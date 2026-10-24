import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../../config/colors.dart';
import '../../../../../config/theme_bloc.dart';
import '../../../../../utils/map/google_map_helpers.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../utils/widgets/custom_scaffold.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/toast_message.dart';
import '../../../bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import '../../../bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import '../../../model/return_orders_list_model.dart';
import '../../../repo/return_order_repo.dart';
import '../navigation/navigation_widgets.dart';
import '../navigation/turn_by_turn_navigator.dart';
import '../navigation/voice_guidance.dart';
import '../store_pickup_route/services/map_service.dart';
import 'return_pickup_flow.dart';
import 'return_pickup_sheet.dart';

/// Map for a return pickup: customer first, then back to the seller, with
/// the same in-app turn-by-turn navigation as delivery orders.
class ReturnPickupMapPage extends StatefulWidget {
  final Pickups pickup;

  const ReturnPickupMapPage({super.key, required this.pickup});

  @override
  State<ReturnPickupMapPage> createState() => _ReturnPickupMapPageState();
}

class _ReturnPickupMapPageState extends State<ReturnPickupMapPage> {
  static const LatLng _nagpurCenter = LatLng(21.1458, 79.0882);

  // Close enough to the destination to offer "I've reached" by itself
  static const double _autoArrivalMeters = 60;

  static const double _markerSize = 45;
  static const double _markerBorder = 4;

  final ReturnOrderRepo _repo = ReturnOrderRepo();
  final UpdateReturnOrderStatusBloc _statusBloc = UpdateReturnOrderStatusBloc();
  final VoiceGuidance _voice = VoiceGuidance();

  gm.GoogleMapController? _mapController;
  StreamSubscription<geo.Position>? _positionSubscription;
  LatLng? _rider;
  double _riderHeading = 0;
  double _speedMps = 0;
  bool _isLoadingLocation = true;

  late ReturnPickupLeg _leg;
  bool _hasArrived = false;
  bool _arrivalPromptOpen = false;
  bool _arrivalPromptDismissed = false;
  CustomerNotifyStatus _notifyStatus = CustomerNotifyStatus.none;
  bool _isSubmitting = false;
  String? _pendingStatus;

  List<RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;
  Map<int, gm.BitmapDescriptor> _routeLabelIcons = {};
  bool _isFetchingRoute = false;
  bool _hasFittedRoute = false;
  DateTime? _lastRouteFetch;

  bool _isNavigating = false;
  bool _isFollowingRider = true;
  TurnByTurnNavigator? _navigator;
  NavProgress? _navProgress;
  double _navBearing = 0;

  Pickups get _pickup => widget.pickup;
  LatLng? get _destination => ReturnPickupFlow.destinationFor(_pickup, _leg);
  RouteOption? get _selectedRoute =>
      _routeOptions.isEmpty ? null : _routeOptions[_selectedRouteIndex];

  @override
  void initState() {
    super.initState();
    _leg = ReturnPickupFlow.legFor(_pickup.pickupStatus);
    _preloadMarkerIcons();
    _restoreArrival().then((_) {
      if (mounted) _initLocation();
    });
    _voice.init();
  }

  @override
  void dispose() {
    _voice.stop();
    if (_isNavigating) WakelockPlus.disable().catchError((_) {});
    _positionSubscription?.cancel();
    _mapController?.dispose();
    _statusBloc.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Arrival, persisted so reopening the pickup doesn't notify twice
  // ---------------------------------------------------------------------------

  String _arrivedKey(ReturnPickupLeg leg) =>
      'return_pickup_${_pickup.id}_${leg.name}_arrived';
  String get _notifiedKey => 'return_pickup_${_pickup.id}_customer_notified';

  Future<void> _restoreArrival() async {
    if (_leg == ReturnPickupLeg.completed) return;
    final leg = _leg;
    final prefs = await SharedPreferences.getInstance();
    final arrived = prefs.getBool(_arrivedKey(leg)) ?? false;
    if (!mounted || leg != _leg || !arrived || _hasArrived) return;
    final notified = prefs.getBool(_notifiedKey);
    setState(() {
      _hasArrived = true;
      if (_leg == ReturnPickupLeg.toCustomer) {
        _notifyStatus =
            notified == true
                ? CustomerNotifyStatus.sent
                : CustomerNotifyStatus.failed;
      }
    });
  }

  Future<void> _saveArrival(bool arrived) async {
    final leg = _leg;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || leg != _leg) return;
    await prefs.setBool(_arrivedKey(leg), arrived);
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    for (final leg in ReturnPickupLeg.values) {
      await prefs.remove(_arrivedKey(leg));
    }
    await prefs.remove(_notifiedKey);
  }

