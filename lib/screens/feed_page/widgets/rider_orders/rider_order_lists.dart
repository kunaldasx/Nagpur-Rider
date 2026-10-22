import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../../config/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../bloc/available_orders_bloc/available_orders_state.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../../bloc/my_orders_bloc/my_orders_event.dart';
import '../../bloc/my_orders_bloc/my_orders_state.dart';
import '../../model/available_orders.dart';
import '../my_orders/my_order_card.dart';
import 'rider_order_cards.dart';

/// Lays out order cards either as a page-level scrolling list (with pull to
/// refresh and pagination) or, when [embedded], as a short non-scrolling
/// column for use inside another scroll view.
class _OrdersListView extends StatefulWidget {
  final List<Orders> orders;
  final bool hasReachedMax;
  final bool embedded;
  final int? maxItems;
  final Widget Function(Orders order) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  /// Shown above the cards in page mode.
  final Widget? leading;

  const _OrdersListView({
    required this.orders,
    required this.hasReachedMax,
    required this.embedded,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.maxItems,
    this.leading,
  });

  @override
  State<_OrdersListView> createState() => _OrdersListViewState();
}

class _OrdersListViewState extends State<_OrdersListView> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      final visible =
          widget.maxItems == null
              ? widget.orders
              : widget.orders.take(widget.maxItems!).toList();
      return Column(children: visible.map(widget.itemBuilder).toList());
    }

    final showLoader = !widget.hasReachedMax;
    final offset = widget.leading == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 14.h, bottom: 16.h),
        itemCount: offset + widget.orders.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < offset) return widget.leading!;
          final orderIndex = index - offset;
          if (orderIndex >= widget.orders.length) {
            return Center(child: LoadingWidget(size: 80.sp));
          }
          return widget.itemBuilder(widget.orders[orderIndex]);
        },
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool embedded;
  final String lottie;
  final Widget? action;
  final Future<void> Function()? onRefresh;

  const _ListMessage({
    required this.title,
    required this.embedded,
    this.subtitle,
    this.lottie = 'assets/lottie/NotDataFound.json',
    this.action,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            lottie,
            width: embedded ? 120.w : 200.w,
            height: embedded ? 120.h : 200.h,
            fit: BoxFit.contain,
          ),
          CustomText(
            text: title,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
            color: RiderUiColors.muted(context),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 6.h),
            CustomText(
              text: subtitle!,
              fontSize: 13,
              textAlign: TextAlign.center,
              color: RiderUiColors.muted(context),
            ),
          ],
          if (action != null) ...[SizedBox(height: 16.h), action!],
        ],
      ),
    );

    if (embedded || onRefresh == null) return Center(child: content);

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: content),
              ),
            ),
      ),
    );
  }
}

Widget _loading(bool embedded) => Padding(
  padding: EdgeInsets.symmetric(vertical: embedded ? 30.h : 0),
  child: Center(child: LoadingWidget(size: embedded ? 80.sp : 150.sp)),
);

/// Orders available to accept (Accept / Decline cards).
class UpcomingOrdersList extends StatefulWidget {
  final bool embedded;
  final int? maxItems;

  const UpcomingOrdersList({super.key, this.embedded = false, this.maxItems});

  @override
  State<UpcomingOrdersList> createState() => _UpcomingOrdersListState();
}

class _UpcomingOrdersListState extends State<UpcomingOrdersList> {
  @override
  void initState() {
    super.initState();
    if (context.read<DeliveryBoyStatusBloc>().state.isOnline) {
      context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
    }
  }

