// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/auth/repo/auth_repo.dart';
import 'package:nagpur_rider/utils/services/session_service.dart';

import 'package:nagpur_rider/config/theme_bloc.dart';
import 'package:nagpur_rider/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:nagpur_rider/utils/widgets/custom_scaffold.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../config/colors.dart';
import '../bloc/profile_bloc/profile_bloc.dart';
import '../bloc/profile_bloc/profile_event.dart';
import '../bloc/profile_bloc/profile_state.dart';
import 'package:nagpur_rider/config/localization_service.dart';
import 'package:provider/provider.dart';
import '../../../utils/widgets/toast_message.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    // Load profile data
    try {
      context.read<ProfileBloc>().add(LoadProfile());
    } catch (e) {
      //
    }
  }

  Future<void> _initializeStatus() async {
    final status = await Global.getDeliveryBoyStatus() ?? false;
    setState(() {
      _isActive = status;
    });
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      radius: 35.r,
      child: Icon(Icons.person, size: 35.r, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      listener: (context, state) {
        if (state is DeliveryBoyStatusLoaded) {
          setState(() {
            _isActive = state.isOnline;
          });
        }
      },
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDarkTheme = themeState.currentTheme == 'dark';

          return CustomScaffold(
            appBar: CustomAppBarWithoutNavbar(
              onBackPressed: () {
                context.go('/feed');
              },
              title: AppLocalizations.of(context)!.settings,
              additionalActions: [],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      if (state is ProfileLoaded) {
                        final profile = state.profile;
                        final String profileName =
                            profile.deliveryBoy?.fullName ??
                            profile.user?.name ??
                            AppLocalizations.of(context)!.deliveryPartner;
                        final String profileEmail = profile.user?.email ?? '';
                        final String? profileImageUrl =
                            profile.user?.profileImage;

                        return CustomCard(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Row(
                            children: [
                              profileImageUrl != null &&
                                      profileImageUrl.isNotEmpty
                                  ? ClipOval(
                                    child: Image.network(
                                      profileImageUrl,
                                      width: 70.r,
                                      height: 70.r,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultAvatar(),
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return SizedBox(
                                          width: 70.r,
                                          height: 70.r,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : _buildDefaultAvatar(),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: profileName,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    if (profileEmail.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      CustomText(
                                        text: profileEmail,
                                        fontSize: 12.sp,
                                        color:
                                            isDarkTheme
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ],
                                    SizedBox(height: 8.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isActive
                                                ? Colors.green.withValues(
                                                  alpha: 0.15,
                                                )
                                                : Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: (_isActive
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6.w,
                                            height: 6.w,
                                            decoration: BoxDecoration(
                                              color:
                                                  _isActive
                                                      ? Colors.green
                                                      : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          CustomText(
                                            text:
                                                _isActive
                                                    ? AppLocalizations.of(
                                                      context,
                                                    )!.active
                                                    : AppLocalizations.of(
                                                      context,
                                                    )!.inactive,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _isActive
                                                    ? Colors.green[700]
                                                    : Colors.grey[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        );
                      } else if (state is ProfileLoading) {
                        return CustomCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35.r,
                                backgroundColor: Colors.grey[200],
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120.w,
                                    height: 16.h,
                                    color: Colors.grey[200],
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    width: 80.w,
                                    height: 12.h,
                                    color: Colors.grey[200],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Account Settings Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.accountSettings,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.person,
                        title: AppLocalizations.of(context)!.myOrders,
                        subtitle: 'View and manage your delivery orders',
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.myOrders),
                        showDivider: false,
                      ),
                      _buildSettingsOption(
                        icon: Icons.money,
                        title: AppLocalizations.of(context)!.cashCollected,
                        subtitle:
                            AppLocalizations.of(
                              context,
                            )!.manageProfileInformation,
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.allCashCollection),
                        showDivider: false,
                      ),
                      _buildSettingsOption(
                        icon: Icons.star,
                        title: AppLocalizations.of(context)!.feedback,
                        subtitle:
                            AppLocalizations.of(
                              context,
                            )!.manageProfileInformation,
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.ratings),
                        showDivider: false,
                      ),
                    ],
                  ),

                  // App Settings Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.appSettings,
                    children: [
                      // _buildSettingsOption(
                      //   icon: Icons.notifications,
                      //   title: AppLocalizations.of(context)!.notifications,
                      //   subtitle:
                      //       AppLocalizations.of(
                      //         context,
                      //       )!.manageNotificationPreferences,
                      //   isDarkTheme: isDarkTheme,
                      //   onTap: () => context.push(AppRoutes.notifications),
                      // ),
                      _buildSettingsOption(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        subtitle:
                            AppLocalizations.of(context)!.changeAppLanguage,
                        isDarkTheme: isDarkTheme,
                        onTap:
                            () => _showLanguageSelectionDialog(
                              context,
                              isDarkTheme,
                            ),
                      ),
                      _buildSettingsOptionWithSwitch(
                        icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                        title: AppLocalizations.of(context)!.darkTheme,
                        subtitle:
                            isDarkTheme
                                ? AppLocalizations.of(context)!.darkMode
                                : AppLocalizations.of(context)!.lightMode,
                        isDarkTheme: isDarkTheme,
                        value: isDarkTheme,
                        onChanged: (value) {
                          context.read<ThemeBloc>().add(
                            SetTheme(value ? 'dark' : 'light'),
                          );
                        },
                        showDivider: false,
                      ),
                    ],
                  ),

                  // Support & Help Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.supportAndHelp,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.description,
                        title: AppLocalizations.of(context)!.termsOfService,
                        subtitle:
                            AppLocalizations.of(
                              context,
                            )!.readTermsAndConditions,
                        isDarkTheme: isDarkTheme,
                        onTap: () {
                          // Navigate to terms of service
                          context.push(AppRoutes.terms);
                        },
                      ),
                      _buildSettingsOption(
                        icon: Icons.privacy_tip,
                        title: AppLocalizations.of(context)!.privacyPolicy,
                        subtitle:
                            AppLocalizations.of(context)!.readPrivacyPolicy,
                        isDarkTheme: isDarkTheme,
                        onTap: () {
                          // Navigate to privacy policy
                          context.push(AppRoutes.privacy);
                        },
                      ),
                    ],
                  ),

                  // Account Actions Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.accountActions,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.logout,
                        title: AppLocalizations.of(context)!.logout,
                        subtitle:
                            AppLocalizations.of(context)!.signOutOfAccount,
                        isDarkTheme: isDarkTheme,
                        onTap: () => _showLogoutDialog(context, isDarkTheme),
                        isDestructive: true,
                        showDivider: false,
                      ),
                    ],
                  ),

                  // SizedBox(height: 10.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 2.w),
              padding: EdgeInsets.all(12.w),
              child: CustomText(
                text: title,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkTheme,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      icon,
                      color:
                          isDestructive
                              ? Colors.red
                              : (isDarkTheme ? Colors.white : Colors.black),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: title,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isDestructive
                                  ? Colors.red
                                  : (isDarkTheme ? Colors.white : Colors.black),
                        ),
                        // SizedBox(height: 4.h),
                        // CustomText(
                        //   text: subtitle,
                        //   fontSize: 14.sp,
                        //   color: isDarkTheme ? Colors.grey : Colors.grey.shade600,
                        // ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDarkTheme ? Colors.white : Colors.black,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOptionWithSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkTheme,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  12.w,
                ), // Adjust padding for border thickness and icon spacing
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: isDarkTheme ? Colors.white : Colors.black,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: title,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                    // SizedBox(height: 4.h),
                    // CustomText(
                    //   text: subtitle,
                    //   fontSize: 14.sp,
                    //   color: isDarkTheme ? Colors.grey : Colors.grey.shade600,
                    // ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primaryColor,
                inactiveTrackColor:
                    isDarkTheme
                        ? Colors.grey.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color:
                isDarkTheme
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.3),
            height: 1.h,
            indent: 56.w,
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkTheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
          title: CustomText(
            text: AppLocalizations.of(context)!.logout,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(
            text: AppLocalizations.of(context)!.areYouSureLogout,
            fontSize: 16.sp,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(
                text: AppLocalizations.of(context)!.cancel,
                fontSize: 16.sp,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Revoke the rider token on the backend; local
                  // credentials are cleared even if this fails.
                  await AuthRepository().logout();
                } catch (_) {}
                await SessionService.endLocalSession();
                // Navigate to login page
                if (!context.mounted) return;
                GoRouter.of(context).pushReplacement(AppRoutes.login);
              },
              child: CustomText(
                text: AppLocalizations.of(context)!.logout,
                fontSize: 16.sp,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, bool isDarkTheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            final currentLanguage = localizationService.currentLanguageCode;
            final availableLanguages =
                localizationService.getAvailableLanguages();

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 24.h,
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: 600.h),
                decoration: BoxDecoration(
                  color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.1),
                            AppColors.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.language_rounded,
                              color: AppColors.primaryColor,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text:
                                      AppLocalizations.of(
                                        context,
                                      )!.selectLanguage,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: 2.h),
                                CustomText(
                                  text:
                                      AppLocalizations.of(
                                        context,
                                      )!.chooseYourPreferredLanguage,
                                  fontSize: 12.sp,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                          // Close button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20.sp,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Language options with scroll
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Column(
                          children:
                              availableLanguages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final language = entry.value;
                                final isSelected =
                                    language['code'] == currentLanguage;
                                final isLast =
                                    index == availableLanguages.length - 1;

                                return _buildEnhancedLanguageOption(
                                  languageCode: language['code'] as String,
                                  languageName: language['name'] as String,
                                  languageNameEnglish:
                                      language['nameEnglish'] as String,
                                  isSelected: isSelected,
                                  isLast: isLast,
                                  onTap: () async {
                                    await localizationService.changeLanguage(
                                      language['code'] as String,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ToastManager.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.languageChangedTo(language['name']),
                                        type: ToastType.success,
                                      );
                                    }
                                  },
                                  isDarkTheme: isDarkTheme,
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    // Bottom padding
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedLanguageOption({
    required String languageCode,
    required String languageName,
    required String languageNameEnglish,
    required bool isSelected,
    required bool isLast,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Language flag/code container
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.primaryColor.withValues(alpha: 0.8),
                                ],
                              )
                              : LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ],
                              ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ]
                              : [],
                    ),
                    child: Center(
                      child: CustomText(
                        text: languageCode.toUpperCase(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Language names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: languageName,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(height: 2.h),
                        CustomText(
                          text: languageNameEnglish,
                          fontSize: 13.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Theme.of(context).colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            )
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider (except for last item)
        if (!isLast)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.0),
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
