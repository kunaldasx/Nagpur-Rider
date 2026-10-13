import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:nagpur_rider/utils/widgets/custom_button.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../../config/theme_bloc.dart';
import '../../../settings/bloc/profile_bloc/profile_bloc.dart';
import '../../../settings/bloc/profile_bloc/profile_state.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';

import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/router/app_routes.dart';

class HomeHeaderSection extends StatelessWidget {
  final Function() handleToggle;

  const HomeHeaderSection({super.key, required this.handleToggle});

  void _showDeliveryZoneErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8.w),
              CustomText(text: AppLocalizations.of(context)!.locationIssue),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: errorMessage),
              SizedBox(height: 16.h),
              CustomText(
                text: AppLocalizations.of(context)!.toResolveThisIssue,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: AppLocalizations.of(context)!.moveToCoveredDeliveryArea,
              ),
              CustomText(
                text: AppLocalizations.of(context)!.checkDeliveryZoneInProfile,
              ),
              CustomText(
                text: AppLocalizations.of(context)!.ensureGpsEnabledAccurate,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(text: AppLocalizations.of(context)!.ok),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to delivery zone page
                context.push('/delivery-zone');
              },
              child: CustomText(
                text: AppLocalizations.of(context)!.viewDeliveryZone,
              ),
            ),
            CustomButton(
              textSize: 15.sp,
              onPressed: () {
                Navigator.of(context).pop();
                // Retry getting location
                context.read<DeliveryBoyStatusBloc>().add(ToggleStatus(true));
              },
              text: AppLocalizations.of(context)!.retry,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
          listener: (context, state) {
            if (state is DeliveryBoyStatusLoaded) {
              if (state.message != null && state.isVerified) {
                ToastManager.show(
                  context: context,
                  message: state.message!,
                  type: ToastType.success,
                );
              }
            } else if (state is DeliveryBoyStatusError) {
              // Show toast for general errors
              ToastManager.show(
                context: context,
                message: state.errorMessage,
                type: ToastType.error,
              );

              // Show detailed dialog for delivery zone errors
              if (state.errorMessage.contains('delivery zone')) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showDeliveryZoneErrorDialog(context, state.errorMessage);
                });
              }
            }
          },
          child: BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
            builder: (context, state) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedToggleSwitch<bool>.dual(
                    indicatorSize: const Size(28, 28),
                    current: state.isOnline,
                    loading: state is DeliveryBoyStatusLoading,
                    first: false,
                    second: true,
                    spacing: 85.w,
                    animationCurve: Curves.easeInOut,
                    animationDuration: const Duration(
                      milliseconds: 300,
                    ), // Reduced from 600ms for faster response
                    borderWidth: 6.w,
                    height: 38.h,
                    styleBuilder:
                        (value) => ToggleStyle(
                          backgroundColor:
                              value
                                  ? AppColors.primaryColor
                                  : AppColors.errorColor,
                          borderColor: Colors.transparent,
                          indicatorColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                    loadingIconBuilder:
                        (context, global) => CupertinoActivityIndicator(
                          color: Color.lerp(
                            AppColors.errorColor,
                            AppColors.primaryColor,
                            global.position,
                          ),
                        ),
                    onChanged: (b) {
                      handleToggle();
                    },
                    iconBuilder:
                        (value) =>
                            value
                                ? Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.primaryColor,
                                  size: 24.sp,
                                )
                                : Icon(
                                  Icons.power_settings_new_rounded,
                                  color: AppColors.errorColor,
                                  size: 24.sp,
                                ),
                    textBuilder:
                        (value) =>
                            value
                                ? CustomText(
                                  text: AppLocalizations.of(context)!.active,
                                  fontSize: 14.sp,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  textAlign: TextAlign.center,
                                )
                                : CustomText(
                                  text: AppLocalizations.of(context)!.inactive,
                                  fontSize: 14.sp,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  textAlign: TextAlign.center,
                                ),
                  ),
                  SizedBox(width: 16.w),
                  SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<
                            NotificationBloc,
                            NotificationState
                          >(
                            builder: (context, notificationState) {
                              int unreadCount = 0;

                              if (notificationState is NotificationLoaded) {
                                unreadCount = notificationState.unreadCount;
                              }

                              return Badge.count(
                                count: unreadCount,
                                isLabelVisible:
                                    unreadCount > 0, // hide badge when 0
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                textStyle: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),

                                offset: Offset(-8, 4), // fine-tune position
                                // Optional: largeSize: 18.r,           // if you want bigger badge
                                child: IconButton(
                                  color: AppColors.primaryColor,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor
                                        .withValues(alpha: 0.1),
                                  ),
                                  onPressed: () {
                                    context.push(AppRoutes.notifications);
                                  },
                                  icon: Icon(Icons.notifications),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: BlocBuilder<ProfileBloc, ProfileState>(
                            builder: (context, profileState) {
                              String profileImageUrl = "assets/png/profile.jpg";
                              if (profileState is ProfileLoaded &&
                                  profileState.profile.user?.profileImage !=
                                      null &&
                                  profileState
                                      .profile
                                      .user!
                                      .profileImage!
                                      .isNotEmpty) {
                                profileImageUrl =
                                    profileState.profile.user!.profileImage!;
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (!state.isVerified) {
                                    ToastManager.show(
                                      context: context,
                                      message:
                                          state.message ??
                                          "Your account has not been verified yet.",
                                      type: ToastType.error,
                                    );
                                    return;
                                  }
                                  context.push(AppRoutes.profile);
                                },
                                child: Opacity(
                                  opacity: state.isVerified ? 1.0 : 0.5,
                                  child: CircleAvatar(
                                    radius: 18.r,
                                    backgroundColor: AppColors.primaryColor,
                                    child:
                                        profileImageUrl.startsWith('http')
                                            ? ClipOval(
                                              child: Image.network(
                                                profileImageUrl,
                                                width: 36.r,
                                                height: 36.r,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 18.sp,
                                                    color: Colors.white,
                                                  );
                                                },
                                              ),
                                            )
                                            : profileImageUrl ==
                                                "assets/png/profile.jpg"
                                            ? Icon(
                                              Icons.person,
                                              size: 18.sp,
                                              color: Colors.white,
                                            )
                                            : Image.asset(
                                              profileImageUrl,
                                              width: 36.r,
                                              height: 36.r,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
