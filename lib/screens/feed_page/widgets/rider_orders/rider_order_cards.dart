import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/services/phone_service.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../system_settings/bloc/system_settings_bloc.dart';
import '../../bloc/accept_order_bloc/accept_order_bloc.dart';
import '../../bloc/accept_order_bloc/accept_order_event.dart';
import '../../bloc/accept_order_bloc/accept_order_state.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../model/available_orders.dart';
import '../available_orders/available_order_card.dart';

/// Colours used by the rider order screens.
class RiderUiColors {
  static const Color green = Color(0xFF22A447);
  static const Color red = Color(0xFFD10000);
  static const Color price = Color(0xFFF5A000);
  static const Color headerBand = Color(0xFFDCE5F8);
  static const Color greyPill = Color(0xFFEDEDED);

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBorderColor
          : const Color(0xFFE3E3E3);

  static Color band(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryColor.withValues(alpha: 0.25)
          : headerBand;

  static Color pill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCardColor
          : greyPill;

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
}

/// Orders the rider declined in this session. There is no decline API, so a
/// declined order is only hidden from this rider's lists until the app restarts.
class DeclinedOrders {
  static final ValueNotifier<Set<int>> ids = ValueNotifier<Set<int>>({});

  static void add(int id) => ids.value = {...ids.value, id};
}

/// Rounded segmented control: blue outline, selected segment filled blue.
class RiderPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const RiderPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.sameColorChange,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppColors.primaryColor, width: 1.2),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(26.r),
                ),
                child: CustomText(
                  text: labels[index],
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color:
                      isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Small map thumbnail with a pin and "Here" label.
class HereMapTile extends StatelessWidget {
  final VoidCallback? onTap;

  const HereMapTile({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66.w,
        height: 54.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: RiderUiColors.cardBorder(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapGrid())),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                  CustomText(
                    text: AppLocalizations.of(context)!.here,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
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

class _MapGrid extends CustomPainter {
  const _MapGrid();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 6.0;
    final light = Paint()..color = const Color(0xFFF4F4F4);
    final dark = Paint()..color = const Color(0xFFE6E6E6);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final even = ((x ~/ cell) + (y ~/ cell)) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), even ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Outer card frame shared by every order card.
class _RiderCardFrame extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _RiderCardFrame({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.sameColorChange,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: RiderUiColors.cardBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Light-blue band at the top of each card.
class _HeaderBand extends StatelessWidget {
  final Widget child;

  const _HeaderBand({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: RiderUiColors.band(context),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  const _RoundButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.loading = false,
    this.height = 40,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: height.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child:
            loading
                ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
                : CustomText(
                  text: label,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: foreground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
      ),
    );
  }
}

String _orderNumber(Orders order) => '${order.id ?? '-'}';

String _formatTime(String? raw) {
  final parsed = raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
  if (parsed == null) return '00:00 am';
  return DateFormat('hh:mm a').format(parsed.toLocal()).toLowerCase();
}

String _travelMinutes(Orders order) {
  final distance = order.deliveryRoute?.totalDistance ?? 0;
  final minutes = distance * 2;
  return minutes == minutes.roundToDouble()
      ? minutes.toInt().toString()
      : minutes.toStringAsFixed(1);
}

String _paymentLabel(Orders order) {
  final method = order.paymentMethod ?? '';
  return method.isEmpty ? '-' : method.toUpperCase();
}

String _customerAddress(Orders order) {
  return [
    order.shippingAddress1,
    order.shippingAddress2,
    order.shippingCity,
    order.shippingState,
  ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
}

void _openOrderDetails(BuildContext context, Orders order) {
  if (order.id == null) return;
  context.push(
    AppRoutes.orderDetails,
    extra: {'orderId': order.id!, 'from': false, 'sourceTab': 1},
  );
}

Future<void> _openCustomerLocation(BuildContext context, Orders order) async {
  final lat = order.shippingLatitude ?? '';
  final lng = order.shippingLongitude ?? '';
  if (lat.isEmpty || lng.isEmpty) {
    ToastManager.show(
      context: context,
      message: AppLocalizations.of(context)!.routeDetailsNotAvailableForMapView,
      type: ToastType.error,
    );
    return;
  }
  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> _callSupport(BuildContext context) async {
  final number =
      context
          .read<SystemSettingsBloc>()
          .currentSettings
          ?.systemSettings
          ?.value
          ?.sellerSupportNumber ??
      '';
  if (number.trim().isEmpty) {
    ToastManager.show(
      context: context,
      message: AppLocalizations.of(context)!.supportNumberUnavailable,
      type: ToastType.error,
    );
    return;
  }
  try {
    await PhoneService.makePhoneCall(number);
  } catch (_) {
    if (!context.mounted) return;
    ToastManager.show(
      context: context,
      message: AppLocalizations.of(context)!.supportNumberUnavailable,
      type: ToastType.error,
    );
  }
}

/// Round avatar with an icon/letter, used for store and customer.
class _CircleBadge extends StatelessWidget {
  final Widget child;

  const _CircleBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _ClockLine extends StatelessWidget {
  final String text;

  const _ClockLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 12.sp, color: AppColors.primaryColor),
        SizedBox(width: 3.w),
        CustomText(text: text, fontSize: 11, color: AppColors.primaryColor),
      ],
    );
  }
}

/// Available order: price + distance, pickup store, Accept / Decline.
class UpcomingOrderCard extends StatelessWidget {
  final Orders order;

  const UpcomingOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AcceptOrderBloc(),
      child: _UpcomingOrderCardContent(order: order),
    );
  }
}

class _UpcomingOrderCardContent extends StatelessWidget {
  final Orders order;

  const _UpcomingOrderCardContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store =
        order.deliveryRoute?.routeDetails?.isNotEmpty == true
            ? order.deliveryRoute!.routeDetails!.first
            : null;
    final storeName =
        (store?.storeName ?? '').isNotEmpty ? store!.storeName! : l10n.store;
    final storeAddress = [
      store?.address,
      store?.city,
      store?.state,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
    final distance = order.deliveryRoute?.totalDistance ?? 0;
    final price =
        (order.finalTotal ?? '').isNotEmpty
            ? order.finalTotal
            : order.totalPayable;

    return _RiderCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderBand(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: l10n.productPrice,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 2.h),
                      CustomText(
                        text: CurrencyFormatter.formatAmount(context, price),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: RiderUiColors.price,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.sameColorChange,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: CustomText(
                    text: l10n.distanceKm(distance.toStringAsFixed(1)),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 3.w),
              CustomText(
                text: l10n.pickupFrom,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              const Spacer(),
              Container(
                width: 18.w,
                height: 18.w,
                decoration: const BoxDecoration(
                  color: RiderUiColors.price,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront, size: 11.sp, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CircleBadge(
                child: CustomText(
                  text: storeName.substring(0, 1).toLowerCase(),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: storeName,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (storeAddress.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      CustomText(
                        text: storeAddress,
                        fontSize: 11,
                        color: RiderUiColors.muted(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 4.h),
                    _ClockLine(text: l10n.minsAway(_travelMinutes(order))),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              HereMapTile(onTap: () => showOrderRouteOnMap(context, order)),
            ],
          ),
          SizedBox(height: 12.h),
          BlocConsumer<AcceptOrderBloc, AcceptOrderState>(
            listener: (context, state) {
              if (state is AcceptOrderSuccess) {
                afterOrderAccepted(context, order);
              } else if (state is AcceptOrderCompleted) {
                context.read<AvailableOrdersBloc>().add(
                  AllAvailableOrdersList(forceRefresh: true),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AcceptOrderLoading;
              return Row(
                children: [
                  Expanded(
                    child: _RoundButton(
                      label: isLoading ? l10n.accepting : l10n.acceptOrder,
                      background: RiderUiColors.green,
                      foreground: Colors.white,
                      loading: isLoading,
                      onTap: () {
                        if (order.id == null) return;
                        context.read<AcceptOrderBloc>().add(
                          AcceptOrder(order.id!),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _RoundButton(
                      label: l10n.declineOrder,
                      background: RiderUiColors.red,
                      foreground: Colors.white,
                      onTap:
                          isLoading || order.id == null
                              ? null
                              : () {
                                DeclinedOrders.add(order.id!);
                                ToastManager.show(
                                  context: context,
                                  message: l10n.orderDeclinedHidden,
                                  type: ToastType.info,
                                );
                              },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header band with order number on the left and a status badge on the right.
class _OrderStatusHeader extends StatelessWidget {
  final Orders order;
  final bool delivered;

  const _OrderStatusHeader({required this.order, required this.delivered});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _HeaderBand(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: l10n.orderNo,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: _orderNumber(order),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: delivered ? RiderUiColors.green : RiderUiColors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              delivered ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 6.w),
          CustomText(
            text: delivered ? l10n.orderDeliveredLabel : l10n.orderCancelLabel,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final Orders order;

  const _CustomerRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final address = _customerAddress(order);
    return Row(
      children: [
        _CircleBadge(
          child: Icon(Icons.person, color: Colors.white, size: 20.sp),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text:
                    (order.shippingName ?? '').isNotEmpty
                        ? order.shippingName!
                        : l10n.customer,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (address.isNotEmpty) ...[
                SizedBox(height: 2.h),
                CustomText(
                  text: '${l10n.address}: $address',
                  fontSize: 11,
                  color: RiderUiColors.muted(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 4.h),
              _ClockLine(text: l10n.minsShort(_travelMinutes(order))),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        HereMapTile(onTap: () => _openCustomerLocation(context, order)),
      ],
    );
  }
}

class _OrderActionsRow extends StatelessWidget {
  final Orders order;

  const _OrderActionsRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pill = RiderUiColors.pill(context);
    return Row(
      children: [
        Expanded(
          child: _RoundButton(
            label: l10n.rateCustomer,
            background: pill,
            foreground: onSurface,
            height: 30,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            onTap:
                () => ToastManager.show(
                  context: context,
                  message: l10n.rateCustomerComingSoon,
                  type: ToastType.info,
                ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _RoundButton(
            label: l10n.support,
            background: pill,
            foreground: onSurface,
            height: 30,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            onTap: () => _callSupport(context),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _RoundButton(
            label: l10n.viewDetails,
            background: pill,
            foreground: AppColors.primaryColor,
            height: 30,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            onTap: () => _openOrderDetails(context, order),
          ),
        ),
      ],
    );
  }
}

class _TimeText extends StatelessWidget {
  final Orders order;

  const _TimeText({required this.order});

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: AppLocalizations.of(
        context,
      )!.deliveredTimeLabel(_formatTime(order.updatedAt)),
      fontSize: 10,
      color: RiderUiColors.muted(context),
    );
  }
}

/// Completed order card.
class DeliveredOrderCard extends StatelessWidget {
  final Orders order;

  const DeliveredOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _RiderCardFrame(
      onTap: () => _openOrderDetails(context, order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderStatusHeader(order: order, delivered: true),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 15.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 4.w),
              CustomText(
                text: l10n.paymentModeLabel,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 3.w),
              CustomText(
                text: _paymentLabel(order),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              const Spacer(),
              _TimeText(order: order),
            ],
          ),
          SizedBox(height: 10.h),
          _CustomerRow(order: order),
          SizedBox(height: 12.h),
          _OrderActionsRow(order: order),
        ],
      ),
    );
  }
}

/// Cancelled order card.
class CancelledOrderCard extends StatelessWidget {
  final Orders order;

  const CancelledOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelledBy =
        (order.cancelledBy ?? '').isNotEmpty
            ? _capitalize(order.cancelledBy!)
            : l10n.customer;
    final reason = order.cancelReason ?? '';

    return _RiderCardFrame(
      onTap: () => _openOrderDetails(context, order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderStatusHeader(order: order, delivered: false),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.block, size: 15.sp, color: RiderUiColors.red),
              SizedBox(width: 4.w),
              CustomText(
                text: l10n.cancelByLabel,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: RiderUiColors.red,
              ),
              SizedBox(width: 3.w),
              CustomText(
                text: cancelledBy,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              const Spacer(),
              _TimeText(order: order),
            ],
          ),
          SizedBox(height: 10.h),
          _CustomerRow(order: order),
          if (reason.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: RiderUiColors.pill(context),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.whyLabel} ',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: reason,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 12.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          _OrderActionsRow(order: order),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
