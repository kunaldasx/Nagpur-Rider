import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import '../../config/colors.dart';
import '../../router/app_routes.dart';
import '../../screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';

import '../../screens/settings/bloc/profile_bloc/profile_bloc.dart';
import '../../screens/settings/bloc/profile_bloc/profile_state.dart';
import 'custom_text.dart';
import 'toast_message.dart';

class AppHeader extends StatefulWidget {
  final bool showLogout;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.showLogout = true,
    this.onNotificationTap,
    this.onHelpTap,
    this.onProfileTap,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Toggle Switch
        BlocConsumer<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
          listener: (context, state) {
            if (state is DeliveryBoyStatusLoaded) {
              if (state.message != null) {
                ToastManager.show(
                  context: context,
                  message: state.message!,
                  type: ToastType.success,
                );
              }
            } else if (state is DeliveryBoyStatusError) {
              ToastManager.show(
                context: context,
                message: state.errorMessage,
                type: ToastType.error,
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is DeliveryBoyStatusLoading;

            // Don't return loading state here, we'll show it as overlay

            // Determine current state
            bool currentState = state.isOnline;

            return DefaultTextStyle.merge(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                child: AnimatedToggleSwitch<bool>.dual(
                  indicatorSize: const Size(28, 28),
                  current: currentState,
                  first: false,
                  second: true,
                  spacing: 85.w,
                  animationCurve: Curves.easeInOut,
                  animationDuration: const Duration(milliseconds: 600),
                  borderWidth: 6.w,
                  height: 38.h,
                  styleBuilder:
                      (value) => ToggleStyle(
                        backgroundColor:
                            value
                                ? AppColors.primaryColor
                                : AppColors.errorColor,
                        borderColor: Colors.transparent,
                        indicatorColor: Theme.of(context).colorScheme.onPrimary,
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
                    context.read<DeliveryBoyStatusBloc>().add(ToggleStatus(b));
                  },
                  iconBuilder:
                      (value) =>
                          isLoading
                              ? CupertinoActivityIndicator(
                                color: Colors.white,
                                radius: 10.sp,
                              )
                              : value
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
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                                textAlign: TextAlign.center,
                              )
                              : CustomText(
                                text: AppLocalizations.of(context)!.inactive,
                                fontSize: 14.sp,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                textAlign: TextAlign.center,
                              ),
                ),
              ),
            );
          },
        ),
        SizedBox(
          width: 100.w,
          child: Row(
            children: [
              // Expanded(
              //   child: GestureDetector(
              //     onTap: _handleLogout,
              //     child: Container(
              //       padding: const EdgeInsets.all(8),
              //       decoration: BoxDecoration(
              //         color: Colors.red.withValues(alpha:0.1),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Icon(
              //         Icons.logout,
              //         color: Colors.red,
              //         size: 20,
              //       ),
              //     ),
              //   ),
              // ),
              Expanded(
                child: IconButton(
                  color: AppColors.primaryColor,
                  onPressed: () {
                    context.push(AppRoutes.notifications);
                  },
                  icon: Icon(Icons.notifications),
                ),
              ),

              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    String profileImageUrl = "assets/png/profile.jpg";
                    if (profileState is ProfileLoaded &&
                        profileState.profile.user?.profileImage != null &&
                        profileState.profile.user!.profileImage!.isNotEmpty) {
                      profileImageUrl =
                          profileState.profile.user!.profileImage!;
                    }

                    return CircleAvatar(
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 18.sp,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                              : profileImageUrl == "assets/png/profile.jpg"
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right side icons
        // Row(
        //   children: [
        //     const SizedBox(width: 16),
        //     // Logout Icon
        //     if (widget.showLogout)
        //       GestureDetector(
        //         onTap: _handleLogout,
        //         child: Container(
        //           padding: const EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Theme.of(context).colorScheme.error.withValues(alpha:0.1),
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //           child: Icon(
        //             Icons.logout,
        //             color: Theme.of(context).colorScheme.error,
        //             size: 20,
        //           ),
        //         ),
        //       ),
        //     // Notification Icon
        //     GestureDetector(
        //       onTap: widget.onNotificationTap,
        //       child: Icon(
        //         Icons.notifications,
        //         color: AppColors.primaryColor,
        //       ),
        //     ),
        //     const SizedBox(width: 16),
        //     // Profile Icon
        //     GestureDetector(
        //       onTap: widget.onProfileTap,
        //       child: BlocBuilder<ProfileBloc, ProfileState>(
        //         builder: (context, profileState) {
        //           return CircleAvatar(
        //             radius: 16,
        //             backgroundColor: AppColors.primaryColor,
        //             child: Icon(
        //               Icons.person,
        //               size: 16,
        //               color: Theme.of(context).colorScheme.onPrimary,
        //             ),
        //           );
        //         },
        //       ),
        //     ),
        //
        //   ],
        // ),
      ],
    );
  }
}
