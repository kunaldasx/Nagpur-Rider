import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../model/available_orders.dart';
import 'statistics_card.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

class StatisticsRow extends StatelessWidget {
  final Orders order;

  const StatisticsRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order ID Card
          StatisticsCard(
            title: AppLocalizations.of(context)!.orderId,
            value: '${order.id}',
            icon: Icons.receipt,
            iconBackgroundColor: Colors.blue[50]!,
            iconColor: Colors.blue[600]!,
          ),
          SizedBox(width: 12.w),

          // Total Distance Card
          StatisticsCard(
            title: AppLocalizations.of(context)!.totalDistance,
            value:
                '${order.deliveryRoute?.totalDistance?.toStringAsFixed(1) ?? '0.0'} km',
            icon: Icons.straighten,
            iconBackgroundColor: Colors.orange[50]!,
            iconColor: Colors.orange[600]!,
          ),
          SizedBox(width: 12.w),

          // // Total Earnings Card
          // StatisticsCard(
            // title: AppLocalizations.of(context)!.totalEarnings,
            // value: CurrencyFormatter.formatAmount(
              // context,
              // order.earnings?.total ?? '0',
            // ),
            // icon: Icons.account_balance_wallet,
            // iconBackgroundColor: Colors.green[50]!,
            // iconColor: Colors.green[600]!,
            // valueColor: Colors.green[600]!,
          // ),
        ],
      ),
    );
  }
}
