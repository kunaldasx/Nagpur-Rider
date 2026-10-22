import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/utils/widgets/custom_card.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../model/available_orders.dart';
import '../../../../utils/currency_formatter.dart';
import '../../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../../bloc/items_collected_bloc/items_collected_state.dart';
import '../../../../l10n/app_localizations.dart';

class ItemCard extends StatelessWidget {
  final Items item;
  final String? orderStatus;
  final bool from;
  final bool isCollected;
  final bool isDelivered;
  final bool isLoading;
  final bool isOtpVerified;
  final VoidCallback? onCollect;
  final VoidCallback? onDelivered;
  final VoidCallback? onTap;
  final VoidCallback? onReachedDestination;

  /// When several items are pending delivery, the order page shows a single
  /// "Deliver All" button instead of one button per item.
  final bool hideDeliverButton;

  const ItemCard({
    super.key,
    required this.item,
    required this.orderStatus,
    required this.from,
    required this.isCollected,
    required this.isDelivered,
    required this.isLoading,
    this.isOtpVerified = false,
    this.onCollect,
    this.onDelivered,
    this.onTap,
    this.onReachedDestination,
    this.hideDeliverButton = false,
  });

  Widget _buildDeliverAction(BuildContext context, bool shouldOpenOtpDialog) {
    if (hideDeliverButton) {
      return Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 24.sp),
          SizedBox(height: 4.h),
          CustomText(
            text: 'Ready',
            fontSize: 12.sp,
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ],
      );
    }
    return CustomButton(
      width: 100.w,
      height: 40.h,
      textSize: 15.sp,
      text: AppLocalizations.of(context)!.deliver,
      onPressed: () {
        // If OTP dialog should open, call onTap (which opens OTP dialog), otherwise call onDelivered
        if (shouldOpenOtpDialog) {
          onTap?.call();
        } else {
          onDelivered?.call();
        }
      },
      backgroundColor: AppColors.primaryColor,
      textColor: Colors.white,
      borderRadius: 8.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if item requires OTP
    final bool requiresOtp = item.product?.requiresOtp == 1;
    // Check if OTP dialog should open when delivered button is clicked
    final bool shouldOpenOtpDialog =
        orderStatus?.toLowerCase() == 'out_for_delivery' &&
        item.status?.toLowerCase() == 'collected' &&
        requiresOtp &&
        item.otpVerified == 0 &&
        !isOtpVerified;

    return BlocBuilder<ItemsCollectedBloc, ItemsCollectedState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: CustomCard(
            padding: EdgeInsets.all(16.w),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        image: DecorationImage(
                          image: NetworkImage(item.product?.image ?? ''),
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child:
                          item.product?.image == null
                              ? Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Colors.blue,
                                  size: 20.sp,
                                ),
                              )
                              : const SizedBox(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text:
                                      item.title ??
                                      AppLocalizations.of(context)!.unknownItem,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text:
                              '${AppLocalizations.of(context)!.quantity}: ${item.quantity ?? 1}',
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: CurrencyFormatter.formatAmount(
                            context,
                            item.price ?? '0',
                          ),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryColor,
                        ),
                      ],
                    ),

                    // Loading state
                    if (isLoading)
                      SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      )
                    // Collection mode logic
                    else if (isDelivered) ...[
                      // Show tick mark and "Delivered" text when item is delivered
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24.sp,
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.delivered,
                            fontSize: 12.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (isCollected &&
                        !isDelivered &&
                        item.reachedDestination == false) ...[
                      // Show tick mark and "Collected" text when item is collected but not delivered
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 24.sp,
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.collected,
                            fontSize: 12.sp,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (isDelivered &&
                        item.reachedDestination == true) ...[
                      // Show tick mark and "Delivered" text when item is delivered and has reached destination
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24.sp,
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text: AppLocalizations.of(context)!.delivered,
                            fontSize: 12.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (item.reachedDestination == true &&
                        isCollected &&
                        !isDelivered) ...[
                      // Show "Deliver" button when item has reached destination (highest priority)
                      _buildDeliverAction(context, shouldOpenOtpDialog),
                    ] else if (orderStatus?.toLowerCase() ==
                            'out_for_delivery' &&
                        item.status?.toLowerCase() == 'collected' &&
                        !isOtpVerified) ...[
                      // Show "Deliver" button when order status is "out_for_delivery" and item status is "collected"
                      _buildDeliverAction(context, shouldOpenOtpDialog),
                    ] else if (isCollected) ...[
                      // Show tick mark and "Collected" text when item is collected (for collection mode or assigned orders)
                      // BUT if order status is "out_for_delivery", show "Deliver" button instead
                      if (orderStatus?.toLowerCase() == 'out_for_delivery' ||
                          item.reachedDestination == true) ...[
                        // Show "Deliver" button when reached destination and item is collected
                        _buildDeliverAction(context, shouldOpenOtpDialog),
                      ] else ...[
                        // Show "Collected" tickmark when item is collected but has not reached destination and not out for delivery
                        Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 24.sp,
                            ),
                            SizedBox(height: 4.h),
                            CustomText(
                              text: AppLocalizations.of(context)!.collected,
                              fontSize: 12.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      // Show "Collect" button when item is not collected
                      // Check if order status is "assigned" to show collect button
                      if (orderStatus?.toLowerCase() == 'assigned') ...[
                        if (isCollected) ...[
                          // Show tick mark and "Collected" text when item is collected
                          // BUT if order status is "out_for_delivery", show "Deliver" button instead
                          if (orderStatus?.toLowerCase() ==
                                  'out_for_delivery' ||
                              item.reachedDestination == true) ...[
                            // Show "Deliver" button when reached destination and item is collected
                            _buildDeliverAction(context, shouldOpenOtpDialog),
                          ] else ...[
                            // Show tick mark and "Collected" text for other cases
                            Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24.sp,
                                ),
                                SizedBox(height: 4.h),
                                CustomText(
                                  text: 'Collected',
                                  fontSize: 12.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          // Show "Collect" button when item is not collected
                          CustomButton(
                            width: 100.w,
                            height: 40.h,
                            textSize: 15.sp,
                            text: AppLocalizations.of(context)!.collect,
                            onPressed:
                                (item.status?.toLowerCase() == 'preparing' ||
                                        item.status?.toLowerCase() == 'ready' ||
                                        orderStatus?.toLowerCase() ==
                                            'assigned')
                                    ? () {
                                      if (orderStatus?.toLowerCase() ==
                                          'assigned') {
                                        onCollect?.call();
                                      } else if (from) {
                                        onDelivered?.call();
                                      } else {
                                        onCollect?.call();
                                      }
                                    }
                                    : null,
                            backgroundColor:
                                (item.status?.toLowerCase() == 'preparing' ||
                                        item.status?.toLowerCase() == 'ready' ||
                                        orderStatus?.toLowerCase() ==
                                            'assigned')
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                            textColor: Colors.white,
                            borderRadius: 8.r,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            textStyle: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
