// widgets/pickup_order/my_pickups_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/utils/widgets/custom_card.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import '../../model/return_orders_list_model.dart';
import '../../view/map/return_pickup/return_handoff_dialog.dart';

class MyPickupsCard extends StatelessWidget {
  final Pickups pickup;

  const MyPickupsCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return _MyPickupsCardContent(pickup: pickup);
  }
}

class _MyPickupsCardContent extends StatelessWidget {
  final Pickups pickup;

  const _MyPickupsCardContent({required this.pickup});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'picked_up':
        return Colors.blue;
      case 'delivered_to_seller':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status, BuildContext context) {
    switch (status) {
      case 'picked_up':
        return AppLocalizations.of(context)!.pickup;
      case 'delivered_to_seller':
        return AppLocalizations.of(context)!.delivered;
      default:
        return AppLocalizations.of(context)!.assigned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = pickup.store;
    final status = pickup.pickupStatus ?? 'pending';
    final isDelivered = status == 'delivered_to_seller';

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: () {
          context.push(
            AppRoutes.pickupOrderDetails,
            extra: {'returnId': pickup.id.toString()},
          );
        },
        child: CustomCard(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text:
                        '${AppLocalizations.of(context)!.pickup} #${pickup.id}',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: CustomText(
                      text: _getStatusText(status, context),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Pickup Address
              if (store?.address != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomText(
                        text: store!.address!,
                        fontSize: 14.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 12.h),

              // Store + 1 Item
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 16.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text:
                            store?.name ??
                            AppLocalizations.of(context)!.unknown,
                        fontSize: 14.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  SizedBox(width: 16.w),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: "1 ${AppLocalizations.of(context)!.item}",
                        fontSize: 14.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // // Earnings
              // CustomText(
              // text: AppLocalizations.of(context)!.earnings,
              // fontSize: 12.sp,
              // color: Theme.of(
              // context,
              // ).colorScheme.onSurface.withValues(alpha: 0.6),
              // ),
              // CustomText(
              // text: CurrencyFormatter.formatAmount(
              // context,
              // pickup.earnings?.total,
              // ),
              // fontSize: 18.sp,
              // fontWeight: FontWeight.bold,
              // color: AppColors.primaryColor,
              // ),

              // SizedBox(height: 16.h),

              // Update Button or Success Message
              if (!isDelivered)
                ElevatedButton.icon(
                  onPressed:
                      () => showReturnHandoffDialog(
                        context,
                        pickup: pickup,
                        status:
                            status == 'picked_up'
                                ? 'delivered_to_seller'
                                : 'picked_up',
                      ),
                  icon: Icon(Icons.verified_user, size: 20.sp),
                  label: Text(AppLocalizations.of(context)!.updateStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: AppLocalizations.of(context)!.deliveredSuccessfully,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
