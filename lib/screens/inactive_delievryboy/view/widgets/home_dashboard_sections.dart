import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_images.dart';
import '../../../../config/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../feed_page/model/available_orders.dart';
import '../../../feed_page/repo/my_orders.dart';
import '../../../feed_page/widgets/rider_orders/rider_order_cards.dart';
import '../../../feed_page/widgets/rider_orders/rider_order_lists.dart';
import '../../model/home_stats_model.dart';

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.sameColorChange,
  borderRadius: BorderRadius.circular(16.r),
  border: Border.all(color: RiderUiColors.cardBorder(context)),
);

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const HomeSectionTitle({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: CustomText(
              text: AppLocalizations.of(context)!.viewAll,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
      ],
    );
  }
}

class HomeProfileCard extends StatelessWidget {
  final DeliveryBoyData? deliveryBoy;

  const HomeProfileCard({super.key, this.deliveryBoy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = deliveryBoy?.profileImage ?? '';
    final name =
        (deliveryBoy?.fullName ?? '').isNotEmpty
            ? deliveryBoy!.fullName
            : l10n.deliveryPartner;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 82.w,
              height: 82.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  image.startsWith('http')
                      ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Image.asset(AppImages.splashLogoo),
                      )
                      : Image.asset(AppImages.splashLogoo, fit: BoxFit.cover),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: name,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: l10n.deliveryPartner,
                    fontSize: 12,
                    color: RiderUiColors.muted(context),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.secondaryColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 3.w),
                      CustomText(
                        text: (deliveryBoy?.rating ?? 0).toStringAsFixed(1),
                        fontSize: 12,
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: RiderUiColors.band(context),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 13.sp,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            CustomText(
                              text:
                                  '${deliveryBoy?.totalDeliveries ?? 0} ${l10n.deliveries}',
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// COD / Online collected today plus today's total earnings.
///
/// The home API only returns total earnings, so the COD / Online split is
/// summed from today's completed orders.
class HomeTodayEarnings extends StatefulWidget {
  final double totalEarnings;

  const HomeTodayEarnings({super.key, required this.totalEarnings});

  @override
  State<HomeTodayEarnings> createState() => _HomeTodayEarningsState();
}

class _HomeTodayEarningsState extends State<HomeTodayEarnings> {
  late Future<({double cod, double online})> _payments;

  @override
  void initState() {
    super.initState();
    _payments = _loadTodayPayments();
  }

  Future<({double cod, double online})> _loadTodayPayments() async {
    double cod = 0;
    double online = 0;
    try {
      final response = await MyOrdersRepo().myOrdersList(
        limit: 50,
        offset: 0,
        status: 'completed',
      );
      final list = response['data']?['orders'];
      if (list is! List) return (cod: cod, online: online);

      final now = DateTime.now();
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final order = Orders.fromJson(item);
        final date = DateTime.tryParse(order.updatedAt ?? '')?.toLocal();
        if (date == null ||
            date.year != now.year ||
            date.month != now.month ||
            date.day != now.day) {
          continue;
        }
        final amount =
            double.tryParse(order.finalTotal ?? '') ??
            double.tryParse(order.totalPayable ?? '') ??
            0;
        final method = (order.paymentMethod ?? '').toLowerCase();
        if (method.contains('cod') || method.contains('cash')) {
          cod += amount;
        } else {
          online += amount;
        }
      }
    } catch (_) {
      // Leave both at zero when the orders can't be loaded.
    }
    return (cod: cod, online: online);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        HomeSectionTitle(
          title: l10n.todayEarnings,
          onViewAll: () => context.go(AppRoutes.pockets),
        ),
        SizedBox(height: 10.h),
        FutureBuilder<({double cod, double online})>(
          future: _payments,
          builder: (context, snapshot) {
            final cod = snapshot.data?.cod ?? 0;
            final online = snapshot.data?.online ?? 0;
            return Row(
              children: [
                Expanded(
                  child: _PaymentTile(
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.primaryColor,
                    label: l10n.codPayment,
                    amount: cod,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _PaymentTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.warningColor,
                    label: l10n.onlinePayment,
                    amount: online,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: RiderUiColors.green,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: l10n.totalEarnings,
                    fontSize: 13,
                    color: RiderUiColors.muted(context),
                  ),
                  CustomText(
                    text: CurrencyFormatter.formatAmount(
                      context,
                      widget.totalEarnings,
                    ),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;

  const _PaymentTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: label,
                  fontSize: 11,
                  color: RiderUiColors.muted(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  text: CurrencyFormatter.formatAmount(context, amount),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "My Order Details" with Available / Delivered tabs (first few orders).
class HomeMyOrderDetails extends StatefulWidget {
  const HomeMyOrderDetails({super.key});

  @override
  State<HomeMyOrderDetails> createState() => _HomeMyOrderDetailsState();
}

class _HomeMyOrderDetailsState extends State<HomeMyOrderDetails> {
  static const int _previewCount = 3;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        HomeSectionTitle(
          title: l10n.myOrderDetails,
          onViewAll: () => context.go('${AppRoutes.feed}?tab=$_tab'),
        ),
        SizedBox(height: 10.h),
        RiderPillTabs(
          labels: [l10n.availableOrders, l10n.deliveredOrders],
          selectedIndex: _tab,
          onChanged: (index) => setState(() => _tab = index),
        ),
        SizedBox(height: 14.h),
        _tab == 0
            ? const UpcomingOrdersList(embedded: true, maxItems: _previewCount)
            : const RiderOrdersByStatusList(
              status: 'completed',
              embedded: true,
              maxItems: _previewCount,
            ),
      ],
    );
  }
}
