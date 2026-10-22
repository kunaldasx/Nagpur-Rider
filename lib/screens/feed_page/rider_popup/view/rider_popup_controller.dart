import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/alert_accept_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';
import 'package:nagpur_rider/utils/services/order_alert_permissions.dart';
import 'package:nagpur_rider/utils/services/order_ringtone_service.dart';

/// Drives the rider order popup from outside the router:
/// - rings (phone ringtone + vibration, like the seller app) while a new
///   order is waiting to be accepted or skipped
/// - re-checks available orders on resume and on a timer
/// - handles the Android back button while the popup is up: an accepted
///   order's scan panel minimizes, a new order card needs Accept or Skip
/// - accepts an order whose native incoming-order alert the rider tapped
///   Accept on ([OrderAlertBridge]), then opens it
/// - checks what alerts need to ring when the rider goes on duty
///
/// Must sit ABOVE `MaterialApp.router` so its back-button observer is
/// registered before the router's and gets the first say.
class RiderPopupController extends StatefulWidget {
  final Widget child;

  const RiderPopupController({super.key, required this.child});

  @override
  State<RiderPopupController> createState() => _RiderPopupControllerState();
}

class _RiderPopupControllerState extends State<RiderPopupController>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _pollTimer;
  StreamSubscription<void>? _acceptRequests;

  RiderPopupCubit get _cubit => context.read<RiderPopupCubit>();
  AlertAcceptCubit get _alertCubit => context.read<AlertAcceptCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.fetch();
    _startPolling();
    _acceptRequests = OrderAlertBridge.acceptRequests.listen(
      (_) => _takeAlertAccept(),
    );
    OrderAlertBridge.ringing.addListener(_onNativeRingingChanged);
    // The listener below only reacts to changes, so cover orders that were
    // already queued before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRinging(_cubit.state);
      // Cold start from an alert's Accept button.
      _takeAlertAccept();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _acceptRequests?.cancel();
    OrderAlertBridge.ringing.removeListener(_onNativeRingingChanged);
    OrderRingtoneService().stop();
    super.dispose();
  }

  void _syncRinging(RiderPopupState state) {
    // The native alert is already ringing: don't play a second ringtone.
    if (state.hasUnaccepted && OrderAlertBridge.ringing.value.isEmpty) {
      OrderRingtoneService().start();
    } else {
      OrderRingtoneService().stop();
    }
  }

  void _onNativeRingingChanged() {
    if (!mounted) return;
    _syncRinging(_cubit.state);
    // An assigned order may now be in the lists.
    if (OrderAlertBridge.ringing.value.isNotEmpty) _cubit.fetch();
  }

  /// Accepts the order whose alert the rider tapped Accept on, if any.
  Future<void> _takeAlertAccept() async {
    final orderId = await OrderAlertBridge.takePendingAccept();
    if (orderId == null || !mounted) return;
    if ((Global.userToken ?? '').trim().isEmpty) {
      MyAppRoute.router.go(AppRoutes.login);
      return;
    }
    final outcome = await _alertCubit.accept(orderId);
    if (outcome == AlertAcceptOutcome.signedOut && mounted) {
      _cubit.clear();
      MyAppRoute.router.go(AppRoutes.login);
    }
  }

  /// After the backend confirmed [orderId]: the bag scan if it has bags to
  /// pick up, else its details.
  Future<void> _openAcceptedAlert(int orderId) async {
    if (await _cubit.openAccepted(orderId)) return;
    await _waitForStartup();
    if (!mounted) return;
    MyAppRoute.router.push(
      AppRoutes.orderDetails,
      extra: {'orderId': orderId, 'from': true},
    );
  }

  /// On a cold start the splash screen routes on its own once it's done;
  /// pushing before then would be replaced.
  Future<void> _waitForStartup() async {
    for (var i = 0; i < 40; i++) {
      final path =
          MyAppRoute.router.routerDelegate.currentConfiguration.uri.path;
      if (path.isNotEmpty && path != AppRoutes.splashScreen) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _cubit.fetch());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cubit.fetch();
        OrderAlertBridge.refreshRinging();
        _takeAlertAccept();
        if (_cubit.state.hasUnaccepted) {
          // A call or another app may have taken audio focus meanwhile.
          OrderRingtoneService().stop().then((_) {
            if (mounted) _syncRinging(_cubit.state);
          });
        }
        _startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async {
    // true = handled, so neither the router nor Android closes anything.
    if (_alertCubit.state.isShown) {
      _alertCubit.dismiss();
      return true;
    }
    final state = _cubit.state;
    if (!state.isShown) return false;
    final top = state.top;
    if (top != null && state.isAccepted(top) && !top.allBagsPickedUp) {
      _cubit.setMinimized(true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RiderPopupCubit, RiderPopupState>(
          listenWhen: (prev, curr) => prev.hasUnaccepted != curr.hasUnaccepted,
          listener: (context, state) => _syncRinging(state),
        ),
        BlocListener<AlertAcceptCubit, AlertAcceptState>(
          listenWhen:
              (prev, curr) => prev.acceptedVersion != curr.acceptedVersion,
          listener: (context, state) {
            final orderId = state.acceptedOrderId;
            if (orderId != null) _openAcceptedAlert(orderId);
          },
        ),
        BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
          listenWhen: (prev, curr) => !prev.isOnline && curr.isOnline,
          listener: (context, state) {
            final navigatorContext = navigatorKey.currentContext;
            if (navigatorContext != null) {
              OrderAlertPermissions.check(navigatorContext);
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
