import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

import '../../../../../config/app_images.dart';
import '../../../../../config/colors.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../model/return_orders_list_model.dart';
import '../store_pickup_route/services/map_service.dart';
import 'return_pickup_flow.dart';

const Color _green = Color(0xFF2E9E5B);
const Color _orange = Color(0xFFF08A00);

/// Bottom card of the return pickup map: which step the rider is on, the
/// returned items, and the one action that moves the pickup forward.
class ReturnPickupSheet extends StatelessWidget {
  final Pickups pickup;
  final ReturnPickupLeg leg;
  final bool hasArrived;
  final bool isSubmitting;
  final bool isDarkTheme;

  /// Route currently selected on the map; null until it has loaded.
  final RouteOption? route;

  /// Minutes the selected route is slower than the fastest one.
  final int extraMinutes;
  final bool hasAlternativeRoutes;

  final VoidCallback onStart;
  final VoidCallback onShowSteps;
  final VoidCallback onCall;
  final VoidCallback onReached;
  final VoidCallback onCollected;
  final VoidCallback onDelivered;

  const ReturnPickupSheet({
    super.key,
    required this.pickup,
    required this.leg,
    required this.hasArrived,
    required this.isSubmitting,
    required this.isDarkTheme,
    required this.route,
    required this.onStart,
    required this.onShowSteps,
    required this.onCall,
    required this.onReached,
    required this.onCollected,
    required this.onDelivered,
    this.extraMinutes = 0,
    this.hasAlternativeRoutes = false,
  });

  bool get _toCustomer => leg == ReturnPickupLeg.toCustomer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepHeader(leg: leg, hasArrived: hasArrived),
            if (!hasArrived && route != null) ...[
              SizedBox(height: 10.h),
              _DriveSummary(
                route: route!,
                extraMinutes: extraMinutes,
                hasAlternativeRoutes: hasAlternativeRoutes,
              ),
            ],
            SizedBox(height: 8.h),
            _AddressRow(
              icon: _toCustomer ? Icons.person_pin_circle : Icons.store,
              color: _toCustomer ? _orange : Colors.red,
              name:
                  _toCustomer
                      ? ReturnPickupFlow.customerName(pickup)
                      : ReturnPickupFlow.sellerName(pickup),
              address:
                  _toCustomer
                      ? ReturnPickupFlow.customerAddress(pickup)
                      : ReturnPickupFlow.sellerAddress(pickup),
            ),
            SizedBox(height: 8.h),
            ReturnItemsList(
              pickup: pickup,
              title: _itemsTitle(l10n),
              collected: !_toCustomer,
            ),
            SizedBox(height: 10.h),
            if (!hasArrived)
              ..._travelActions(l10n)
            else
              ..._arrivedActions(l10n),
          ],
        ),
      ),
    );
  }

  String _itemsTitle(AppLocalizations l10n) {
    if (_toCustomer) {
      return hasArrived ? l10n.collectTheseItems : l10n.returnItemsCount(1);
    }
    if (hasArrived) {
      final seller = ReturnPickupFlow.sellerName(pickup);
      return seller.isEmpty ? l10n.deliveredToSeller : l10n.handOverTo(seller);
    }
    return l10n.carryingItems(1);
  }

  // Start / Steps / Call, then "I've reached ..."
  List<Widget> _travelActions(AppLocalizations l10n) {
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      side: const BorderSide(color: AppColors.primaryColor),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
    return [
      Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              key: const ValueKey('return_start'),
              onPressed: onStart,
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: Text(
                l10n.startNavigation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: route == null ? null : onShowSteps,
              icon: const Icon(Icons.format_list_bulleted),
              label: Text(
                l10n.routeSteps,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: outlinedStyle,
            ),
          ),
          SizedBox(width: 8.w),
          Tooltip(
            message: l10n.callCustomer,
            child: OutlinedButton(
              onPressed: onCall,
              style: outlinedStyle.copyWith(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                ),
                minimumSize: const WidgetStatePropertyAll(Size.zero),
              ),
              child: const Icon(Icons.phone),
            ),
          ),
        ],
      ),
      SizedBox(height: 8.h),
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          key: const ValueKey('return_reached'),
          onPressed: onReached,
          icon: Icon(_toCustomer ? Icons.location_on : Icons.store),
          label: Text(
            _toCustomer ? l10n.iHaveReachedCustomer : l10n.iHaveReachedSeller,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ),
    ];
  }

  // Call, then the swipe that confirms collection / hand-over
  List<Widget> _arrivedActions(AppLocalizations l10n) {
    return [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone),
          label: Text(
            l10n.callCustomer,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor),
            padding: EdgeInsets.symmetric(vertical: 11.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ),
      SizedBox(height: 10.h),
      _ConfirmSwipe(
        key: ValueKey('return_swipe_${leg.name}'),
        text:
            _toCustomer
                ? l10n.swipePackageCollected
                : l10n.swipeDeliveredToSeller,
        isLoading: isSubmitting,
        onSwipe: _toCustomer ? onCollected : onDelivered,
      ),
    ];
  }
}