  Future<void> _confirmArrival() async {
    if (_arrivalPromptOpen || _hasArrived) return;
    final l10n = AppLocalizations.of(context)!;
    final toCustomer = _leg == ReturnPickupLeg.toCustomer;
    _arrivalPromptOpen = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  toCustomer ? Icons.location_on : Icons.store,
                  color: Colors.green,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomText(
                    text: l10n.confirmArrival,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: CustomText(
              text:
                  toCustomer
                      ? l10n.haveYouReachedCustomer
                      : l10n.haveYouReachedSeller,
              fontSize: 14.sp,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: CustomText(text: l10n.cancel, fontSize: 14.sp),
              ),
              CustomButton(
                textSize: 15.sp,
                text: l10n.yesImHere,
                onPressed: () => Navigator.pop(dialogContext, true),
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
    );

    _arrivalPromptOpen = false;
    if (!mounted) return;
    if (confirmed != true) {
      // Don't keep popping the dialog while the rider waits at the gate
      _arrivalPromptDismissed = true;
      return;
    }

    if (_isNavigating) _stopNavigation(showOverview: false);
    setState(() => _hasArrived = true);
    _saveArrival(true);
    if (toCustomer) _notifyCustomer();
  }

  Future<void> _notifyCustomer() async {
    if (_leg != ReturnPickupLeg.toCustomer ||
        _notifyStatus == CustomerNotifyStatus.sending ||
        _notifyStatus == CustomerNotifyStatus.sent) {
      return;
    }
    setState(() => _notifyStatus = CustomerNotifyStatus.sending);
    var sent = false;
    try {
      final response = await _repo.markArrivedAtCustomer(_pickup.id.toString());
      sent = response['success'] == true;
    } catch (_) {
      sent = false;
    }
    if (!mounted || _leg != ReturnPickupLeg.toCustomer) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _leg != ReturnPickupLeg.toCustomer) return;
    await prefs.setBool(_notifiedKey, sent);
    if (!mounted || _leg != ReturnPickupLeg.toCustomer) return;
    setState(() {
      _notifyStatus =
          sent ? CustomerNotifyStatus.sent : CustomerNotifyStatus.failed;
    });
  }

  // ---------------------------------------------------------------------------
  // Status updates: picked_up, delivered_to_seller
  // ---------------------------------------------------------------------------

