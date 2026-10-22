// screens/feed_page/pickup_order_details/pickup_order_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/pickup_order_details_bloc/pickup_order_details_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';
import 'package:nagpur_rider/screens/feed_page/view/pickup_order/widgets/return_earnings_details_section.dart';
import 'package:nagpur_rider/screens/feed_page/view/pickup_order/widgets/return_order_items_section.dart';
import 'package:nagpur_rider/screens/feed_page/view/pickup_order/widgets/return_reason_section.dart';
import 'package:nagpur_rider/screens/feed_page/view/pickup_order/widgets/return_store_details_section.dart';

import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../../router/app_routes.dart';

class PickupOrderDetailsPage extends StatefulWidget {
  final String returnId;

  const PickupOrderDetailsPage({super.key, required this.returnId});

  @override
  State<PickupOrderDetailsPage> createState() => _PickupOrderDetailsPageState();
}

class _PickupOrderDetailsPageState extends State<PickupOrderDetailsPage> {
  bool _isStoreExpanded = false;
  bool _isEarningsExpanded = false;
  bool _isProductExpanded = true;
  bool _isReturnDetailsExpanded = false;

  void _showStatusUpdateSheet(Pickups pickup) {
    final currentStatus = pickup.pickupStatus ?? 'pending';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<UpdateReturnOrderStatusBloc>(),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.updateStatus,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (currentStatus != 'picked_up' &&
                      currentStatus != 'delivered_to_seller')
                    _buildStatusOption(
                      ctx,
                      AppLocalizations.of(context)!.pickup,
                      'picked_up',
                      Icons.local_shipping,
                      Colors.blue,
                    ),
                  if (currentStatus == 'picked_up')
                    _buildStatusOption(
                      ctx,
                      AppLocalizations.of(context)!.deliveredToSeller,
                      'delivered_to_seller',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          context.read<UpdateReturnOrderStatusBloc>().add(
            UpdateReturnOrderStatus(returnId: widget.returnId, status: status),
          );
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              PickupOrderDetailsBloc()
                ..add(FetchPickupOrderDetails(widget.returnId)),
      child: BlocBuilder<PickupOrderDetailsBloc, PickupOrderDetailsState>(
        builder: (context, blocState) {
          return CustomScaffold(
            appBar: CustomAppBarWithoutNavbar(
              title: AppLocalizations.of(context)!.pickupDetails,
            ),
            body: BlocConsumer<PickupOrderDetailsBloc, PickupOrderDetailsState>(
              listener: (context, state) {
                if (state is PickupOrderDetailsError) {
                  ToastManager.show(
                    context: context,
                    message: state.message,
                    type: ToastType.error,
                  );
                }
              },
              builder: (context, state) {
                if (state is PickupOrderDetailsLoading) {
                  return const Center(child: LoadingWidget());
                }

                if (state is PickupOrderDetailsSuccess) {
                  final pickup = state.pickup;
                  final currentStatus = pickup.pickupStatus ?? 'pending';
                  final isDelivered = currentStatus == 'delivered_to_seller';

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        // Status Banner
                        Container(
                          padding: EdgeInsets.all(16.h),
                          decoration: BoxDecoration(
                            color: (isDelivered ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color:
                                    isDelivered ? Colors.green : Colors.orange,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  "${AppLocalizations.of(context)!.status}: ${currentStatus.replaceAll('_', ' ').toUpperCase()}",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDelivered
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Product Details (as Order Items)
                        ReturnOrderItemsSection(
                          pickup: pickup,
                          isExpanded: _isProductExpanded,
                          onToggle:
                              () => setState(
                                () => _isProductExpanded = !_isProductExpanded,
                              ),
                        ),

                        SizedBox(height: 12.h),

                        ReturnReasonSection(
                          pickup: pickup,
                          isExpanded: _isReturnDetailsExpanded,
                          onToggle:
                              () => setState(
                                () =>
                                    _isReturnDetailsExpanded =
                                        !_isReturnDetailsExpanded,
                              ),
                        ),

                        SizedBox(height: 12.h),

                        // Store Details
                        ReturnStoreDetailsSection(
                          pickup: pickup,
                          isExpanded: _isStoreExpanded,
                          onToggle:
                              () => setState(
                                () => _isStoreExpanded = !_isStoreExpanded,
                              ),
                        ),
                        SizedBox(height: 12.h),

                        // // Earnings
                        // ReturnEarningsDetailsSection(
                          // pickup: pickup,
                          // isExpanded: _isEarningsExpanded,
                          // onToggle:
                              // () => setState(
                                // () =>
                                    // _isEarningsExpanded = !_isEarningsExpanded,
                              // ),
                        // ),

                        SizedBox(height: 20.h),

                        // Location button - Show based on status
                        if (currentStatus == 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  AppRoutes.pickupOrderMap,
                                  extra: {
                                    'pickup': pickup,
                                    'locationType': 'customer',
                                  },
                                );
                              },
                              icon: const Icon(Icons.location_on),
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.goToCustomerLocation,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50.h),
                              ),
                            ),
                          ),
                        if (currentStatus == 'picked_up')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  AppRoutes.pickupOrderMap,
                                  extra: {
                                    'pickup': pickup,
                                    'locationType': 'seller',
                                  },
                                );
                              },
                              icon: const Icon(Icons.location_on),
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.goToSellerLocation,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50.h),
                              ),
                            ),
                          ),

                        SizedBox(height: 12.h),

                        // Update Status Button
                        if (!isDelivered)
                          BlocConsumer<
                            UpdateReturnOrderStatusBloc,
                            UpdateReturnOrderStatusState
                          >(
                            listener: (context, statusState) {
                              if (statusState
                                  is UpdateReturnOrderStatusSuccess) {
                                ToastManager.show(
                                  context: context,
                                  message: statusState.message,
                                  type: ToastType.success,
                                );
                                context.read<PickupOrderListBloc>().add(
                                  FetchPickupOrders(forceRefresh: true),
                                );
                                context.read<PickupOrderDetailsBloc>().add(
                                  FetchPickupOrderDetails(widget.returnId),
                                );
                              } else if (statusState
                                  is UpdateReturnOrderStatusFailed) {
                                ToastManager.show(
                                  context: context,
                                  message: statusState.error,
                                  type: ToastType.error,
                                );
                              }
                            },
                            builder: (context, statusState) {
                              if (statusState
                                  is UpdateReturnOrderStatusLoading) {
                                return const CircularProgressIndicator();
                              }
                              return ElevatedButton.icon(
                                onPressed: () => _showStatusUpdateSheet(pickup),
                                icon: const Icon(Icons.update),
                                label: Text(
                                  AppLocalizations.of(context)!.updateStatus,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50.h),
                                ),
                              );
                            },
                          ),

                        if (isDelivered)
                          Container(
                            padding: EdgeInsets.all(16.h),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 10.w),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.deliveredSuccessfully,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Text(AppLocalizations.of(context)!.noDetailsFound),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
