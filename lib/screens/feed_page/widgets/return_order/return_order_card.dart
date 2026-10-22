import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/config/app_images.dart';
import 'package:nagpur_rider/config/colors.dart';

import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/utils/widgets/custom_card.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import 'package:nagpur_rider/utils/widgets/loading_widget.dart';
import 'package:nagpur_rider/utils/widgets/toast_message.dart';
import 'package:nagpur_rider/utils/currency_formatter.dart';
import '../../bloc/return_order/accept_return_order_bloc/return_order_bloc.dart';
import '../../bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import '../../model/return_orders_list_model.dart';

class ReturnOrderCard extends StatelessWidget {
  final Pickups pickup;

  const ReturnOrderCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnOrderBloc(),
      child: _ReturnOrderCardContent(pickup: pickup),
    );
  }
}

class _ReturnOrderCardContent extends StatelessWidget {
  final Pickups pickup;

  const _ReturnOrderCardContent({required this.pickup});

  @override
  Widget build(BuildContext context) {
    final store = pickup.store;
    final product = pickup.orderItem?.product;

    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with earnings and status - Matching available order style
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // // Expected earning - Same style as available order
                  // Column(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    // children: [
                      // CustomText(
                        // text: AppLocalizations.of(context)!.earnings,
                        // fontSize: 11.sp,
                        // fontWeight: FontWeight.w500,
                        // color: Theme.of(
                          // context,
                        // ).colorScheme.onSurface.withValues(alpha: 0.7),
                      // ),
                      // SizedBox(height: 2.h),
                      // CustomText(
                        // text: CurrencyFormatter.formatAmount(
                          // context,
                          // pickup.earnings?.total ?? '0',
                        // ),
                        // fontSize: 18.sp,
                        // fontWeight: FontWeight.bold,
                        // color: AppColors.secondaryColor,
                      // ),
                    // ],
                  // ),
                  const SizedBox.shrink(),
                  // Status badge - Compact style
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(
                          text:
                              AppLocalizations.of(
                                context,
                              )!.pending.toUpperCase(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 1.h),
                        CustomText(
                          text: 'Return #${pickup.id}',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pickup section - Matching available order layout
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PICKUP FROM header
                  Row(
                    children: [
                      Icon(
                        Icons.keyboard_return_rounded,
                        size: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: AppLocalizations.of(context)!.pickupFrom,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Store info row - Same structure as available order
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store logo - Same size and style
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 4.r,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomText(
                            text: _getStoreInitials(store?.name ?? 'Store'),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Store details - Same layout
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store name
                            CustomText(
                              text: store?.name ?? 'Unknown Store',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(height: 2.h),

                            // Store address
                            if (store?.address != null)
                              CustomText(
                                text: store!.address!,
                                fontSize: 11.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 4.h),

                            // Product info with icon - Similar to time estimate
                            if (product?.name != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 10.sp,
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: CustomText(
                                      text: product!.name!,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Accept button section - EXACTLY matching available order swiper
            SizedBox(
              width: double.infinity,
              height: 45.h,
              child: BlocConsumer<ReturnOrderBloc, ReturnOrderState>(
                listener: (context, state) {
                  if (state is AcceptReturnOrderSuccess) {
                    ToastManager.show(
                      context: context,
                      message: state.message,
                      type: ToastType.success,
                    );
                    // Refresh list after accept
                    context.read<ReturnOrderListBloc>().add(
                      FetchReturnOrders(forceRefresh: true),
                    );
                  } else if (state is ReturnOrderError) {
                    ToastManager.show(
                      context: context,
                      message: state.errorMessage,
                      type: ToastType.error,
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is ReturnOrderLoading;

                  return SwipeButton(
                    thumbPadding: EdgeInsets.all(4.w),
                    borderRadius: BorderRadius.circular(22.r),
                    inactiveThumbColor: Colors.white,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Color(0xFF3CB371),
                    inactiveTrackColor: Color(0xFF3CB371),
                    width: double.infinity,
                    height: 45.h,
                    thumb: Container(
                      width: 40.w,
                      height: 35.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17.r),
                        border: Border.all(
                          color: Color(0xFF3CB371),
                          width: 1.w,
                        ),
                      ),
                      child: Center(
                        child:
                            isLoading
                                ? LoadingWidget(size: 25.w)
                                : Image.asset(
                                  AppImages.arrowRight,
                                  width: 25.w,
                                  height: 25.h,
                                ),
                      ),
                    ),
                    onSwipe: () async {
                      if (!isLoading) {
                        context.read<ReturnOrderBloc>().add(
                          AcceptReturnOrder(returnId: pickup.id.toString()),
                        );
                      }
                    },
                    child: CustomText(
                      text:
                          isLoading
                              ? AppLocalizations.of(context)!.accepting
                              : 'Swipe to Accept Return',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStoreInitials(String storeName) {
    if (storeName.isEmpty || storeName == 'Store') return 'S';

    final words = storeName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }
}
