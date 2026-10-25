// ignore_for_file: empty_catches, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:nagpur_rider/screens/settings/bloc/profile_bloc/profile_state.dart';
import 'package:nagpur_rider/screens/settings/model/profile_model.dart';
import 'package:nagpur_rider/utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_card.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../feed_page/widgets/header_section/home_header_section.dart';
import '../earnings/bloc/earnings_bloc.dart';
import '../earnings/bloc/earnings_event.dart';

import '../earnings/repo/earnings_repo.dart';
import '../../../utils/currency_formatter.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../../l10n/app_localizations.dart';

import '../../../../config/colors.dart';

class PocketsPage extends StatefulWidget {
  const PocketsPage({super.key});

  @override
  State<PocketsPage> createState() => _PocketsPageState();
}

class _PocketsPageState extends State<PocketsPage> {
  late EarningsBloc _earningsBloc;

  @override
  void initState() {
    super.initState();
    // Create the bloc instance
    _earningsBloc = EarningsBloc(EarningsRepo(), context: context);
    // Check delivery boy status first, then conditionally make API calls
    context.read<DeliveryBoyStatusBloc>().add(CheckApiStatus());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sync with current delivery boy status when page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryBoyStatusBloc>().add(CheckApiStatus());
    });
  }

  @override
  void dispose() {
    _earningsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Exit App'),
                  content: const Text('Are you sure you want to exit the app?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Exit'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      child: MultiBlocProvider(
        providers: [BlocProvider(create: (context) => _earningsBloc)],
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: CustomScaffold(
              body: Stack(
                children: [
                  // Main pockets content (always visible)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 10.0.w,
                      right: 10.0.w,
                      top: 5.0.h,
                      bottom: 16.0.h, // Keep padding to avoid overlap with FAB
                    ),
                    child: Column(
                      children: [
                        // Header (always visible)
                        BlocBuilder<
                          DeliveryBoyStatusBloc,
                          DeliveryBoyStatusState
                        >(
                          builder: (context, statusState) {
                            bool currentStatus = statusState.isOnline;

                            return HomeHeaderSection(
                              handleToggle: () {
                                try {
                                  final bloc =
                                      context.read<DeliveryBoyStatusBloc>();
                                  final newValue = !currentStatus;
                                  bloc.add(ToggleStatus(newValue));
                                } catch (e) {}
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        // Content
                        Expanded(child: _buildPocketsView()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsSection() {
    return BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      builder: (context, statusState) {
        return Column(
          children: [
            // // Earnings Card
            // GestureDetector(
            // onTap: () {
            // context.push('/earnings');
            // },
            // child: CustomCard(
            // padding: EdgeInsets.all(20.w),
            // child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
            // Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // children: [
            // CustomText(
            // text: _getCurrentWeekRange(),
            // fontSize: 14.sp,
            // fontWeight: FontWeight.w600,
            // ),
            // Icon(
            // Icons.arrow_forward_ios,
            // size: 16.sp,
            // color: Theme.of(
            // context,
            // ).colorScheme.onSurface.withValues(alpha: 0.6),
            // ),
            // ],
            // ),
            // SizedBox(height: 12.h),
            // BlocBuilder<EarningsBloc, EarningsState>(
            // builder: (context, state) {
            // if (state is EarningsStatsLoaded) {
            // return CustomText(
            // text: CurrencyFormatter.formatAmount(
            // context,
            // '${state.response.data?.totalEarnings ?? 0}',
            // ),
            // fontSize: 20.sp,
            // fontWeight: FontWeight.bold,
            // );
            // }
            // return CustomText(
            // text: CurrencyFormatter.formatAmount(context, '0'),
            // fontSize: 20.sp,
            // fontWeight: FontWeight.bold,
            // );
            // },
            // ),
            // ],
            // ),
            // ),
            // ),

            // // Earnings Statistics
            // SizedBox(height: 16.h),

            // // Earnings Statistics Section
            // BlocBuilder<EarningsBloc, EarningsState>(
            // builder: (context, state) {
            // if (state is EarningsStatsLoaded &&
            // state.response.data != null) {
            // return _buildEarningsStats(state.response.data!);
            // } else if (state is EarningsError) {
            // return _buildEarningsErrorState(state.message);
            // } else if (state is EarningsLoading) {
            // return const Center(child: CupertinoActivityIndicator());
            // } else {
            // return const SizedBox.shrink();
            // }
            // },
            // ),

            // SizedBox(height: 16.h),
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded && state.profile.user != null) {
                  return _buildUserBalance(state.profile);
                } else if (state is ProfileError) {
                  return _buildEarningsErrorState(state.message);
                } else if (state is ProfileLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),

            // Date Range Section

            // _buildDateRangeSection(isStatusActive),

            // Action Buttons below earnings (moved from floating position)
            SizedBox(height: 16.h),
            Column(
              children: [
                CustomButton(
                  textSize: 12.sp,

                  width: double.infinity,
                  onPressed: () {
                    context.push('/cash-collection');
                  },
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.white,
                  text: AppLocalizations.of(context)!.cashOnDelivery,
                  icon: Icon(Icons.money, color: Colors.white, size: 14.sp),
                ),
                SizedBox(height: 16.h),
                CustomButton(
                  textSize: 12.sp,
                  width: double.infinity,
                  onPressed: () {
                    context.push('/withdrawal-history');
                  },
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.white,
                  text: AppLocalizations.of(context)!.withdrawalHistory,
                  icon: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserBalance(ProfileModel profile) {
    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: AppLocalizations.of(context)!.balance,

            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  CurrencyFormatter.formatAmount(
                    context,
                    '${profile.user?.walletBalance ?? 0}',
                  ),
                  Icons.money,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatItem(
                  'Blocked',
                  CurrencyFormatter.formatAmount(
                    context,
                    '${profile.user?.blockedBalance ?? 0}',
                  ),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatItem(
                  'Available',
                  CurrencyFormatter.formatAmount(
                    context,
                    '${profile.user?.availableBalance ?? 0}',
                  ),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsErrorState(String message) {
    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: AppLocalizations.of(context)!.somethingWentWrong,

            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          // SizedBox(height: 4.h),
          // CustomText(
          //   text: message,
          //
          //   fontSize: 12.sp,
          //   color: Theme.of(context).colorScheme.error,
          //   textAlign: TextAlign.center,
          // ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(height: 8.h),
        CustomText(
          text: value,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        CustomText(
          text: title,
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildPocketsView() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Always show the pockets content regardless of delivery boy status
    return _buildPocketsContent(isDarkTheme);
  }

  Widget _buildPocketsContent(bool isDarkTheme) {
    // Make API calls to fetch earnings data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _earningsBloc.add(FetchEarningsStats());
    });

    return _buildEarningsSection();
  }
}
