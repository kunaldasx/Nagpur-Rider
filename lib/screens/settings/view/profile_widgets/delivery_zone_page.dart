import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:nagpur_rider/utils/widgets/custom_card.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import 'package:nagpur_rider/utils/widgets/custom_button.dart';
import 'package:nagpur_rider/utils/widgets/loading_widget.dart';
import 'package:nagpur_rider/utils/widgets/toast_message.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';
import '../../repo/profile_repo.dart';
import '../../model/profile_model.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

class DeliveryZonePage extends StatefulWidget {
  const DeliveryZonePage({super.key});

  @override
  State<DeliveryZonePage> createState() => _DeliveryZonePageState();
}

class _DeliveryZonePageState extends State<DeliveryZonePage> {
  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.deliveryZones,
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocProvider(
        create:
            (context) => ProfileBloc(ProfileRepo())..add(const LoadProfile()),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: LoadingWidget());
            }

            if (state is ProfileLoaded) {
              return _buildDeliveryZoneContent(state.profile);
            }

            if (state is ProfileError) {
              return _buildErrorState(state.message);
            }

            return const Center(child: LoadingWidget());
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryZoneContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final deliveryZone = profile.deliveryBoy?.deliveryZone;

    if (deliveryZone == null) {
      return _buildNoZoneState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Header
          _buildZoneHeader(deliveryZone, isDarkTheme),
          SizedBox(height: 24.h),

          // Zone Details
          _buildSectionTitle(AppLocalizations.of(context)!.zoneInformation),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.zoneName,
            value: deliveryZone.name ?? 'N/A',
            icon: Icons.location_on_outlined,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.zoneSlug,
            value: deliveryZone.slug ?? 'N/A',
            icon: Icons.tag_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.radius,
            value: '${deliveryZone.radiusKm?.toStringAsFixed(2) ?? 'N/A'} km',
            icon: Icons.radar_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 24.h),

          // Delivery Charges
          _buildSectionTitle(AppLocalizations.of(context)!.deliveryCharges),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.regularDeliveryCharges,
            value: '₹${deliveryZone.regularDeliveryCharges ?? 'N/A'}',
            icon: Icons.local_shipping_outlined,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.rushDeliveryCharges,
            value: '₹${deliveryZone.rushDeliveryCharges ?? 'N/A'}',
            icon: Icons.flash_on_outlined,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.freeDeliveryAmount,
            value:
                '₹${deliveryZone.freeDeliveryAmount?.toStringAsFixed(2) ?? 'N/A'}',
            icon: Icons.free_breakfast_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 24.h),

          // Delivery Times
          _buildSectionTitle(AppLocalizations.of(context)!.deliveryTimes),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.regularDeliveryTime,
            value: '${deliveryZone.deliveryTimePerKm ?? 'N/A'} min/km',
            icon: Icons.access_time_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.rushDeliveryTime,
            value: '${deliveryZone.rushDeliveryTimePerKm ?? 'N/A'} min/km',
            icon: Icons.speed_outlined,
            color: Colors.red,
          ),
          SizedBox(height: 24.h),

          // // Delivery Boy Earnings
          // _buildSectionTitle(AppLocalizations.of(context)!.yourEarnings),
          // SizedBox(height: 16.h),

          // _buildInfoCard(
            // title: AppLocalizations.of(context)!.baseFee,
            // value: '₹${deliveryZone.deliveryBoyBaseFee ?? 'N/A'}',
            // icon: Icons.account_balance_wallet_outlined,
            // color: Colors.green,
          // ),
          // SizedBox(height: 16.h),

          // _buildInfoCard(
            // title: AppLocalizations.of(context)!.perStorePickupFee,
            // value: '₹${deliveryZone.deliveryBoyPerStorePickupFee ?? 'N/A'}',
            // icon: Icons.store_outlined,
            // color: Colors.blue,
          // ),
          // SizedBox(height: 16.h),

          // _buildInfoCard(
            // title: AppLocalizations.of(context)!.distanceBasedFee,
            // value: '₹${deliveryZone.deliveryBoyDistanceBasedFee ?? 'N/A'}',
            // icon: Icons.route_outlined,
            // color: Colors.orange,
          // ),
          // SizedBox(height: 16.h),

          // _buildInfoCard(
            // title: AppLocalizations.of(context)!.perOrderIncentive,
            // value: '₹${deliveryZone.deliveryBoyPerOrderIncentive ?? 'N/A'}',
            // icon: Icons.emoji_events_outlined,
            // color: Colors.purple,
          // ),
          // SizedBox(height: 24.h),

          // Additional Information
          _buildSectionTitle(
            AppLocalizations.of(context)!.additionalInformation,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.handlingCharges,
            value:
                '₹${deliveryZone.handlingCharges?.toStringAsFixed(2) ?? 'N/A'}',
            icon: Icons.handyman_outlined,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.perStoreDropOffFee,
            value:
                '₹${deliveryZone.perStoreDropOffFee?.toStringAsFixed(2) ?? 'N/A'}',
            icon: Icons.delivery_dining_outlined,
            color: Colors.teal,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.bufferTime,
            value: '${deliveryZone.bufferTime ?? 'N/A'} minutes',
            icon: Icons.timer_outlined,
            color: Colors.indigo,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: AppLocalizations.of(context)!.rushDelivery,
            value:
                deliveryZone.rushDeliveryEnabled == true
                    ? AppLocalizations.of(context)!.enabled
                    : AppLocalizations.of(context)!.disabled,
            icon: Icons.flash_on_outlined,
            color:
                deliveryZone.rushDeliveryEnabled == true
                    ? Colors.green
                    : Colors.grey,
          ),
          SizedBox(height: 24.h),

          // Zone Status
          _buildSectionTitle(AppLocalizations.of(context)!.zoneStatus),
          SizedBox(height: 16.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: (deliveryZone.status == 'active'
                      ? Colors.green
                      : Colors.red)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: (deliveryZone.status == 'active'
                        ? Colors.green
                        : Colors.red)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  deliveryZone.status == 'active'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color:
                      deliveryZone.status == 'active'
                          ? Colors.green
                          : Colors.red,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomText(
                    text: 'Zone is ${deliveryZone.status ?? 'unknown'}',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        deliveryZone.status == 'active'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildZoneHeader(dynamic deliveryZone, bool isDarkTheme) {
    return CustomCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.location_on,
              size: 40.sp,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: deliveryZone.name ?? 'Delivery Zone',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color:
                isDarkTheme
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: (deliveryZone.status == 'active'
                      ? Colors.green
                      : Colors.red)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: CustomText(
              text: deliveryZone.status?.toUpperCase() ?? 'UNKNOWN',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: value,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoZoneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64.sp,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: 'No Delivery Zone Assigned',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text:
                'You haven\'t been assigned to any delivery zone yet. Please contact support.',
            fontSize: 14.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: 'Error Loading Profile',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: message,
            fontSize: 14.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: AppLocalizations.of(context)!.retry,
            onPressed: () {
              context.read<ProfileBloc>().add(const LoadProfile());
            },
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
