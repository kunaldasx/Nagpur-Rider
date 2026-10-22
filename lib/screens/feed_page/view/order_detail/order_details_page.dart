// ignore_for_file: unused_element, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import '../../../../utils/location_handler.dart';
import '../../../../config/colors.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../system_settings/bloc/system_settings_bloc.dart';
import '../../../system_settings/bloc/system_settings_event.dart';
import '../../../system_settings/bloc/system_settings_state.dart';
import '../../../system_settings/repo/system_settings_repo.dart';
import '../../model/available_orders.dart';
import '../../model/cod_payment.dart';
import '../../repo/cod_payment_repo.dart';
import '../../widgets/orderdetails_widgets/cod_payment_sheet.dart';
import '../../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../../bloc/items_collected_bloc/items_collected_event.dart';
import '../../bloc/items_collected_bloc/items_collected_state.dart';
import '../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../bloc/order_details_bloc/order_details_event.dart';
import '../../bloc/order_details_bloc/order_details_state.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../../bloc/my_orders_bloc/my_orders_event.dart';
import '../../repo/order_details.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../../../utils/widgets/reusable_bottom_sheet.dart';
import '../../widgets/orderdetails_widgets/index.dart';
import '../../../../router/app_routes.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'widgets/index.dart' as new_widgets;
import '../../services/order_service.dart';
import '../../services/dialog_service.dart';
import '../../../../utils/services/phone_service.dart';
import '../../../../utils/services/ui_helper_service.dart';
import '../../services/item_card_service.dart';
import '../../rider_popup/cubit/rider_popup_cubit.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final bool from;
  final int? sourceTab; // 0 = Available Orders, 1 = My Orders
  final bool? arrivalConfirmed; // Whether arrival has been confirmed

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    this.from = false,
    this.sourceTab,
    this.arrivalConfirmed,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class OrderDetailsPageWithBloc extends StatelessWidget {
  final int orderId;
  final bool from;
  final int? sourceTab; // 0 = Available Orders, 1 = My Orders
  final bool? arrivalConfirmed; // Whether arrival has been confirmed

  const OrderDetailsPageWithBloc({
    super.key,
    required this.orderId,
    this.from = false,
    this.sourceTab,
    this.arrivalConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ItemsCollectedBloc()),
        BlocProvider(create: (context) => OrderDetailsBloc(OrderDetailsRepo())),
        BlocProvider(
          create: (context) => SystemSettingsBloc(SystemSettingsRepo()),
        ),
      ],
      child: OrderDetailsPage(
        orderId: orderId,
        from: from,
        sourceTab: sourceTab,
        arrivalConfirmed: arrivalConfirmed,
      ),
    );
  }
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with TickerProviderStateMixin {
  Orders? _fetchedOrder;

  // Local state sets for tracking item status
  final Set<String> _collectedItems = {};
  final Set<String> _deliveredItems = {};
  final Set<String> _otpVerifiedItems = {};

  // UI state variables
  bool _isItemsExpanded = true;
  bool _isDeliveryExpanded = false;
  bool _isStoreDetailsExpanded = false;
  bool _isPaymentExpanded = false;
  bool _isEarningsExpanded = false;
  bool _isPricingExpanded = false;
  final Set<String> _processingItemIds = {};
  bool _isCollectingAll = false;
  bool _isDeliveringAll = false;

  // Confetti controller for celebration animation
  late ConfettiController _confettiController;

  // Track if confetti has been shown for this order
  bool _hasShownConfetti = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayStatus(String status) {
    // Check if all items are delivered with verified OTP

    // If status is delivered and OTP is verified, don't show pending
    if (status.toLowerCase() == 'delivered') {
      return 'delivered';
    }

    // If status is pending and no items require OTP, show as collected
    if (status.toLowerCase() == 'pending') {
      return 'collected'; // Show as collected instead of pending
    }

    return status;
  }

  bool _areAllItemsDeliveredWithOtp() {
    final order = _fetchedOrder;
    if (order?.items == null || order!.items!.isEmpty) return false;

    for (var item in order.items!) {
      if (item.status?.toLowerCase() != 'delivered' || item.otpVerified != 1) {
        return false;
      }
    }
    return true;
  }

  bool _areAllItemsDelivered() {
    return OrderService.areAllItemsDelivered(_fetchedOrder);
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Reset confetti flag for new order
    _hasShownConfetti = false;

    // Initialize arrival confirmation status from widget parameter

    // Fetch system system_settings for currency symbol

    context.read<SystemSettingsBloc>().add(FetchSystemSettings());

    // Fetch order details from API
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));

    // Remove the post-frame callback that was causing state conflicts
    // WidgetsBinding.instance.addPostFrameCallback((_) {

    //   _initializeLocalStateFromApi();
    // });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method is called when the widget's dependencies change
    // It's a good place to refresh data when navigating back to this page

    // Only refresh if we don't have order data
    // Don't refresh if we already have the latest state to preserve bloc updates
    if (_fetchedOrder == null) {

      _refreshOrderDataIfNeeded();
    } else {}
  }

  // Method to refresh order data when needed (e.g., when navigating back)
  void _refreshOrderDataIfNeeded() {
    // Only refresh if we have an order and it's been a while since last refresh
    if (_fetchedOrder != null) {
      context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
    }
  }

  // Method to manually refresh order data
  void _refreshOrderData() {
    // Check if current bloc state has reachedDestination items that we need to preserve
    final currentState = context.read<OrderDetailsBloc>().state;
    Map<String, bool> reachedDestinationItems = {};

    if (currentState is OrderDetailsSuccess) {
      // Preserve reachedDestination status from current bloc state
      for (var item in currentState.order.items ?? []) {
        if (item.reachedDestination == true) {
          reachedDestinationItems[item.id.toString()] = true;
        }
      }
    }

    // Clear local state first
    setState(() {
      _deliveredItems.clear();
      _otpVerifiedItems.clear();
      _collectedItems.clear();
    });

    // Fetch fresh data from API
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));

    // After API response, restore reachedDestination status
    if (reachedDestinationItems.isNotEmpty) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SystemSettingsBloc, SystemSettingsState>(
          listener: (context, state) {
            if (state is SystemSettingsLoaded) {
              // Trigger a rebuild to update currency symbols
              setState(() {});
            }
          },
        ),
        // The bag scan popup moved this order's items to collected.
        BlocListener<RiderPopupCubit, RiderPopupState>(
          listenWhen: (prev, curr) =>
              prev.pickupVersion != curr.pickupVersion &&
              curr.lastPickedUpOrderId == widget.orderId,
          listener: (context, state) {
            context.read<OrderDetailsBloc>().add(
              FetchOrderDetails(widget.orderId),
            );
          },
        ),
      ],
      child: BlocConsumer<ItemsCollectedBloc, ItemsCollectedState>(
        listener: (context, state) {
          if (state is ItemsCollectedSuccess) {
            String processedItemId = state.itemId;

            setState(() {
              _processingItemIds.remove(processedItemId);

              // Always add to collected items to hide security icon for OTP items
              _collectedItems.add(processedItemId);

              // Add to delivered items if this is delivery mode and order status is not assigned
              // OR if order status is "out_for_delivery"
              if ((widget.from &&
                      _fetchedOrder?.status?.toLowerCase() != 'assigned') ||
                  _fetchedOrder?.status?.toLowerCase() == 'out_for_delivery') {
                _deliveredItems.add(processedItemId);
              }

              // Update the local order data immediately for this item
              if (_fetchedOrder?.items != null) {
                List<Items> updatedItems = _fetchedOrder!.items!.map((item) {
                  if (item.id.toString() == processedItemId) {
                    String newStatus = (widget.from && _fetchedOrder?.status?.toLowerCase() != 'assigned') ? 'delivered' : 'collected';
                    return item.copyWith(status: newStatus);
                  }
                  return item;
                }).toList();

                _fetchedOrder = _fetchedOrder!.copyWith(items: updatedItems);
              }

              // If this was the last item in "collect all", reset the flag
              if (_isCollectingAll &&
                  _areAllItemsCollected()) {
                _isCollectingAll = false;
              }
            });

            // Dispatch FetchOrderDetails as backup
            context.read<OrderDetailsBloc>().add(
              FetchOrderDetails(widget.orderId),
            );

            // Show toast
            String successMessage = (widget.from && _fetchedOrder?.status?.toLowerCase() != 'assigned')
                ? AppLocalizations.of(context)!.itemDeliveredSuccessfully
                : AppLocalizations.of(context)!.itemCollectedSuccessfully;

            // Only show individual toasts if not collecting all, or show one consolidated one later
            if (!_isCollectingAll && !_isDeliveringAll) {
              ToastManager.show(
                context: context,
                message: successMessage,
                type: ToastType.success,
              );
            }
          } else if (state is ItemsCollectedError) {
            setState(() {
              _processingItemIds.remove(state.itemId);
              if (_isCollectingAll && _processingItemIds.isEmpty) {
                _isCollectingAll = false;
              }
            });

            ToastManager.show(
              context: context,
              message: state.errorMessage,
              type: ToastType.error,
            );
          }
        },
        builder: (context, itemsCollectedState) {
          return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
            listener: (context, state) {
              if (state is OrderDetailsSuccess) {
                // Check if we need to restore reachedDestination status from previous state
                setState(() {
                  _fetchedOrder = state.order;

                  // Reset confetti flag for new order data
                  if (_fetchedOrder?.id != widget.orderId) {
                    _hasShownConfetti = false;
                  }

                  // Update local state based on API response
                  if (_fetchedOrder?.items != null) {
                    for (var item in _fetchedOrder!.items!) {
                      // Update local state based on API status
                      if (item.id != null) {
                        String itemId = item.id.toString();

                        // If item is delivered according to API, add to delivered items
                        if (item.status?.toLowerCase() == 'delivered') {
                          _deliveredItems.add(itemId);
                        }

                        // If item is collected according to API, add to collected items
                        if (item.status?.toLowerCase() == 'collected' ||
                            item.status?.toLowerCase() == 'delivered') {
                          _collectedItems.add(itemId);
                        }

                        // If item has OTP verified according to API, add to OTP verified items
                        if (item.otpVerified == 1) {
                          _otpVerifiedItems.add(itemId);
                        }
                      }
                    }
                  }
                });
              } else if (state is OrderDetailsError) {
                setState(() {
                });
              }
            },
            builder: (context, state) {
              // Use fetched order data with restored reachedDestination values
              final order = _fetchedOrder;

              if (order == null) {
                return CustomScaffold(
                  appBar: CustomAppBarWithoutNavbar(
                    title: AppLocalizations.of(context)!.orderDetails,
                    showRefreshButton: true,
                    showThemeToggle: false,
                    onRefreshPressed: () {
                      // Only refresh if we don't have order data or if it's stale
                      // Don't refresh if we already have the latest state to preserve bloc updates
                      if (_fetchedOrder == null) {
                        _refreshOrderData();
                      } else {
                        // Show a message that data is already up to date
                        ToastManager.show(
                          context: context,
                          message: 'Order data is already up to date',
                          type: ToastType.info,
                        );
                      }
                    },
                    additionalActions: [
                      IconButton(
                        icon: Icon(
                          Icons.map,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () {
                          context.push(
                            AppRoutes.pickupRouteMap,
                            extra: {'order': order},
                          );
                        },
                        tooltip: AppLocalizations.of(context)!.goToMap,
                      ),
                      order?.status == "out_for_delivery"
                          ? IconButton(
                            icon: Icon(
                              Icons.call,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed:
                                () => _makePhoneCall(
                                  '${order?.shippingPhonecode ?? ''}${order?.shippingPhone ?? ''}',
                                ),
                            tooltip: AppLocalizations.of(context)!.call,
                          )
                          : SizedBox.shrink(),
                    ],
                  ),
                  body: const Center(child: LoadingWidget()),
                );
              }

              return CustomScaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                appBar: CustomAppBarWithoutNavbar(
                  title: AppLocalizations.of(context)!.orderDetails,
                  showRefreshButton: true,
                  showThemeToggle: false,
                  onRefreshPressed: () {
                    // Only refresh if we don't have order data or if it's stale
                    // Don't refresh if we already have the latest state to preserve bloc updates
                    if (_fetchedOrder == null) {
                      _refreshOrderData();
                    } else {
                      // Show a message that data is already up to date
                      ToastManager.show(
                        context: context,
                        message: 'Order data is already up to date',
                        type: ToastType.info,
                      );
                    }
                  },
                  additionalActions: [
                    IconButton(
                      icon: Icon(
                        Icons.map,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        order.status != "out_for_delivery"
                            ? context.push(
                              AppRoutes.mapDelivery,
                              extra: {'order': order},
                            )
                            : context.push(
                              AppRoutes.pickupRouteMap,
                              extra: {'order': order},
                            );
                      },
                      tooltip: AppLocalizations.of(context)!.goToMap,
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(18.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Banner
                      new_widgets.OrderStatusBanner(
                        orderStatus: order.status,
                        getStatusColor: _getStatusColor,
                        getDisplayStatus: _getDisplayStatus,
                      ),
                      SizedBox(height: 24.h),
                      Column(
                        children: [
                          StatisticsRow(order: order),
                          SizedBox(height: 12.h),

                          // Payment Method Card
                          new_widgets.PaymentMethodCard(order: order),
                          SizedBox(height: 12.h),

                          // Order Note Card
                          if (order.orderNote != null && order.orderNote != "")
                            new_widgets.OrderNoteCard(order: order),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      new_widgets.OrderItemsSection(
                        order: order,
                        isExpanded: _isItemsExpanded,
                        onToggle: () {
                          setState(() {
                            _isItemsExpanded = !_isItemsExpanded;
                          });
                        },
                        itemCards:
                            order.items
                                ?.map((item) => _buildItemCard(item))
                                .toList() ??
                            [],
                        onDeliverAll:
                            _useDeliverAll()
                                ? (_isDeliveringAll ? () {} : _deliverAllItems)
                                : null,
                        isDeliveringAll: _isDeliveringAll,
                        onCollectAll:
                            (!widget.from &&
                                    order.status?.toLowerCase() == 'assigned' &&
                                    !_areAllItemsCollected())
                                ? _collectAllItems
                                : null,
                      ),
                      SizedBox(height: 16.h),
                      // // Earnings Details Section
                      // new_widgets.EarningsDetailsSection(
                        // order: order,
                        // isExpanded: _isEarningsExpanded,
                        // onToggle: () {
                          // setState(() {
                            // _isEarningsExpanded = !_isEarningsExpanded;
                          // });
                        // },
                      // ),
                      // SizedBox(height: 16.h),

                      // Payment Method Section
                      new_widgets.PaymentInformationSection(
                        order: order,
                        isExpanded: _isPaymentExpanded,
                        onToggle: () {
                          setState(() {
                            _isPaymentExpanded = !_isPaymentExpanded;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Pricing Details Section
                      new_widgets.PricingDetailsSection(
                        order: order,
                        isExpanded: _isPricingExpanded,
                        onToggle: () {
                          setState(() {
                            _isPricingExpanded = !_isPricingExpanded;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      new_widgets.StoreDetailsSection(
                        order: order,
                        isExpanded: _isDeliveryExpanded,
                        onToggle: () {
                          setState(() {
                            _isDeliveryExpanded = !_isDeliveryExpanded;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Shipping Details Section
                      new_widgets.ShippingDetailsSection(
                        order: order,
                        isExpanded: _isStoreDetailsExpanded,
                        onToggle: () {
                          setState(() {
                            _isStoreDetailsExpanded = !_isStoreDetailsExpanded;
                          });
                        },
                      ),

                      SizedBox(
                        height: 100.h,
                      ), // Bottom padding for swipe button
                    ],
                  ),
                ),
                bottomSheet: _buildBottomSheet(),
                // Add confetti widget for celebration
                floatingActionButton: Stack(
                  children: [
                    // Confetti widget positioned to cover the entire screen
                    Positioned.fill(
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality:
                            BlastDirectionality
                                .explosive, // Explode from center
                        emissionFrequency: 0.05,
                        numberOfParticles: 20,
                        maxBlastForce: 5,
                        minBlastForce: 2,
                        gravity: 0.1,
                        colors: [
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                          Colors.orange,
                          Colors.red,
                          Colors.yellow,
                          Colors.pink,
                          Colors.teal,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to build the bottom sheet using the reusable widget
  Widget? _buildBottomSheet() {
    if (_fetchedOrder?.items == null) {
      return null;
    }

    // Check if order status is delivered first - this should take priority
    if (_fetchedOrder?.status?.toLowerCase() == 'delivered') {
      return ActionBottomSheet(
        buttonText: AppLocalizations.of(context)!.allDone,
        onPressed: () => _showEarningsPopup(),
        buttonColor: AppColors.primaryColor,
        textColor: Colors.white,
      );
    }

    // Simple logic: check if all items are collected or delivered
    bool allItemsCollected = _fetchedOrder!.items!.every((item) {
      // Check if item is collected from API status OR local collection state
      bool isCollectedFromApi = item.status?.toLowerCase() == 'collected';
      bool isCollectedFromLocal = _collectedItems.contains(item.id.toString());
      return isCollectedFromApi || isCollectedFromLocal;
    });

    bool allItemsDelivered = _fetchedOrder!.items!.every((item) {
      // Check if item is delivered from API status OR local delivery state
      bool isDeliveredFromApi = item.status?.toLowerCase() == 'delivered';
      bool isDeliveredFromLocal = _deliveredItems.contains(item.id.toString());
      return isDeliveredFromApi || isDeliveredFromLocal;
    });

    // Check if any items have reached destination and are delivered
    bool anyItemsReachedDestination = _fetchedOrder!.items!.any(
      (item) =>
          item.reachedDestination == true ||
          item.status?.toLowerCase() == 'delivered',
    );

    // Simple Case 1: If reachedDestination is false AND all items are collected → Show "View Pickup Route"
    if (!anyItemsReachedDestination && allItemsCollected) {
      return ActionBottomSheet(
        buttonText: AppLocalizations.of(context)!.viewPickupRoute,
        onPressed: () {
          context.push(
            AppRoutes.pickupRouteMap,
            extra: {
              'order': _fetchedOrder!,
              'bloc': context.read<OrderDetailsBloc>(),
            },
          );
        },
        buttonColor: AppColors.primaryColor,
        textColor: Colors.white,
      );
    }

    // Simple Case 2: If reachedDestination is true AND all items are delivered → Show "All Done"
    if (anyItemsReachedDestination && allItemsDelivered) {
      return ActionBottomSheet(
        buttonText: AppLocalizations.of(context)!.allDone,
        onPressed: _showEarningsPopup,
        buttonColor: AppColors.primaryColor,
        textColor: Colors.white,
      );
    }

    return null;
  }

  bool _areAllItemsCollected() {
    return OrderService.areAllItemsCollected(_fetchedOrder);
  }

  int _getTotalItems() {
    return OrderService.getTotalItems(_fetchedOrder);
  }

  bool _hasItemsRequiringOtp() {
    return OrderService.hasItemsRequiringOtp(_fetchedOrder);
  }

  bool _areAllOtpItemsVerified() {
    return OrderService.areAllOtpItemsVerified(_fetchedOrder);
  }

  bool _hasCodItems() {
    return OrderService.hasCodItems(_fetchedOrder);
  }

  void _showCodPopup() {
    DialogService.showCodPopup(context, _fetchedOrder);
  }

  void _showCongratulationsGif() {
    // Use the same earnings popup logic since it's similar
    _showEarningsPopup();
  }

  /// Items can't be collected before the seller's bag is scanned: opens the
  /// bag scan popup instead and returns false.
  bool _ensureBagScanned() {
    final order = _fetchedOrder;
    if (order?.id == null || !order!.needsBagScan) return true;
    context.read<RiderPopupCubit>().openAccepted(order.id!, stayOnScreen: true);
    ToastManager.show(
      context: context,
      message: 'Scan the bag assigned to this order before confirming pickup.',
      type: ToastType.warning,
    );
    return false;
  }

  /// Riders may only mark items delivered when they are within
  /// [_deliveryRangeMeters] of the customer's shipping location.
  static const double _deliveryRangeMeters = 100;
  bool _checkingDeliveryRange = false;

  Future<bool> _ensureNearDeliveryLocation() async {
    if (_checkingDeliveryRange) return false;
    final order = _fetchedOrder;
    final destLat = double.tryParse(order?.shippingLatitude ?? '');
    final destLng = double.tryParse(order?.shippingLongitude ?? '');
    // No coordinates on the order: nothing to verify against.
    if (destLat == null || destLng == null) return true;

    _checkingDeliveryRange = true;
    try {
      final position = await _getCurrentPosition();
      if (!mounted) return false;
      if (position == null) {
        ToastManager.show(
          context: context,
          message:
              'Unable to get your current location. Turn on GPS and try again.',
          type: ToastType.error,
        );
        return false;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destLat,
        destLng,
      );
      if (distance <= _deliveryRangeMeters) return true;

      final away =
          distance >= 1000
              ? '${(distance / 1000).toStringAsFixed(1)} km'
              : '${distance.round()} m';
      ToastManager.show(
        context: context,
        message:
            'You must be within ${_deliveryRangeMeters.round()} m of the '
            'delivery location to deliver. You are $away away.',
        type: ToastType.warning,
      );
      return false;
    } finally {
      _checkingDeliveryRange = false;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        // Native "turn on location" popup (Android); fall back to a dialog
        // that opens location settings if the rider declines or on iOS.
        final enabled = await loc.Location().requestService();
        if (!enabled) {
          LocationHandler.showLocationServiceDialog();
          return null;
        }
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        LocationHandler.showPermissionDeniedDialog(
          isPermanent: permission == LocationPermission.deniedForever,
        );
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Fall back to a recent fix if a fresh one times out.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            DateTime.now().difference(last.timestamp) <
                const Duration(minutes: 1)) {
          return last;
        }
      } catch (_) {}
      return null;
    }
  }

  void _collectItem(Items item) {
    if (!_ensureBagScanned()) return;
    // Collect the item directly (no OTP required)
    if (item.id != null) {
      // Set the current processing item ID for tracking
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      // Dispatch the API call - UI updates will be handled in BlocConsumer
      context.read<ItemsCollectedBloc>().add(
        ItemsCollected(item.id.toString()),
      );
    }
  }

  /// For COD orders, asks the rider how the customer paid (cash or UPI QR)
  /// before the final delivery. Returns `null` if delivery must not proceed,
  /// otherwise whether cash was collected (sent with the delivery request).
  Future<bool?> _collectCodPaymentIfNeeded(Items item) async {
    if (!_hasCodItems() || item.id == null) return false;
    final itemId = item.id.toString();

    setState(() => _processingItemIds.add(itemId));
    CodPaymentInstructions instructions;
    try {
      instructions = await CodPaymentRepo().getPaymentInstructions(itemId);
    } catch (e) {
      if (!mounted) return null;
      setState(() => _processingItemIds.remove(itemId));
      ToastManager.show(
        context: context,
        message: e.toString(),
        type: ToastType.error,
      );
      return null;
    }
    if (!mounted) return null;
    setState(() => _processingItemIds.remove(itemId));

    // Non-COD or already paid (e.g. UPI confirmed for an earlier item).
    if (!instructions.required || instructions.isCompleted) return false;

    final outcome = await CodPaymentSheet.show(
      context,
      orderItemId: itemId,
      instructions: instructions,
    );
    if (outcome == null) return null;
    return outcome == CodPaymentOutcome.cash;
  }

  /// Collected items that are waiting for the final delivery.
  List<Items> _pendingDeliveryItems() {
    final order = _fetchedOrder;
    if (order?.items == null) return [];
    final outForDelivery = order!.status?.toLowerCase() == 'out_for_delivery';
    return order.items!.where((item) {
      if (item.id == null) return false;
      final id = item.id.toString();
      final status = item.status?.toLowerCase();
      final delivered = status == 'delivered' || _deliveredItems.contains(id);
      final collected = status == 'collected' || _collectedItems.contains(id);
      return collected &&
          !delivered &&
          (outForDelivery || item.reachedDestination == true);
    }).toList();
  }

  /// With more than one item to deliver, a single "Deliver All" button
  /// replaces the per-item buttons.
  bool _useDeliverAll() =>
      _isDeliveringAll || _pendingDeliveryItems().length > 1;

  Future<void> _deliverAllItems() async {
    final pending = _pendingDeliveryItems();
    if (pending.isEmpty) return;
    if (!await _ensureNearDeliveryLocation() || !mounted) return;

    // One COD payment covers the whole order.
    final cashCollected = await _collectCodPaymentIfNeeded(pending.first);
    if (cashCollected == null || !mounted) return;

    bool needsOtp(Items item) =>
        item.product?.requiresOtp == 1 && item.otpVerified != 1;

    String? otp;
    if (pending.any(needsOtp)) {
      otp = await DialogService.showDeliveryOtpDialog(context);
      if (otp == null || otp.isEmpty || !mounted) return;
    }

    setState(() => _isDeliveringAll = true);
    final bloc = context.read<ItemsCollectedBloc>();
    var allDelivered = true;

    // Sequential, so the cash collection is committed with the first item
    // before the remaining items are marked delivered.
    for (var i = 0; i < pending.length; i++) {
      final itemId = pending[i].id.toString();
      final cash = cashCollected && i == 0;
      setState(() => _processingItemIds.add(itemId));

      final result = bloc.stream.firstWhere(
        (state) =>
            (state is ItemsCollectedSuccess && state.itemId == itemId) ||
            (state is ItemsCollectedError && state.itemId == itemId),
      );
      bloc.add(
        needsOtp(pending[i])
            ? ItemsCollectedWithOtp(
              orderItemId: itemId,
              otp: otp!,
              cashCollected: cash,
            )
            : ItemsDelivered(itemId, cashCollected: cash),
      );
      if (await result is ItemsCollectedError) {
        allDelivered = false;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _isDeliveringAll = false);
    if (allDelivered) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.allItemsDeliveredSuccessfully,
        type: ToastType.success,
      );
    }
  }

  void _deliverItemWithoutOtp(Items item) async {
    if (item.id != null) {
      if (!await _ensureNearDeliveryLocation() || !mounted) return;
      final cashCollected = await _collectCodPaymentIfNeeded(item);
      if (cashCollected == null || !mounted) return;

      // Set the current processing item ID for tracking
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      // Remove the force refresh that was causing bottom sheet to disappear
      // _forceBottomSheetRefresh();

      // Dispatch the API call to mark item as delivered
      context.read<ItemsCollectedBloc>().add(
        ItemsDelivered(item.id.toString(), cashCollected: cashCollected),
      );
    }
  }

  void _deliverItem(Items item) async {
    if (item.id != null) {
      if (!await _ensureNearDeliveryLocation() || !mounted) return;
      final cashCollected = await _collectCodPaymentIfNeeded(item);
      if (cashCollected == null || !mounted) return;

      // Show OTP dialog for delivery
      final String? otp = await _showDeliveryOtpDialog();

      if (otp != null && otp.isNotEmpty) {
        // Set the current processing item ID for tracking
        setState(() {
          _processingItemIds.add(item.id.toString());
        });

        // Dispatch the API call - UI updates will be handled in BlocConsumer
        context.read<ItemsCollectedBloc>().add(
          ItemsCollectedWithOtp(
            orderItemId: item.id.toString(),
            otp: otp,
            cashCollected: cashCollected,
          ),
        );
      }
    }
  }

  Future<String?> _showDeliveryOtpDialog() async {
    return await DialogService.showDeliveryOtpDialog(context);
  }

  void _showCustomerOtpDialog() async {
    await DialogService.showCustomerOtpDialog(context, _fetchedOrder);
  }

  Widget _buildItemCard(Items item) {
    return ItemCardService.buildItemCard(
      context: context,
      item: item,
      from: widget.from,
      collectedItems: _collectedItems,
      deliveredItems: _deliveredItems,
      otpVerifiedItems: _otpVerifiedItems,
      currentProcessingItemId: _isCollectingAll ? 'collecting_all' : (_processingItemIds.contains(item.id.toString()) ? item.id.toString() : null),
      fetchedOrder: _fetchedOrder,
      onCollect: () => _collectItem(item),
      onDelivered: () => _deliverItemWithoutOtp(item),
      onReachedDestination: () => _markItemReachedDestination(item),
      onItemOtpTap: _showItemOtpDialog,
      hideDeliverButton: _useDeliverAll(),
    );
  }

  void _showItemOtpDialog(Items item) async {
    bool requiresOtp = item.product?.requiresOtp == 1;

    if (!requiresOtp) {
      _deliverItemWithoutOtp(item);
      return;
    }

    if (!await _ensureNearDeliveryLocation() || !mounted) return;

    // Settle COD payment (cash / UPI QR) before asking for the delivery OTP
    final cashCollected = await _collectCodPaymentIfNeeded(item);
    if (cashCollected == null || !mounted) return;

    // Show simplified OTP dialog
    final String? otp = await DialogService.showDeliveryOtpDialog(context);

    if (otp != null && otp.isNotEmpty) {
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      context.read<ItemsCollectedBloc>().add(
        ItemsCollectedWithOtp(
          orderItemId: item.id.toString(),
          otp: otp,
          cashCollected: cashCollected,
        ),
      );
    }
  }

  void _collectAllItems() async {
    if (!_ensureBagScanned()) return;
    setState(() {
      _isCollectingAll = true;
    });

    OrderService.collectAllItems(
      order: _fetchedOrder,
      collectedItems: _collectedItems,
      onItemCollected: (itemId) {
        context.read<ItemsCollectedBloc>().add(ItemsCollected(itemId));
      },
      onError: (errorMessage) {
        setState(() {
          _isCollectingAll = false;
        });
        ToastManager.show(
          context: context,
          message: errorMessage,
          type: ToastType.error,
        );
      },
    );
  }

  void _showEarningsPopup() {
    // Show confetti only if it hasn't been shown for this order yet
    if (!_hasShownConfetti) {
      _hasShownConfetti = true;
      _confettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64.sp),
              SizedBox(height: 16.h),
              CustomText(
                text: AppLocalizations.of(context)!.orderCompleted,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text:
                    AppLocalizations.of(context)!.allItemsDeliveredSuccessfully,
                textAlign: TextAlign.center,
                fontSize: 16,
                color: Colors.grey,
              ),
              SizedBox(height: 16.h),
              // Container(
                // padding: EdgeInsets.all(16.w),
                // decoration: BoxDecoration(
                  // color: AppColors.primaryColor.withValues(alpha: 0.1),
                  // borderRadius: BorderRadius.circular(8.r),
                // ),
                // child: Column(
                  // children: [
                    // CustomText(
                      // text: AppLocalizations.of(context)!.yourEarningsBreakdown,
                      // fontWeight: FontWeight.bold,
                      // fontSize: 16.sp,
                    // ),
                    // SizedBox(height: 12.h),
                    // // Breakdown details
                    // if (_fetchedOrder?.earnings?.breakdown != null) ...[
                      // _buildBreakdownRow(
                        // AppLocalizations.of(context)!.baseFee,
                        // _fetchedOrder?.earnings?.breakdown?.baseFee,
                      // ),
                      // _buildBreakdownRow(
                        // AppLocalizations.of(context)!.storePickupFee,
                        // _fetchedOrder?.earnings?.breakdown?.perStorePickupFee,
                      // ),
                      // _buildBreakdownRow(
                        // AppLocalizations.of(context)!.distanceFee,
                        // _fetchedOrder?.earnings?.breakdown?.distanceBasedFee,
                      // ),
                      // _buildBreakdownRow(
                        // AppLocalizations.of(context)!.orderIncentive,
                        // _fetchedOrder?.earnings?.breakdown?.perOrderIncentive,
                      // ),
                      // const Divider(height: 16, thickness: 1),
                    // ],
                    // // Total
                    // Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // children: [
                        // CustomText(
                          // text: AppLocalizations.of(context)!.totalEarnings,
                          // fontWeight: FontWeight.bold,
                          // fontSize: 16,
                        // ),
                        // CustomText(
                          // text: CurrencyFormatter.formatAmount(
                            // context,
                            // _fetchedOrder?.earnings?.total ?? 0,
                          // ),
                          // fontSize: 20.sp,
                          // fontWeight: FontWeight.w600,
                          // color: AppColors.primaryColor,
                        // ),
                      // ],
                    // ),
                  // ],
                // ),
              // ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      textSize: 15.sp,
                      text: AppLocalizations.of(context)!.ok,
                      onPressed: () {
                        context.pop();
                      },
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.white,
                      borderRadius: 8.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      textStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomButton(
                      textSize: 15.sp,
                      text: AppLocalizations.of(context)!.goToHome,
                      onPressed: () async {
                        // Close the dialog first
                        context.pop();

                        // Determine the correct tab based on where user came from
                        int targetTab = _getTargetTabForNavigation();

                        // Refresh the appropriate list based on target tab
                        if (targetTab == 0) {
                          // Available Orders tab - refresh available orders list
                          context.read<AvailableOrdersBloc>().add(
                            AllAvailableOrdersList(forceRefresh: true),
                          );
                        } else if (targetTab == 1) {
                          // My Orders tab - refresh my orders list
                          context.read<MyOrdersBloc>().add(
                            AllMyOrdersList(forceRefresh: true),
                          );
                        }

                        // Navigate to feed with the appropriate tab
                        context.go('${AppRoutes.feed}?tab=$targetTab');
                      },
                      textColor: Colors.black87,
                      borderRadius: 8.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      textStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildBreakdownRow(String label, double? amount) {
    // return UIHelperService.buildBreakdownRow(context, label, amount);
  // }

  String _getStatusText() {
    return OrderService.getStatusText(
      context,
      _fetchedOrder,
      widget.from,
    );
  }

  int _getCollectedItemsCount() {
    return OrderService.getCollectedItemsCount(_fetchedOrder);
  }

  void _handleButtonPress() {
    OrderService.handleButtonPress(
      context: context,
      order: _fetchedOrder,
      from: widget.from,
      onCollectAllItems: _collectAllItems,
      onShowEarningsPopup: _showEarningsPopup,
      onNavigateToPickupRoute: () {
        context.push(
          AppRoutes.pickupRouteMap,
          extra: {
            'order': _fetchedOrder!,
            'bloc': context.read<OrderDetailsBloc>(),
          },
        );
      },
      onNavigateToMap: () {},
    );
  }

  void _markItemReachedDestination(Items item) {
    if (item.id != null) {
      OrderService.markItemReachedDestination(
        orderId: widget.orderId,
        itemId: item.id!,
        onMarkItemReachedDestination: (orderId, itemId) {
          context.read<OrderDetailsBloc>().add(
            MarkItemReachedDestination(orderId, itemId),
          );
        },
      );
    }
  }

  int _getTargetTabForNavigation() {
    return OrderService.getTargetTabForNavigation(
      widget.sourceTab,
      widget.from,
    );
  }
}

Future<void> _makePhoneCall(String phoneNumber) async {
  await PhoneService.makePhoneCall(phoneNumber);
}