  void _updateStatus(String status) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _pendingStatus = status;
    _statusBloc.add(
      UpdateReturnOrderStatus(returnId: _pickup.id.toString(), status: status),
    );
  }

  void _onStatusState(
    BuildContext context,
    UpdateReturnOrderStatusState state,
  ) {
    if (state is UpdateReturnOrderStatusLoading) {
      setState(() => _isSubmitting = true);
    } else if (state is UpdateReturnOrderStatusSuccess) {
      ToastManager.show(
        context: context,
        message: state.message,
        type: ToastType.success,
      );
      _refreshPickupList(context);
      if (_pendingStatus == 'picked_up') {
        _startSellerLeg();
      } else if (_pendingStatus == 'delivered_to_seller') {
        _clearSavedState();
        setState(() {
          _isSubmitting = false;
          _leg = ReturnPickupLeg.completed;
          _routeOptions = [];
        });
      }
      _pendingStatus = null;
    } else if (state is UpdateReturnOrderStatusFailed) {
      setState(() => _isSubmitting = false);
      _pendingStatus = null;
      ToastManager.show(
        context: context,
        message: state.error,
        type: ToastType.error,
      );
    }
  }

  void _refreshPickupList(BuildContext context) {
    try {
      context.read<PickupOrderListBloc>().add(
        FetchPickupOrders(forceRefresh: true),
      );
    } catch (_) {
      // Not provided above this page (e.g. in tests)
    }
  }

  void _startSellerLeg() {
    setState(() {
      _isSubmitting = false;
      _leg = ReturnPickupLeg.toSeller;
      _hasArrived = false;
      _arrivalPromptDismissed = false;
      _routeOptions = [];
      _routeLabelIcons = {};
      _selectedRouteIndex = 0;
      _hasFittedRoute = false;
    });
    _restoreArrival();
    _fitToRiderAndDestination();
    _fetchRoute();
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  Future<void> _initLocation() async {
    // Show the map on the destination if GPS takes too long
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoadingLocation) {
        setState(() => _isLoadingLocation = false);
        _fitToRiderAndDestination();
      }
    });

    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        _onNoLocation();
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        _onNoLocation();
        return;
      }

      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (lastKnown != null) _onPosition(lastKnown);
      _startPositionStream();
    } catch (_) {
      _onNoLocation();
    }
  }

  void _onNoLocation() {
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
    _fitToRiderAndDestination();
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPosition, onError: (_) {});
  }

  void _onPosition(geo.Position position) {
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    if (!GoogleMapHelpers.isValid(point)) return;
    final isFirstFix = _rider == null;

    setState(() {
      if (_rider != null && position.speed > 1.5 && position.heading >= 0) {
        _riderHeading = position.heading;
      }
      _rider = point;
      _speedMps = position.speed > 0 ? position.speed : 0;
      _isLoadingLocation = false;
    });

    if (isFirstFix) {
      _fitToRiderAndDestination();
      _fetchRoute();
      _maybeOfferArrival();
      return;
    }

    if (_isNavigating) _onNavigationPosition(position);
    _maybeOfferArrival();
    _maybeRefreshRoute();
  }

  // Offer "I've reached" when the rider pulls up without navigating
  void _maybeOfferArrival() {
    final destination = _destination;
    final rider = _rider;
    if (destination == null || rider == null) return;
    if (_hasArrived || _arrivalPromptDismissed) return;
    if (_leg == ReturnPickupLeg.completed) return;
    final meters = MapService.calculateDistance(rider, destination) * 1000;
    if (meters <= _autoArrivalMeters) _confirmArrival();
  }

  // ---------------------------------------------------------------------------
  // Route
  // ---------------------------------------------------------------------------

  Future<void> _fetchRoute() async {
    final rider = _rider;
    final destination = _destination;
    if (!mounted || rider == null || destination == null || _isFetchingRoute) {
      return;
    }
    if (_leg == ReturnPickupLeg.completed) return;

    _isFetchingRoute = true;
    _lastRouteFetch = DateTime.now();
    final legAtStart = _leg;
    try {
      final options = await MapService.fetchRouteOptions(rider, destination);
      // The rider may have moved on to the next leg meanwhile
      if (!mounted || legAtStart != _leg || options.isEmpty) return;

      final selected =
          _isNavigating
              ? _routeMatchingCurrent(options)
              : (_selectedRouteIndex < options.length
                  ? _selectedRouteIndex
                  : 0);
      final labelIcons = await _loadRouteLabelIcons(options, selected);
      if (!mounted || legAtStart != _leg) return;

      setState(() {
        _routeOptions = options;
        _selectedRouteIndex = selected;
        _routeLabelIcons = labelIcons;
      });

      final navigator = _navigator;
      if (_isNavigating && navigator != null) {
        navigator.setRoute(options[selected]);
        setState(() => _navProgress = navigator.update(_rider!));
      }

      if (!_hasFittedRoute && !_isNavigating) {
        _hasFittedRoute = true;
        GoogleMapHelpers.fitPoints(
          _mapController,
          [for (final option in options) ...option.points],
          padding: 80,
          singlePointZoom: 15.0,
        );
      }
    } finally {
      _isFetchingRoute = false;
      if (mounted && legAtStart != _leg) _fetchRoute();
    }
  }

  // Routes API requests are billed: refetch only when the rider leaves the
  // selected route, or once a minute to refresh traffic-aware times.
  void _maybeRefreshRoute() {
    final rider = _rider;
    if (rider == null || _isFetchingRoute || _hasArrived) return;
    final now = DateTime.now();
    final sinceLast =
        _lastRouteFetch == null ? null : now.difference(_lastRouteFetch!);
    if (sinceLast != null && sinceLast < const Duration(seconds: 10)) return;

    final points = _selectedRoute?.points ?? const <LatLng>[];
    final isOffRoute =
        points.length < 2 ||
        MapService.minDistanceToPolyline(rider, points) > 50;
    final isTimeForRefresh =
        sinceLast == null || sinceLast >= const Duration(seconds: 60);
    if (isOffRoute || isTimeForRefresh) _fetchRoute();
  }

  // While navigating, keep the route the rider is already on
  int _routeMatchingCurrent(List<RouteOption> options) {
    final current = _selectedRoute?.points ?? const <LatLng>[];
    final rider = _rider;
    if (options.length < 2 || current.length < 2 || rider == null) return 0;
    if (MapService.minDistanceToPolyline(rider, current) > 50) return 0;

    int best = 0;
    double bestScore = double.infinity;
    for (int i = 0; i < options.length; i++) {
      final points = options[i].points;
      final step = math.max(1, points.length ~/ 20);
      double total = 0;
      int count = 0;
      for (int j = 0; j < points.length; j += step) {
        total += MapService.minDistanceToPolyline(points[j], current);
        count++;
      }
      final score = total / math.max(1, count);
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  Future<void> _selectRoute(int index) async {
    if (index == _selectedRouteIndex || index >= _routeOptions.length) return;
    final options = _routeOptions;
    final labelIcons = await _loadRouteLabelIcons(options, index);
    if (!mounted || !identical(options, _routeOptions) || _isNavigating) return;
    setState(() {
      _selectedRouteIndex = index;
      _routeLabelIcons = labelIcons;
    });
  }

  Future<Map<int, gm.BitmapDescriptor>> _loadRouteLabelIcons(
    List<RouteOption> options,
    int selectedIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final icons = <int, gm.BitmapDescriptor>{};
    for (int i = 0; i < options.length; i++) {
      final isSelected = i == selectedIndex;
      icons[i] = await MapLabelIcons.load(
        text: l10n.routeMinutes(options[i].durationMinutes),
        background: isSelected ? AppColors.primaryColor : Colors.white,
        textColor: isSelected ? Colors.white : Colors.grey.shade800,
      );
    }
    return icons;
  }

  // Point on a route farthest from the others, where the label reads best
  LatLng _routeLabelPosition(int index) {
    final points = _routeOptions[index].points;
    final others = [
      for (int i = 0; i < _routeOptions.length; i++)
        if (i != index) _routeOptions[i].points,
    ];
    if (others.isEmpty) return points[points.length ~/ 2];

    LatLng best = points[points.length ~/ 2];
    double bestDistance = -1;
    final step = math.max(1, points.length ~/ 40);
    for (int i = step; i < points.length - step; i += step) {
      final distance = others
          .map((other) => MapService.minDistanceToPolyline(points[i], other))
          .reduce(math.min);
      if (distance > bestDistance) {
        bestDistance = distance;
        best = points[i];
      }
    }
    return best;
  }

  Future<void> _retryRouteAndNavigate() async {
    while (_isFetchingRoute && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted || _hasArrived || _leg == ReturnPickupLeg.completed) return;
    if (_routeOptions.isEmpty) await _fetchRoute();
    if (!mounted || _hasArrived || _leg == ReturnPickupLeg.completed) return;

    if (_routeOptions.isEmpty) {
      ToastManager.show(
        context: context,
        message:
            _rider == null
                ? AppLocalizations.of(context)!.waitingForGps
                : 'Could not load route. Check your internet and try again.',
        type: ToastType.error,
      );
      return;
    }
    _startNavigation();
  }

  // ---------------------------------------------------------------------------
  // In-app turn-by-turn navigation
  // ---------------------------------------------------------------------------

  void _onStartPressed() {
    if (_routeOptions.isEmpty) {
      _retryRouteAndNavigate();
    } else {
      _startNavigation();
    }
  }

  void _startNavigation() {
    final rider = _rider;
    final route = _selectedRoute;
    if (route == null) return;
    if (rider == null) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.waitingForGps,
        type: ToastType.info,
      );
      return;
    }

    final navigator = TurnByTurnNavigator(route);
    final progress = navigator.update(rider);
    setState(() {
      _navigator = navigator;
      _navProgress = progress;
      _isNavigating = true;
      _isFollowingRider = true;
      _navBearing = _speedMps > 1.5 ? _riderHeading : _initialRouteBearing();
    });
    WakelockPlus.enable().catchError((_) {});
    _voice.speak(navigator.announcement(progress, isFirst: true) ?? '');
    _followRider();
  }

  // Direction of the first stretch of road, so the map faces the right way
  double _initialRouteBearing() {
    final points = _selectedRoute?.points ?? const <LatLng>[];
    if (points.length < 2) return _riderHeading;
    final start = points.first;
    final ahead = points.firstWhere(
      (p) => MapService.calculateDistance(start, p) > 0.02,
      orElse: () => points[1],
    );
    return _bearing(start, ahead);
  }

  void _stopNavigation({bool silenceVoice = true, bool showOverview = true}) {
    if (silenceVoice) _voice.stop();
    WakelockPlus.disable().catchError((_) {});
    setState(() {
      _isNavigating = false;
      _navigator = null;
      _navProgress = null;
    });
    if (showOverview) _showRouteOverview();
  }

  void _onNavigationPosition(geo.Position position) {
    final navigator = _navigator;
    if (navigator == null) return;
    if (position.speed > 1.5 && position.heading >= 0) {
      _navBearing = position.heading;
    }

    final progress = navigator.update(
      LatLng(position.latitude, position.longitude),
    );
    setState(() => _navProgress = progress);

    final text = navigator.announcement(progress, isFirst: false);
    if (text != null) _voice.speak(text);

    if (progress.arrived) {
      _stopNavigation(silenceVoice: false, showOverview: false);
      _confirmArrival();
      return;
    }
    if (_isFollowingRider) _followRider();
  }

  void _followRider() {
    final rider = _rider;
    if (rider == null) return;
    _mapController?.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: GoogleMapHelpers.toGm(rider),
          zoom: 17.5,
          tilt: 55,
          bearing: _navBearing,
        ),
      ),
    );
  }

  void _recenter() {
    setState(() => _isFollowingRider = true);
    _followRider();
  }

  Future<void> _showRouteOverview() async {
    if (_isNavigating) setState(() => _isFollowingRider = false);
    final controller = _mapController;
    if (controller == null) return;
    final rider = _rider;
    if (rider != null) {
      await controller.moveCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(target: GoogleMapHelpers.toGm(rider), zoom: 15),
        ),
      );
    }
    await GoogleMapHelpers.fitPoints(
      controller,
      [
        if (rider != null) rider,
        ...?_selectedRoute?.points,
        if (_destination != null) _destination!,
      ],
      padding: 80,
      singlePointZoom: 15.0,
    );
  }

  void _fitToRiderAndDestination() {
    final points = [
      if (_rider != null) _rider!,
      if (_destination != null) _destination!,
    ];
    if (points.isEmpty) return;
    GoogleMapHelpers.fitPoints(
      _mapController,
      points,
      padding: 80,
      singlePointZoom: 15.0,
    );
  }

  void _showSteps({required bool isDarkTheme}) {
    final route = _navigator?.route ?? _selectedRoute;
    if (route == null) return;
    final l10n = AppLocalizations.of(context)!;
    final progress = _navProgress;
    final minutes =
        progress != null
            ? (progress.remainingSeconds / 60).ceil().clamp(1, 100000)
            : route.durationMinutes;
    final meters = progress?.remainingMeters ?? route.distanceMeters;
    showRouteStepsSheet(
      context,
      steps: route.steps,
      currentStepIndex: progress?.stepIndex ?? -1,
      summary:
          '${l10n.routeMinutes(minutes)} · ${TurnByTurnNavigator.displayDistance(meters)}',
      destination: _destinationAddress(),
      isDarkTheme: isDarkTheme,
      onOpenInGoogleMaps: _openInGoogleMaps,
    );
  }

  // ---------------------------------------------------------------------------
  // Hand-offs: phone and Google Maps
  // ---------------------------------------------------------------------------

  String _destinationAddress() =>
      _leg == ReturnPickupLeg.toCustomer
          ? ReturnPickupFlow.customerAddress(_pickup)
          : ReturnPickupFlow.sellerAddress(_pickup);

  Future<void> _call() async {
    final l10n = AppLocalizations.of(context)!;
    final toCustomer = _leg == ReturnPickupLeg.toCustomer;
    final phone =
        toCustomer
            ? ReturnPickupFlow.customerPhone(_pickup)
            : ReturnPickupFlow.sellerPhone(_pickup);
    if (phone == null) {
      ToastManager.show(
        context: context,
        message:
            toCustomer
                ? l10n.customerPhoneUnavailable
                : l10n.sellerPhoneUnavailable,
        type: ToastType.error,
      );
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openInGoogleMaps() async {
    final destination = _destination;
    final target =
        destination != null
            ? '${destination.latitude},${destination.longitude}'
            : _destinationAddress();
    if (target.isEmpty) return;
    final rider = _rider;
    final url =
        'https://www.google.com/maps/dir/?api=1'
        '${rider != null ? '&origin=${Uri.encodeComponent('${rider.latitude},${rider.longitude}')}' : ''}'
        '&destination=${Uri.encodeComponent(target)}'
        '&travelmode=driving';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ToastManager.show(
        context: context,
        message: 'Could not open navigation: $e',
        type: ToastType.error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Map layers
  // ---------------------------------------------------------------------------

  Future<void> _preloadMarkerIcons() async {
    await Future.wait([
      for (final entry in [
        (Colors.blue, Icons.directions_bike),
        (Colors.orange, Icons.person_pin_circle),
        (Colors.green, Icons.person_pin_circle),
        (Colors.red, Icons.store),
        (Colors.green, Icons.store),
      ])
        MapMarkerIcons.load(
          background: entry.$1,
          icon: entry.$2,
          size: _markerSize,
          borderWidth: _markerBorder,
        ),
    ]);
    if (mounted) setState(() {});
  }

  gm.Marker _circleMarker(
    String id,
    LatLng point,
    Color color,
    IconData icon, {
    double rotation = 0,
    int zIndex = 1,
  }) {
    return gm.Marker(
      markerId: gm.MarkerId(id),
      position: GoogleMapHelpers.toGm(point),
      icon: MapMarkerIcons.get(
        background: color,
        icon: icon,
        size: _markerSize,
        borderWidth: _markerBorder,
      ),
      anchor: const Offset(0.5, 0.5),
      rotation: rotation,
      flat: rotation != 0,
      zIndexInt: zIndex,
    );
  }

  Set<gm.Marker> _buildMarkers() {
    final markers = <gm.Marker>{};
    final customer = ReturnPickupFlow.customerLocation(_pickup);
    final seller = ReturnPickupFlow.sellerLocation(_pickup);
    final pickedUp = _leg != ReturnPickupLeg.toCustomer;

    if (customer != null) {
      markers.add(
        _circleMarker(
          'customer',
          customer,
          pickedUp ? Colors.green : Colors.orange,
          Icons.person_pin_circle,
        ),
      );
    }
    if (seller != null) {
      markers.add(
        _circleMarker(
          'seller',
          seller,
          _leg == ReturnPickupLeg.completed ? Colors.green : Colors.red,
          Icons.store,
        ),
      );
    }
    final rider = _rider;
    if (rider != null) {
      markers.add(
        _circleMarker(
          'rider',
          rider,
          Colors.blue,
          Icons.directions_bike,
          rotation: _riderHeading,
          zIndex: 3,
        ),
      );
    }

    if (!_isNavigating && !_hasArrived) {
      for (int i = 0; i < _routeOptions.length; i++) {
        final icon = _routeLabelIcons[i];
        if (icon == null) continue;
        markers.add(
          gm.Marker(
            markerId: gm.MarkerId('route_label_$i'),
            position: GoogleMapHelpers.toGm(_routeLabelPosition(i)),
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            zIndexInt: i == _selectedRouteIndex ? 5 : 4,
            onTap: () => _selectRoute(i),
          ),
        );
      }
    }
    return markers;
  }

  Set<gm.Polyline> _buildPolylines() {
    if (_leg == ReturnPickupLeg.completed || _hasArrived) return const {};

    final navRoute = _navigator?.route;
    if (_isNavigating && navRoute != null) {
      return {
        gm.Polyline(
          polylineId: const gm.PolylineId('nav_route'),
          points: GoogleMapHelpers.toGmList(navRoute.points),
          width: 9,
          color: AppColors.primaryColor,
          startCap: gm.Cap.roundCap,
          endCap: gm.Cap.roundCap,
          jointType: gm.JointType.round,
        ),
      };
    }

    if (_routeOptions.isNotEmpty) {
      return {
        for (int i = 0; i < _routeOptions.length; i++)
          gm.Polyline(
            polylineId: gm.PolylineId('route_$i'),
            points: GoogleMapHelpers.toGmList(_routeOptions[i].points),
            width: i == _selectedRouteIndex ? 7 : 6,
            color:
                i == _selectedRouteIndex
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: 0.35),
            zIndex: i == _selectedRouteIndex ? 2 : 1,
            startCap: gm.Cap.roundCap,
            endCap: gm.Cap.roundCap,
            jointType: gm.JointType.round,
            consumeTapEvents: true,
            onTap: () => _selectRoute(i),
          ),
      };
    }

    // Road route not loaded yet: a straight dashed hint
    final rider = _rider;
    final destination = _destination;
    if (rider == null || destination == null) return const {};
    return {
      gm.Polyline(
        polylineId: const gm.PolylineId('straight'),
        points: GoogleMapHelpers.toGmList([rider, destination]),
        width: 4,
        color: AppColors.primaryColor.withValues(alpha: 0.6),
        patterns: [gm.PatternItem.dash(20), gm.PatternItem.gap(12)],
      ),
    };
  }

  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  List<Widget> _buildNavigationOverlay(bool isDarkTheme) {
    final progress = _navProgress;
    if (progress == null) return const [];
    final l10n = AppLocalizations.of(context)!;
    final itemsHeight = MediaQuery.of(context).size.height * 0.22;
    return [
      Positioned(
        top: 8.h,
        left: 8.w,
        right: 8.w,
        child: NavigationBanner(progress: progress),
      ),
      Positioned(
        top: 150.h,
        right: 12.w,
        child: Column(
          children: [
            NavigationMapButton(
              icon: _voice.muted ? Icons.volume_off : Icons.volume_up,
              tooltip: _voice.muted ? l10n.unmuteVoice : l10n.muteVoice,
              onPressed: () {
                setState(() => _voice.muted = !_voice.muted);
                if (_voice.muted) _voice.stop();
              },
            ),
            SizedBox(height: 10.h),
            NavigationMapButton(
              icon: Icons.alt_route,
              tooltip: l10n.routeOverview,
              onPressed: _showRouteOverview,
            ),
            SizedBox(height: 10.h),
            NavigationMapButton(
              icon: Icons.phone,
              tooltip:
                  _leg == ReturnPickupLeg.toCustomer
                      ? l10n.callCustomer
                      : l10n.callSeller,
              onPressed: _call,
            ),
          ],
        ),
      ),
      Positioned(
        left: 12.w,
        bottom: 96.h + itemsHeight,
        child: SpeedBubble(speedMetersPerSecond: _speedMps),
      ),
      if (!_isFollowingRider)
        Positioned(
          right: 12.w,
          bottom: 100.h + itemsHeight,
          child: RecenterButton(onPressed: _recenter),
        ),
      Positioned(
        left: 12.w,
        right: 12.w,
        bottom: 88.h,
        child: Container(
          constraints: BoxConstraints(maxHeight: itemsHeight),
          decoration: BoxDecoration(
            color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: SingleChildScrollView(
            child: ReturnItemsList(
              pickup: _pickup,
              title:
                  _leg == ReturnPickupLeg.toCustomer
                      ? l10n.returnItemsCount(1)
                      : l10n.carryingItems(1),
              collected: _leg == ReturnPickupLeg.toSeller,
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: NavigationBottomBar(
          progress: progress,
          isDarkTheme: isDarkTheme,
          onExit: _stopNavigation,
          onShowSteps: () => _showSteps(isDarkTheme: isDarkTheme),
        ),
      ),
    ];
  }

  Widget _buildDistancePill() {
    final l10n = AppLocalizations.of(context)!;
    final route = _selectedRoute;
    final rider = _rider;
    final destination = _destination;
    String text;
    if (route != null) {
      text =
          '${l10n.routeMinutes(route.durationMinutes)} · ${route.distanceKm.toStringAsFixed(1)} ${l10n.km}';
    } else if (rider != null && destination != null) {
      text =
          '${MapService.calculateDistance(rider, destination).toStringAsFixed(1)} ${l10n.km}';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            route != null ? Icons.directions_car : Icons.straighten,
            color: Theme.of(context).colorScheme.onSurface,
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          CustomText(text: text, fontWeight: FontWeight.w600, fontSize: 14.sp),
        ],
      ),
    );
  }

  Widget _buildBottomCard(bool isDarkTheme) {
    if (_leg == ReturnPickupLeg.completed) {
      return ReturnCompletedCard(
        pickup: _pickup,
        isDarkTheme: isDarkTheme,
        onBack: () => context.pop(true),
      );
    }
    final route = _selectedRoute;
    return ReturnPickupSheet(
      pickup: _pickup,
      leg: _leg,
      hasArrived: _hasArrived,
      notifyStatus: _notifyStatus,
      isSubmitting: _isSubmitting,
      isDarkTheme: isDarkTheme,
      route: route,
      extraMinutes:
          route == null
              ? 0
              : route.durationMinutes - _routeOptions.first.durationMinutes,
      hasAlternativeRoutes: _routeOptions.length > 1,
      onStart: _onStartPressed,
      onShowSteps: () => _showSteps(isDarkTheme: isDarkTheme),
      onCall: _call,
      onReached: () {
        _arrivalPromptDismissed = false;
        _confirmArrival();
      },
      onRetryNotify: _notifyCustomer,
      onCollected: () => _updateStatus('picked_up'),
      onDelivered: () => _updateStatus('delivered_to_seller'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _statusBloc,
      child: BlocListener<
        UpdateReturnOrderStatusBloc,
        UpdateReturnOrderStatusState
      >(
        listener: _onStatusState,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDarkTheme = themeState.currentTheme == 'dark';
            final screenHeight = MediaQuery.of(context).size.height;

            return PopScope(
              // Back exits navigation first, like Google Maps
              canPop: !_isNavigating,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && _isNavigating) _stopNavigation();
              },
              child: CustomScaffold(
                appBar:
                    _isNavigating
                        ? null
                        : CustomAppBarWithoutNavbar(
                          title: AppLocalizations.of(context)!.returnPickup,
                          showRefreshButton: false,
                          showThemeToggle: false,
                        ),
                body: Stack(
                  children: [
                    Listener(
                      // Any touch on the map while navigating stops following
                      onPointerDown: (_) {
                        if (_isNavigating && _isFollowingRider) {
                          setState(() => _isFollowingRider = false);
                        }
                      },
                      child: gm.GoogleMap(
                        initialCameraPosition: gm.CameraPosition(
                          target: GoogleMapHelpers.toGm(
                            _rider ?? _destination ?? _nagpurCenter,
                          ),
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) _fitToRiderAndDestination();
                          });
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: !_isNavigating,
                        trafficEnabled: _isNavigating,
                        padding:
                            _isNavigating
                                ? EdgeInsets.only(
                                  top: 260.h,
                                  bottom: 88.h + screenHeight * 0.22,
                                )
                                : EdgeInsets.only(
                                  top: 60.h,
                                  bottom: screenHeight * 0.45,
                                ),
                        polylines: _buildPolylines(),
                        markers: _buildMarkers(),
                      ),
                    ),
                    if (_isLoadingLocation)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  SizedBox(height: 16.h),
                                  CustomText(
                                    text:
                                        AppLocalizations.of(
                                          context,
                                        )!.loadingMap,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_isNavigating)
                      ..._buildNavigationOverlay(isDarkTheme)
                    else ...[
                      if (!_hasArrived && _leg != ReturnPickupLeg.completed)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildDistancePill(),
                        ),
                      // Backup only: the main way is the in-app Start button
                      if (_leg != ReturnPickupLeg.completed)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Tooltip(
                            message:
                                AppLocalizations.of(context)!.openInGoogleMaps,
                            child: FloatingActionButton.small(
                              heroTag: 'return_google_maps',
                              onPressed: _openInGoogleMaps,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              foregroundColor: AppColors.primaryColor,
                              child: const Icon(Icons.map_outlined),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 12.w,
                        right: 12.w,
                        bottom: 16.h,
                        child: _buildBottomCard(isDarkTheme),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
