import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/utils/widgets/toast_message.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/available_orders_bloc/available_orders_event.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/my_orders_bloc/my_orders_event.dart';
import 'package:nagpur_rider/screens/feed_page/model/available_orders.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/widgets/bag_scan_panel.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/widgets/common.dart';
import 'package:nagpur_rider/screens/system_settings/bloc/system_settings_bloc.dart';

/// Sits in `MaterialApp.builder`, above every route. While orders with a
/// seller bag are waiting it covers the app with an order card the rider
/// accepts. Withdrawn offers are removed by the backend. An accepted order then asks for its bag to be scanned;
/// the rider can tuck it away (to ride to the store), leaving a "Scan bag"
/// button over the app until the scan is done.
class RiderOrderOverlay extends StatefulWidget {
  final Widget child;

  const RiderOrderOverlay({super.key, required this.child});

  @override
  State<RiderOrderOverlay> createState() => _RiderOrderOverlayState();
}

class _RiderOrderOverlayState extends State<RiderOrderOverlay> {
  /// What the router below last reported about being able to go back.
  bool _routesCanPop = false;
  bool _isShown = false;

  @override
  void initState() {
    super.initState();
    if (context.read<RiderPopupCubit>().state.isShown) {
      _isShown = true;
      _report(true);
    }
  }

  /// With predictive back (enforced on recent Android) the system only sends
  /// Back to Flutter when the framework says it can handle it. While the
  /// popup is up, report "can handle back" so the press reaches
  /// RiderPopupController.didPopRoute.
  bool _onNavigationNotification(NavigationNotification notification) {
    _routesCanPop = notification.canHandlePop;
    if (!_isShown) return false;
    _report(true);
    return true;
  }

  void _report(bool canHandlePop) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NavigationNotification(canHandlePop: canHandlePop).dispatch(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RiderPopupCubit, RiderPopupState>(
      listenWhen:
          (prev, curr) =>
              prev.isShown != curr.isShown ||
              prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        _isShown = state.isShown;
        _report(_isShown || _routesCanPop);
        if (state.errorMessage != null) {
          ToastManager.show(
            context: context,
            message: state.errorMessage!,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        _isShown = state.isShown;
        // Prices use the currency from system settings, which may load
        // after the popup first shows.
        context.watch<SystemSettingsBloc>();
        return Stack(
          children: [
            NotificationListener<NavigationNotification>(
              onNotification: _onNavigationNotification,
              child: widget.child,
            ),
            if (state.isShown)
              Positioned.fill(child: _PopupBarrier(state: state))
            else if (state.showsReminder)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 84,
                child: _ScanReminder(order: state.accepted.first),
              ),
          ],
        );
      },
    );
  }
}

/// Reloads the order lists after the popup changed an order.
void _refreshOrderLists(BuildContext context) {
  try {
    context.read<AvailableOrdersBloc>().add(
      AllAvailableOrdersList(forceRefresh: true),
    );
    context.read<MyOrdersBloc>().add(AllMyOrdersList(forceRefresh: true));
  } catch (e) {
    debugPrint('[RiderPopup] list refresh failed: $e');
  }
}

/// Opens the route to the store for [order], like the orders list does.
void _navigateToStore(BuildContext context, RiderPopupOrder order) {
  context.read<RiderPopupCubit>().setMinimized(true);
  MyAppRoute.router.push(
    AppRoutes.mapDelivery,
    extra: {
      'order': Orders.fromJson(order.raw),
      'currentLat': '0',
      'currentLng': '0',
    },
  );
}

class _PopupBarrier extends StatelessWidget {
  final RiderPopupState state;

  const _PopupBarrier({required this.state});

