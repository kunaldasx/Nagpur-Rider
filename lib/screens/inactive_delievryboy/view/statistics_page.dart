import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nagpur_rider/utils/widgets/empty_state_widget.dart';
import 'package:nagpur_rider/utils/widgets/loading_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../config/colors.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../feed_page/widgets/header_section/home_header_section.dart';
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
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
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
