// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../../utils/widgets/location_status_banner.dart';
import '../../../utils/location_tracker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/global.dart';
import '../../../config/theme_bloc.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/connectivity_mixin.dart';
import '../../inactive_delievryboy/view/statistics_page.dart';
import '../widgets/header_section/home_header_section.dart';
import '../widgets/tab_bar/home_tab_bar_section.dart';
import '../widgets/tab_bar/home_tab_content_section.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../bloc/available_orders_bloc/available_orders_event.dart';
import '../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../bloc/my_orders_bloc/my_orders_event.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

// Function to open Google Maps with directions
Future<void> openGoogleMapsDirections({
  required String destinationLat,
  required String destinationLng,
  String originLat = '21.1458',
  String originLng = '79.0882',
}) async {
  try {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destinationLat,$destinationLng&travelmode=driving',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    // Fallback: try to open in browser if app launch fails
    try {
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/$originLat,$originLng/$destinationLat,$destinationLng',
      );
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } catch (fallbackError) {
      throw 'Could not open Google Maps. Please install Google Maps app or try again.';
    }
  }
}

class FeedPage extends StatefulWidget {
  final int? initialTab; // 0 = Available Orders, 1 = My Orders

  const FeedPage({super.key, this.initialTab});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FeedPageWithStatus(initialTab: widget.initialTab);
  }
}

class FeedPageWithStatus extends StatefulWidget {
  final int? initialTab; // 0 = Available Orders, 1 = My Orders

  const FeedPageWithStatus({super.key, this.initialTab});

  @override
  State<FeedPageWithStatus> createState() => _FeedPageWithStatusState();
}