  Future<void> _refresh() async {
    context.read<AvailableOrdersBloc>().add(
      AllAvailableOrdersList(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      listenWhen: (previous, current) => previous.isOnline != current.isOnline,
      listener: (context, state) {
        if (state.isOnline) {
          context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
        }
      },
      builder: (context, statusState) {
        if (!statusState.isOnline) {
          return _ListMessage(
            embedded: widget.embedded,
            lottie: 'assets/lottie/notactive.json',
            title: l10n.accountInactive,
            subtitle: l10n.activateAccountToViewOrders,
            action: ElevatedButton.icon(
              onPressed:
                  () => context.read<DeliveryBoyStatusBloc>().add(
                    ToggleStatus(true),
                  ),
              icon: Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 18.sp,
              ),
              label: CustomText(
                text: l10n.activateAccount,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<Set<int>>(
          valueListenable: DeclinedOrders.ids,
          builder: (context, declined, _) {
            return BlocBuilder<AvailableOrdersBloc, AvailableOrdersState>(
              builder: (context, state) {
                List<Orders>? orders;
                bool hasReachedMax = true;
                if (state is AvailableOrdersLoaded) {
                  orders = state.availableOrders;
                  hasReachedMax = state.hasReachedMax;
                } else if (state is AvailableOrdersRefreshing) {
                  orders = state.availableOrders;
                  hasReachedMax = state.hasReachedMax;
                }

                if (orders == null) {
                  if (state is AvailableOrdersLoading ||
                      state is AvailableOrdersInitial) {
                    return _loading(widget.embedded);
                  }
                }

                final visible =
                    (orders ?? [])
                        .where((order) => !declined.contains(order.id))
                        .toList();

                final emptyMessage = _ListMessage(
                  embedded: widget.embedded,
                  title: l10n.noAvailableOrders,
                  subtitle: l10n.ordersWillAppearHere,
                  onRefresh: _refresh,
                );

                if (visible.isEmpty && widget.embedded) return emptyMessage;

                return _OrdersListView(
                  leading:
                      widget.embedded
                          ? null
                          : Column(
                            children: [
                              const _ActiveOrders(),
                              if (visible.isEmpty)
                                _ListMessage(
                                  embedded: true,
                                  title: l10n.noAvailableOrders,
                                  subtitle: l10n.ordersWillAppearHere,
                                ),
                            ],
                          ),
                  orders: visible,
                  hasReachedMax: hasReachedMax,
                  embedded: widget.embedded,
                  maxItems: widget.maxItems,
                  onRefresh: _refresh,
                  onLoadMore:
                      () => context.read<AvailableOrdersBloc>().add(
                        LoadMoreAvailableOrders(''),
                      ),
                  itemBuilder:
                      (order) => UpcomingOrderCard(
                        key: ValueKey('upcoming_${order.id}'),
                        order: order,
                      ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Orders the rider has accepted but not finished yet, so they can be resumed.
class _ActiveOrders extends StatelessWidget {
  const _ActiveOrders();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyOrdersBloc()..add(AllMyOrdersList(type: 'assigned')),
      child: BlocBuilder<MyOrdersBloc, MyOrdersState>(
        builder: (context, state) {
          final orders =
              state is MyOrdersLoaded
                  ? state.myOrders
                  : state is MyOrdersRefreshing
                  ? state.myOrders
                  : const <Orders>[];
          final active =
              orders.where((order) {
                final status = order.status?.toLowerCase();
                return status != 'delivered' &&
                    status != 'completed' &&
                    status != 'canceled' &&
                    status != 'cancelled';
              }).toList();
          if (active.isEmpty) return const SizedBox.shrink();

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.myOrders,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 8.h),
              ...active.map(
                (order) => MyOrderCard(
                  key: ValueKey('active_${order.id}'),
                  order: order,
                  isDarkTheme: isDark,
                ),
              ),
              SizedBox(height: 6.h),
            ],
          );
        },
      ),
    );
  }
}

/// Rider's own orders filtered by [status] ('completed' or 'canceled').
/// Each list keeps its own bloc so tabs don't overwrite each other.
class RiderOrdersByStatusList extends StatelessWidget {
  final String status;
  final bool embedded;
  final int? maxItems;

  const RiderOrdersByStatusList({
    super.key,
    required this.status,
    this.embedded = false,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyOrdersBloc()..add(AllMyOrdersList(type: status)),
      child: _RiderOrdersByStatusView(
        status: status,
        embedded: embedded,
        maxItems: maxItems,
      ),
    );
  }
}

class _RiderOrdersByStatusView extends StatelessWidget {
  final String status;
  final bool embedded;
  final int? maxItems;

  const _RiderOrdersByStatusView({
    required this.status,
    required this.embedded,
    this.maxItems,
  });

  bool get _isCancelled => status == 'canceled' || status == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> refresh() async {
      context.read<MyOrdersBloc>().add(
        AllMyOrdersList(type: status, forceRefresh: true),
      );
    }

    return BlocBuilder<MyOrdersBloc, MyOrdersState>(
      builder: (context, state) {
        List<Orders>? orders;
        bool hasReachedMax = true;
        if (state is MyOrdersLoaded) {
          orders = state.myOrders;
          hasReachedMax = state.hasReachedMax;
        } else if (state is MyOrdersRefreshing) {
          orders = state.myOrders;
          hasReachedMax = state.hasReachedMax;
        }

        if (orders == null) {
          if (state is MyOrdersError) {
            return _ListMessage(
              embedded: embedded,
              title: l10n.noOrdersFound,
              onRefresh: refresh,
              action: TextButton(
                onPressed: refresh,
                child: CustomText(
                  text: l10n.retry,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return _loading(embedded);
        }

        if (orders.isEmpty) {
          return _ListMessage(
            embedded: embedded,
            title: l10n.noOrdersFound,
            onRefresh: refresh,
          );
        }

        return _OrdersListView(
          orders: orders,
          hasReachedMax: hasReachedMax,
          embedded: embedded,
          maxItems: maxItems,
          onRefresh: refresh,
          onLoadMore:
              () => context.read<MyOrdersBloc>().add(LoadMoreMyOrders(status)),
          itemBuilder:
              (order) =>
                  _isCancelled
                      ? CancelledOrderCard(
                        key: ValueKey('cancelled_${order.id}'),
                        order: order,
                      )
                      : DeliveredOrderCard(
                        key: ValueKey('delivered_${order.id}'),
                        order: order,
                      ),
        );
      },
    );
  }
}
