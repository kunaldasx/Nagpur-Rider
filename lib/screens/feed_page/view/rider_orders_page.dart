import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/connectivity_mixin.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../dashboard/bloc/notification/notification_bloc.dart';
import '../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../bloc/available_orders_bloc/available_orders_event.dart';
import '../widgets/rider_orders/rider_order_cards.dart';
import '../widgets/rider_orders/rider_order_lists.dart';

/// "Order Details" screen of the Orders tab: Upcoming / Delivered / Cancel.
class RiderOrdersPage extends StatefulWidget {
  /// 0 = Upcoming, 1 = Delivered, 2 = Cancel.
  final int initialTab;

  const RiderOrdersPage({super.key, this.initialTab = 0});

  @override
  State<RiderOrdersPage> createState() => _RiderOrdersPageState();
}

class _RiderOrdersPageState extends State<RiderOrdersPage>
    with WidgetsBindingObserver, ConnectivityMixin {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 2);
    WidgetsBinding.instance.addObserver(this);
    context.read<NotificationBloc>().add(GetUnreadCount());
  }

  @override
  void didUpdateWidget(covariant RiderOrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() => _tab = widget.initialTab.clamp(0, 2));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 0 && mounted) {
      context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return buildWithConnectivity(
      onRetry: () => setState(() {}),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(AppRoutes.home);
        },
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 26.sp,
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                ),
                title: CustomText(
                  text: l10n.orderDetails,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    SizedBox(height: 6.h),
                    RiderPillTabs(
                      labels: [l10n.upcoming, l10n.delivered, l10n.cancel],
                      selectedIndex: _tab,
                      onChanged: (index) => setState(() => _tab = index),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: const [
                          UpcomingOrdersList(),
                          RiderOrdersByStatusList(status: 'completed'),
                          RiderOrdersByStatusList(status: 'canceled'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
