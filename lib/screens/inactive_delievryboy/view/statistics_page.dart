import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/utils/widgets/empty_state_widget.dart';
import 'package:nagpur_rider/utils/widgets/loading_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_card.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/currency_formatter.dart';
import '../../../config/colors.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../feed_page/widgets/header_section/home_header_section.dart';
import '../../system_settings/bloc/system_settings_bloc.dart';
import '../bloc/inactive_page_stats/home_stats_bloc.dart';
import '../bloc/inactive_page_stats/home_stats_state.dart';
import '../bloc/inactive_page_stats/home_stats_event.dart';
import '../model/home_stats_model.dart';
import '../repo/home_stats_repo.dart';
import 'widgets/home_dashboard_sections.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedChartPeriod = 'Week'; // Default value
  bool _isLocalized = false;
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLocalized) {
      _selectedChartPeriod = AppLocalizations.of(context)!.week;
      _isLocalized = true;
    }

    // Sync with current delivery boy status when page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryBoyStatusBloc>().add(CheckApiStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HomeStatsBloc(HomeStatsRepo())..add(FetchHomeStats()),
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.brightness == Brightness.dark
                  ? AppColors.darkBackgroundColor
                  : AppColors.backgroundColor,
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.brightness == Brightness.dark
                    ? AppColors.darkBackgroundColor
                    : AppColors.backgroundColor,
            body: Padding(
              padding: EdgeInsets.only(left: 10.0.w, right: 10.0.w, top: 5.0.h),
              child: Column(
                children: [
                  // Header Section
                  BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
                    listener: (context, state) {
                      // Handle status changes and sync with current state
                      if (state is DeliveryBoyStatusLoaded) {
                        // Status is loaded, no action needed
                      } else if (state is DeliveryBoyStatusError) {}
                    },
                    child: BlocBuilder<
                      DeliveryBoyStatusBloc,
                      DeliveryBoyStatusState
                    >(
                      builder: (context, state) {
                        bool currentStatus = state.isOnline;

                        return HomeHeaderSection(
                          handleToggle: () {
                            try {
                              final bloc =
                                  context.read<DeliveryBoyStatusBloc>();
                              final newValue = !currentStatus;

                              bloc.add(ToggleStatus(newValue));
                            } catch (e) {
                              //
                            }
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        try {
                          final bloc = context.read<HomeStatsBloc>();
                          bloc.add(RefreshHomeStats());
                          setState(() => _refreshCount++);
                        } catch (e) {
                          //
                        }
                      },
                      child: BlocBuilder<HomeStatsBloc, HomeStatsState>(
                        builder: (context, homeStatsState) {
                          if (homeStatsState is HomeStatsLoading) {
                            return const Center(child: LoadingWidget());
                          } else if (homeStatsState is HomeStatsError) {
                            return EmptyStateWidget.noData(
                              onRetry: () {
                                context.read<HomeStatsBloc>().add(
                                  FetchHomeStats(),
                                );
                              },
                            );
                          } else if (homeStatsState is HomeStatsLoaded) {
                            return _buildHomeStatsContent(
                              homeStatsState.response,
                            );
                          } else {
                            return Center(
                              child: CustomText(
                                text:
                                    AppLocalizations.of(
                                      context,
                                    )!.noDataAvailable,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          }
                        },
                      ),
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

  Widget _buildHomeStatsContent(HomeStatsResponse response) {
    final profileData = _findDataByKey(
      response.data,
      'profile',
      (data) => data.profileData,
    );
    final summaryData = _findDataByKey(
      response.data,
      'summary',
      (data) => data.summaryData,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(left: 5.w, right: 5.w, bottom: 16.h),
      child: Column(
        children: [
          HomeProfileCard(deliveryBoy: profileData?.deliveryBoy),
          SizedBox(height: 18.h),
          HomeTodayEarnings(
            key: ValueKey('today_earnings_$_refreshCount'),
            totalEarnings: summaryData?.today.earnings ?? 0,
          ),
          SizedBox(height: 18.h),
          HomeMyOrderDetails(key: ValueKey('my_orders_$_refreshCount')),
        ],
      ),
    );
  }

  Widget _buildProfileCard(HomeStatsResponse response) {
    final profileData = _findDataByKey(
      response.data,
      'profile',
      (data) => data.profileData,
    );

    return CustomCard(
      onTap: () {
        context.push(AppRoutes.profile);
      },
      padding: EdgeInsets.all(24.w),
      width: double.infinity,
      child: Row(
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.errorColor.withValues(alpha: 0.1),
                  backgroundImage: NetworkImage(
                    profileData?.deliveryBoy.profileImage ?? "",
                  ),
                ),
                // Status indicator dot
                Positioned(
                  bottom: 12.h,
                  right: 5.w,
                  child: Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color:
                          profileData?.deliveryBoy.status == 'active'
                              ? AppColors.successColor
                              : AppColors.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      profileData?.deliveryBoy.fullName ??
                      AppLocalizations.of(context)!.deliveryPartner,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: AppLocalizations.of(context)!.deliveryPartner,
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.accentYellow, size: 16),
                    SizedBox(width: 4),
                    CustomText(
                      text: '${profileData?.deliveryBoy.rating ?? 0.0}',
                      fontSize: 14,
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.local_shipping,
                      color: AppColors.accentBlue,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    CustomText(
                      text:
                          '${profileData?.deliveryBoy.totalDeliveries ?? 0} ${AppLocalizations.of(context)!.deliveries}',
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(HomeStatsResponse response) {
    final summaryData = _findDataByKey(
      response.data,
      'summary',
      (data) => data.summaryData,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppLocalizations.of(context)!.earningsAnalytics,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.today,
                CurrencyFormatter.formatAmount(
                  context,
                  (summaryData?.today.earnings ?? 0.0).toString(),
                ),
                Icons.today,
                AppColors.accentGreen,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.thisWeek,
                CurrencyFormatter.formatAmount(
                  context,
                  (summaryData?.thisWeek.earnings ?? 0.0).toString(),
                ),
                Icons.weekend,
                AppColors.accentBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.thisMonth,
                CurrencyFormatter.formatAmount(
                  context,
                  (summaryData?.thisMonth.earnings ?? 0.0).toString(),
                ),
                Icons.calendar_month,
                AppColors.accentOrange,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.total,
                CurrencyFormatter.formatAmount(
                  context,
                  (summaryData?.total.earnings ?? 0.0).toString(),
                ),
                Icons.account_balance_wallet,
                AppColors.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8.h),
          CustomText(text: title, fontSize: 12, fontWeight: FontWeight.w500),
          SizedBox(height: 4.h),
          CustomText(text: amount, fontSize: 16, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(HomeStatsResponse response) {
    final performanceData = _findDataByKey(
      response.data,
      'performanceMetrics',
      (data) => data.performanceMetricsData,
    );

    return CustomCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: AppLocalizations.of(context)!.performanceMetrics,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  AppLocalizations.of(context)!.ordersDelivered,
                  '${performanceData?.ordersDelivered ?? 0}',
                  Icons.check_circle,
                  AppColors.accentGreen,
                  () => context.push(AppRoutes.myOrders, extra: 'completed'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildMetricItem(
                  AppLocalizations.of(context)!.averageRating,
                  '${performanceData?.averageRating ?? 0.0}',
                  Icons.star,
                  AppColors.accentYellow,
                  () => context.push(
                    '/ratings',
                  ), // Clickable - navigates to ratings
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    Widget cardContent = CustomCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8.h),
          CustomText(text: title, fontSize: 12, textAlign: TextAlign.center),
          SizedBox(height: 4.h),
          CustomText(
            text: value,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          // Add hint text for clickable items
          if (onTap != null) ...[
            SizedBox(height: 4.h),
            CustomText(
              text: AppLocalizations.of(context)!.tapToView,
              fontSize: 10,
              color: Colors.grey[500],
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    // If onTap is provided, wrap with GestureDetector and add visual feedback
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 2),
            ),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }

  Widget _buildTodayProgress(HomeStatsResponse response) {
    final todayData = _findDataByKey(
      response.data,
      'todayProgress',
      (data) => data.todayProgressData,
    );

    return CustomCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: AppLocalizations.of(context)!.today,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              // Expanded(
              //   child: _buildProgressItem(
              //     AppLocalizations.of(context)!.earnings,
              //     CurrencyFormatter.formatAmount(
              //       context,
              //       (todayData?.earnings ?? 0.0).toString(),
              //     ),
              //     Icons.money,
              //     Colors.green,
              //   ),
              // ),
              // SizedBox(width: 8.w),
              Expanded(
                child: _buildProgressItem(
                  AppLocalizations.of(context)!.feeds,
                  '${todayData?.gigs ?? 0}',
                  Icons.work,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8.h),
          CustomText(text: title, fontSize: 12, textAlign: TextAlign.center),
          SizedBox(height: 4.h),
          CustomText(
            text: value,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsAnalytics(HomeStatsResponse response) {
    final analyticsData = _findDataByKey(
      response.data,
      'earningsAnalytics',
      (data) => data.value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppLocalizations.of(context)!.earningsAnalytics,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 16.h),

        // Chart Period Selector
        _buildChartPeriodSelector(),
        SizedBox(height: 16.h),

        // Chart
        _buildEarningsChart(analyticsData?['charts']),

        SizedBox(height: 20.h),

        // Summary at bottom
        _buildAnalyticsSummary(analyticsData?['summary']),
      ],
    );
  }

  Widget _buildEarningsChart(dynamic charts) {
    if (charts == null) {
      return SizedBox(
        height: 250.h,
        child: Center(
          child: CustomText(
            text: AppLocalizations.of(context)!.noChartDataAvailable,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Get data based on selected period
    List<dynamic> rawData = [];
    List<FlSpot> flSpotData = [];
    List<String> labels = [];

    try {
      final currentPeriod = _selectedChartPeriod;

      if (currentPeriod == AppLocalizations.of(context)!.week) {
        rawData = List<dynamic>.from(charts['weekly']['data'] ?? []);
        for (int i = 0; i < rawData.length; i++) {
          final item = rawData[i] as Map<String, dynamic>;
          double earnings = (item['earnings'] ?? 0).toDouble();
          flSpotData.add(FlSpot(i.toDouble(), earnings));
          labels.add(item['day']?.toString() ?? '');
        }
      } else if (currentPeriod == AppLocalizations.of(context)!.month) {
        rawData = List<dynamic>.from(charts['monthly']['data'] ?? []);
        for (int i = 0; i < rawData.length; i++) {
          final item = rawData[i] as Map<String, dynamic>;
          double earnings = (item['earnings'] ?? 0).toDouble();
          flSpotData.add(FlSpot(i.toDouble(), earnings));
          labels.add(item['week']?.toString() ?? '');
        }
      } else if (currentPeriod == AppLocalizations.of(context)!.year) {
        rawData = List<dynamic>.from(charts['yearly']['data'] ?? []);
        for (int i = 0; i < rawData.length; i++) {
          final item = rawData[i] as Map<String, dynamic>;
          double earnings = (item['earnings'] ?? 0).toDouble();
          flSpotData.add(FlSpot(i.toDouble(), earnings));
          labels.add(item['month']?.toString() ?? '');
        }
      } else {
        // Default to weekly data
        rawData = List<dynamic>.from(charts['weekly']['data'] ?? []);
        for (int i = 0; i < rawData.length; i++) {
          final item = rawData[i] as Map<String, dynamic>;
          double earnings = (item['earnings'] ?? 0).toDouble();
          flSpotData.add(FlSpot(i.toDouble(), earnings));
          labels.add(item['day']?.toString() ?? '');
        }
      }
    } catch (e) {
      return SizedBox(
        height: 250.h,
        child: Center(
          child: CustomText(
            text: AppLocalizations.of(context)!.errorLoadingChartData,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (flSpotData.isEmpty) {
      return SizedBox(
        height: 250.h,
        child: Center(
          child: CustomText(
            text: AppLocalizations.of(
              context,
            )!.noDataAvailableForPeriod(_selectedChartPeriod),
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Calculate max Y value for better scaling
    double maxY =
        flSpotData.isEmpty
            ? 5000
            : flSpotData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    maxY = (maxY * 1.2); // Add 20% padding
    if (maxY < 5000) maxY = 5000; // Minimum scale

    final settingsData = context.read<SystemSettingsBloc>();

    return CustomCard(
      height: 250.h,
      padding: EdgeInsets.only(left: 8.w, right: 16.w, top: 16.w, bottom: 16.w),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: CustomText(
                        text: labels[index],
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 5, // Show 5 labels on Y axis
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0) return const Text('');
                  return CustomText(
                    text:
                        '${settingsData.currencySymbol}${(value / 1000).toStringAsFixed(0)}K',
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  );
                },
                reservedSize: 35,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (flSpotData.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: flSpotData,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.onSurface,
                    strokeWidth: 2,
                    strokeColor: AppColors.primaryColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.3),
                    AppColors.primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor:
                  (touchedSpot) => Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  final label = index < labels.length ? labels[index] : '';
                  return LineTooltipItem(
                    '$label\n${settingsData.currencySymbol}${barSpot.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary(dynamic summary) {
    if (summary == null) return const SizedBox.shrink();

    final totalEarnings = summary['totalEarnings']?.toDouble() ?? 0.0;
    final averageEarnings = summary['averageEarnings']?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.moneybag,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: AppLocalizations.of(context)!.total,
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: CurrencyFormatter.formatAmount(
                        context,
                        totalEarnings.toString(),
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: AppLocalizations.of(context)!.average,
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: CurrencyFormatter.formatAmount(
                        context,
                        averageEarnings.toString(),
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartPeriodSelector() {
    return CustomCard(
      padding: EdgeInsets.all(5.h),
      child: Row(
        children:
            [
              AppLocalizations.of(context)!.week,
              AppLocalizations.of(context)!.month,
              AppLocalizations.of(context)!.year,
            ].map((period) {
              final isSelected = _selectedChartPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChartPeriod = period;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: CustomText(
                        text: period,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: AppLocalizations.of(context)!.quickActions,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 16.h),

          // View History Card
          GestureDetector(
            onTap: () {
              context.push('/view-history');
            },
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: AppColors.accentBlue,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: AppLocalizations.of(context)!.viewHistory,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text:
                              AppLocalizations.of(context)!.checkPastDeliveries,
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to find data by key
  T? _findDataByKey<T>(
    List<HomeStatsData> data,
    String key,
    T Function(HomeStatsData) extractor,
  ) {
    try {
      final found = data.where((item) => item.key == key).firstOrNull;
      return found != null ? extractor(found) : null;
    } catch (e) {
      return null;
    }
  }
}