  @override
  Widget build(BuildContext context) {
    final top = state.top!;
    final isAccepted = state.isAccepted(top);
    final cubit = context.read<RiderPopupCubit>();

    // This sits above the app's Navigator, so it brings its own Overlay for
    // the barcode text field (selection handles, toolbar).
    return Overlay.wrap(
      child: Material(
        color: popupSurface(context),
        child: Padding(
          // Keep the text field above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: AppColors.primaryColor,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Center(
                      child: _WaitingBadge(
                        accepted: state.accepted.length,
                        available: state.available.length,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    layoutBuilder:
                        (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, if (current != null) current],
                        ),
                    transitionBuilder:
                        (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.96,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                    child:
                        isAccepted
                            ? BagScanPanel(
                              key: ValueKey('scan-${top.id}'),
                              order: top,
                              isScanning: state.scanningOrderId == top.id,
                              onMinimize: () => cubit.setMinimized(true),
                              onNavigateToStore:
                                  () => _navigateToStore(context, top),
                              onProceed: () {
                                final open = cubit.finishPickup(top);
                                _refreshOrderLists(context);
                                if (open) {
                                  MyAppRoute.router.push(
                                    AppRoutes.orderDetails,
                                    extra: {
                                      'orderId': top.id,
                                      'from': true,
                                      'sourceTab': 1,
                                    },
                                  );
                                }
                              },
                            )
                            : _IncomingOrderCard(
                              key: ValueKey(top.id),
                              order: top,
                              position: 1,
                              total: state.available.length,
                              isAccepting: state.acceptingOrderId == top.id,
                              errorMessage:
                                  state.failedOrderId == top.id
                                      ? state.errorMessage
                                      : null,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingBadge extends StatelessWidget {
  final int accepted;
  final int available;

  const _WaitingBadge({required this.accepted, required this.available});

  @override
  Widget build(BuildContext context) {
    final text =
        accepted > 0
            ? (accepted == 1
                ? '1 bag to pick up'
                : '$accepted orders to pick up')
            : (available == 1 ? '1 new order' : '$available new orders');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accepted > 0 ? Colors.orange.shade800 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accepted > 0
                ? Icons.shopping_bag_outlined
                : Icons.notifications_active,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  final RiderPopupOrder order;
  final int position;
  final int total;
  final bool isAccepting;
  final String? errorMessage;

  const _IncomingOrderCard({
    super.key,
    required this.order,
    required this.position,
    required this.total,
    required this.isAccepting,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = order.createdAt?.toLocal();
    final tiles = <(String, String)>[
      (
        'ORDERED',
        created == null ? '—' : DateFormat('d MMM, HH:mm').format(created),
      ),
      ('PAYMENT', paymentLabel(order.paymentMethod)),
      ('TOTAL', formatPopupAmount(context, order.total)),
      (
        'ITEMS',
        order.items.length == 1 ? '1 item' : '${order.items.length} items',
      ),
    ];

    return ColoredBox(
      color: popupSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _IncomingHeader(position: position, total: total),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 8) / 2;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (label, value) in tiles)
                                SizedBox(
                                  width: width,
                                  child: _InfoTile(label: label, value: value),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      PopupSection(
                        title: 'PICKUP',
                        child: Column(
                          children: [
                            for (final s in order.baggedSellerOrders)
                              BagRow(sellerOrder: s),
                            for (final c in order.pickupContacts)
                              ContactRow(
                                icon: Icons.storefront_outlined,
                                name: c.name,
                                phone: c.phone,
                              ),
                          ],
                        ),
                      ),
                      PopupSection(
                        title: 'DROP',
                        child: ContactRow(
                          icon: Icons.location_on_outlined,
                          name: order.customerName,
                          phone: '',
                          subtitle: order.customerAddress,
                        ),
                      ),
                      if (order.items.isNotEmpty)
                        PopupSection(
                          title: 'ITEMS',
                          child: Column(
                            children: [
                              for (final item in order.items)
                                PopupItemRow(item: item),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupBottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorMessage != null) ...[
                  Text(
                    "Couldn't accept this order. $errorMessage",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                PopupPrimaryButton(
                  label: errorMessage != null ? 'Retry accept' : 'Accept order',
                  color: Colors.green.shade600,
                  isLoading: isAccepting,
                  onPressed: () async {
                    final ok = await context.read<RiderPopupCubit>().accept(
                      order,
                    );
                    if (ok && context.mounted) {
                      _refreshOrderLists(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingHeader extends StatelessWidget {
  final int position;
  final int total;

  const _IncomingHeader({required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  total > 1 ? 'NEW ORDER · $position OF $total' : 'NEW ORDER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bag ready for pickup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Accept, ride to the store and scan the assigned bag.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: popupMutedSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating button over the app while an accepted order's bag is unscanned.
class _ScanReminder extends StatelessWidget {
  final RiderPopupOrder order;

  const _ScanReminder({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade800,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<RiderPopupCubit>().setMinimized(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scan bag for order #${order.orderNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
