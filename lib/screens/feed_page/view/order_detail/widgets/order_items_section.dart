import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../model/available_orders.dart';

class OrderItemsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> itemCards;
  final VoidCallback? onCollectAll;
  final VoidCallback? onDeliverAll;
  final bool isDeliveringAll;

  const OrderItemsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
    required this.itemCards,
    this.onCollectAll,
    this.onDeliverAll,
    this.isDeliveringAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomText(
                      text: AppLocalizations.of(context)!.orderItems,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.items != null && order.items!.isNotEmpty) ...[
                    ...itemCards,
                    SizedBox(height: 16.h),
                    if (onCollectAll != null)
                      CustomButton(
                        text: AppLocalizations.of(context)!.collectAllItems,
                        onPressed: onCollectAll,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                    if (onDeliverAll != null)
                      CustomButton(
                        width: double.infinity,
                        text: 'Deliver All Items',
                        isLoading: isDeliveringAll,
                        onPressed: onDeliverAll,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                  ] else
                    CustomText(
                      text: AppLocalizations.of(context)!.noData,
                      fontSize: 18.sp,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