class _FeedPageWithStatusState extends State<FeedPageWithStatus>
    with ConnectivityMixin {
  bool _isInitialized = false;
  bool _hasDispatchedEvents = false; // Prevent multiple event dispatches

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    if (_hasDispatchedEvents) return; // Prevent multiple calls

    try {
      final localStatus = await Global.getDeliveryBoyStatus() ?? false;

      setState(() {
        _isInitialized = true;
      });

      // Only dispatch events once
      if (!_hasDispatchedEvents) {
        final bloc = context.read<DeliveryBoyStatusBloc>();
        bloc.add(SyncInitialStatus(localStatus));
        _hasDispatchedEvents = true;
      }
    } catch (e) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildWithConnectivity(
      child: _buildFeedPageContent(),
      onRetry: _initializeStatus,
    );
  }

  Widget _buildFeedPageContent() {
    if (!_isInitialized) {
      return const CustomScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      builder: (context, state) {
        // Always show FeedPageContent regardless of status
        // The inactive widget will be shown in the Available Orders tab when needed
        return WillPopScope(
          onWillPop: () async {
            // Show exit confirmation dialog
            return await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.exitApp),
                      content: Text(
                        AppLocalizations.of(context)!.exitAppConfirmation,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(AppLocalizations.of(context)!.exit),
                        ),
                      ],
                    );
                  },
                ) ??
                false;
          },
          child: FeedPageContent(initialTab: widget.initialTab),
        );
      },
    );
  }

  @override
  void didUpdateWidget(FeedPageWithStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class FeedPageContent extends StatefulWidget {
  final int? initialTab; // 0 = Available Orders, 1 = My Orders

  const FeedPageContent({super.key, this.initialTab});

  @override
  State<FeedPageContent> createState() => _FeedPageContentState();
}

class _FeedPageContentState extends State<FeedPageContent>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ConnectivityMixin {
  final bool _isUpdating = false;
  bool _isInitialized = false; // Track if initialization is complete
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(GetUnreadCount());
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update icon colors only

      // Refresh orders when switching tabs
      if (_tabController.index == 0) {
        // Available Orders tab - can refresh available but typically not needed strictly on switch
        // Just let it load if initial
      } else if (_tabController.index == 1) {
        // My Orders tab - remove forceRefresh so it uses cached data or loads normally
        context.read<MyOrdersBloc>().add(AllMyOrdersList());
      } else if (_tabController.index == 2) {
        // Return Orders tab
        context.read<ReturnOrderListBloc>().add(FetchReturnOrders());
      } else if (_tabController.index == 3) {
        // Pickup Orders tab
        context.read<PickupOrderListBloc>().add(FetchPickupOrders());
      }
    });

    // Initialize with a default value, will be updated after loading from storage
    // _onlineController = ValueNotifier<bool>(false);
    // _onlineController.addListener(_handleToggle);

    _initializeStatusFromGlobal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh data when dependencies change (e.g., when returning from order details page)
    if (!_isInitialized) {
      _isInitialized = true;
      _refreshDataOnPageVisible();
    } else {
      // Also refresh when returning from other pages (like order details)
      // Small delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshDataOnPageVisible();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh orders when app becomes active
      _refreshDataOnPageVisible();
    }
  }

  /// Refreshes data when the page becomes visible
  void _refreshDataOnPageVisible() {
    if (!mounted) return;
    // Refresh based on current tab
    if (_tabController.index == 0) {
      // Available Orders tab
      context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
    } else if (_tabController.index == 1) {
      // My Orders tab
      context.read<MyOrdersBloc>().add(AllMyOrdersList());
    } else if (_tabController.index == 2) {
      // Return Orders
      context.read<ReturnOrderListBloc>().add(FetchReturnOrders());
    } else if (_tabController.index == 3) {
      // Pickup Orders
      context.read<PickupOrderListBloc>().add(FetchPickupOrders());
    }
  }

  Future<void> _initializeStatusFromGlobal() async {
    try {
      await Global.initializeToken();
      await Global.initializeStatus();

      await Global.printFCMToken();

      final initialStatus = await Global.getDeliveryBoyStatus() ?? false;

      // Set initial value without triggering loading state
      _isInitialized = true; // Mark as initialized

      // Sync the deliveryboy_status_update_bloc with the persisted status
      try {
        final bloc = context.read<DeliveryBoyStatusBloc>();
        bloc.add(SyncInitialStatus(initialStatus));
      } catch (e) {
        // Handle error silently
      }

      // Refresh orders after initialization
      try {
        context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
        context.read<MyOrdersBloc>().add(AllMyOrdersList());
        context.read<ReturnOrderListBloc>().add(FetchReturnOrders());
        context.read<PickupOrderListBloc>().add(FetchPickupOrders());
      } catch (e) {
        // Handle error silently
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleToggle() {
    if (_isUpdating || !_isInitialized) {
      return; // Don't handle toggle until initialized
    }

    final currentState = context.read<DeliveryBoyStatusBloc>().state.isOnline;
    final newValue = !currentState;

    // Dispatch to the single source-of-truth deliveryboy_status_update_bloc
    try {
      final bloc = context.read<DeliveryBoyStatusBloc>();
      bloc.add(
        ToggleStatus(
          newValue,
          explainBackground: () => explainBackgroundLocation(context),
        ),
      );
    } catch (e) {
      // Handle error silently
    }

    // Don't update local state here - let the bloc handle it
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithConnectivity(
      child: _buildFeedPageContent(),
      onRetry: _initializeStatusFromGlobal,
    );
  }

  Widget _buildFeedPageContent() {
    return BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      builder: (context, state) {
        final isOnline = state.isOnline;

        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDarkTheme = themeState.currentTheme == 'dark';

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: CustomScaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Padding(
                    padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 5.h),
                    child: Column(
                      children: [
                        HomeHeaderSection(
                          handleToggle: () {
                            _handleToggle();
                          },
                        ),
                        if (isOnline) const LocationStatusBanner(),
                        if (!isOnline &&
                            state is DeliveryBoyStatusError &&
                            state.locationIssue != null)
                          LocationIssueBanner(
                            status: state.locationIssue!,
                            message: switch (state.locationIssue!) {
                              LocationHealthStatus.serviceOff =>
                                AppLocalizations.of(
                                  context,
                                )!.locationOnlineGpsRequired,
                              LocationHealthStatus.permissionDenied =>
                                AppLocalizations.of(
                                  context,
                                )!.locationOnlinePermissionRequired,
                              _ =>
                                AppLocalizations.of(
                                  context,
                                )!.locationOnlineWeakSignal,
                            },
                          ),
                        const SizedBox(height: 16),
                        HomeTabBarSection(tabController: _tabController),
                        HomeTabContentSection(
                          tabController: _tabController,
                          isDeliveryBoyActive:
                              isOnline, // Pass the delivery boy status
                          isDarkTheme: isDarkTheme, // Pass the theme parameter
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// New HomePage that shows StatisticsPage
class StatisticsHomePage extends StatefulWidget {
  const StatisticsHomePage({super.key});

  @override
  State<StatisticsHomePage> createState() => _StatisticsHomePageState();
}

class _StatisticsHomePageState extends State<StatisticsHomePage> {
  @override
  Widget build(BuildContext context) {
    return const StatisticsPage();
  }
}