class _StepHeader extends StatelessWidget {
  final ReturnPickupLeg leg;
  final bool hasArrived;

  const _StepHeader({required this.leg, required this.hasArrived});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toCustomer = leg == ReturnPickupLeg.toCustomer;
    final label =
        hasArrived
            ? (toCustomer ? l10n.arrivedAtCustomer : l10n.arrivedAtSeller)
            : (toCustomer ? l10n.returnStepPickup : l10n.returnStepToSeller);
    final color =
        hasArrived ? _green : (toCustomer ? _orange : AppColors.primaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasArrived) ...[
                Icon(Icons.check_circle, color: color, size: 14.sp),
                SizedBox(width: 4.w),
              ],
              Flexible(
                child: CustomText(
                  text: label.toUpperCase(),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _segment(toCustomer ? AppColors.primaryColor : _green),
            SizedBox(width: 4.w),
            _segment(
              toCustomer ? Colors.grey.shade300 : AppColors.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _segment(Color color) => Expanded(
    child: Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.r),
      ),
    ),
  );
}

// "12 min (3.4 km)" with "Fastest route" / "+2 min slower" below
class _DriveSummary extends StatelessWidget {
  final RouteOption route;
  final int extraMinutes;
  final bool hasAlternativeRoutes;

  const _DriveSummary({
    required this.route,
    required this.extraMinutes,
    required this.hasAlternativeRoutes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFastest = extraMinutes <= 0;
    final subtitle =
        isFastest ? l10n.fastestRoute : l10n.routeMinutesSlower(extraMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.directions_car,
              color: AppColors.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: CustomText(
                text:
                    '${l10n.routeMinutes(route.durationMinutes)} (${route.distanceKm.toStringAsFixed(1)} ${l10n.km})',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        CustomText(
          text:
              hasAlternativeRoutes
                  ? '$subtitle · ${l10n.tapRouteToSwitch}'
                  : subtitle,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isFastest ? Colors.green[700] : Colors.grey[600],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty && address.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                CustomText(
                  text: name,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (address.isNotEmpty)
                CustomText(
                  text: address,
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The returned product(s), shown on every step so the rider knows what to
/// collect and hand over.
class ReturnItemsList extends StatelessWidget {
  final Pickups pickup;
  final String title;

  /// Show a tick on each item once it has been picked up.
  final bool collected;

  const ReturnItemsList({
    super.key,
    required this.pickup,
    required this.title,
    this.collected = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemTitle = ReturnPickupFlow.itemTitle(pickup);
    final reason = pickup.reason ?? '';
    final images = pickup.images ?? const <String>[];
    final outline = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(10.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryColor,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: CustomText(
                    text: title,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.blue,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: itemTitle.isEmpty ? l10n.unknownItem : itemTitle,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reason.isNotEmpty)
                        CustomText(
                          text: '${l10n.reason}: $reason',
                          fontSize: 11.5.sp,
                          color: Colors.grey[600],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (collected)
                  Icon(Icons.check_circle, color: _green, size: 20.sp),
              ],
            ),
          ),
          // Photos the customer attached to the return, to match the package
          if (images.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
              child: SizedBox(
                height: 44.w,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6.w),
                  itemBuilder:
                      (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: Image.network(
                          images[i],
                          width: 44.w,
                          height: 44.w,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 44.w,
                                height: 44.w,
                                color: outline,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 18.sp,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfirmSwipe extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onSwipe;

  const _ConfirmSwipe({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeButton(
      enabled: !isLoading,
      thumbPadding: EdgeInsets.all(4.w),
      borderRadius: BorderRadius.circular(22.r),
      inactiveThumbColor: Colors.white,
      activeThumbColor: Colors.white,
      activeTrackColor: _green,
      inactiveTrackColor: _green.withValues(alpha: 0.6),
      height: 45.h,
      thumb: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17.r),
          border: Border.all(color: _green, width: 1.w),
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _green,
                    ),
                  )
                  : Image.asset(
                    AppImages.arrowRight,
                    width: 25.w,
                    height: 25.h,
                  ),
        ),
      ),
      onSwipe: onSwipe,
      child: CustomText(
        text: text,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Shown once the package has been handed over to the seller.
class ReturnCompletedCard extends StatelessWidget {
  final Pickups pickup;
  final bool isDarkTheme;
  final VoidCallback onBack;

  const ReturnCompletedCard({
    super.key,
    required this.pickup,
    required this.isDarkTheme,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: _green, size: 44.sp),
          ),
          SizedBox(height: 12.h),
          CustomText(
            text: l10n.returnCompleted,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 4.h),
          CustomText(
            text: l10n.returnDeliveredSummary('${pickup.id ?? ''}'),
            fontSize: 13.sp,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('return_back_to_orders'),
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                l10n.backToOrders,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
