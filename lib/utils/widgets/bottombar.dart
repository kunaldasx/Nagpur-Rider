// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/utils/widgets/custom_scaffold.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../../../config/colors.dart';
import '../../config/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomNavBar extends StatefulWidget {
  final Widget child;
  final bool hideBottomNav;

  const BottomNavBar({
    super.key,
    required this.child,
    this.hideBottomNav = false,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  // Define the routes for each tab
  static const List<String> _routes = [
    AppRoutes.home, // Home tab with StatisticsPage
    AppRoutes.feed, // Feed tab
    AppRoutes.pockets, // Earnings tab
    AppRoutes.more, // Settings tab
  ];

  void _onItemTapped(int index) {
    // Use GoRouter to navigate instead of setState
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Get current route to determine selected index
    final currentRoute = GoRouterState.of(context).uri.path;
    _selectedIndex = _routes.indexOf(currentRoute);
    if (_selectedIndex == -1) _selectedIndex = 0; // Default to first tab

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return CustomScaffold(
          body: Column(
            children: [
              // Main content
              Expanded(child: widget.child),

              // Solid bottom navigation bar
              if (!widget.hideBottomNav)
                Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.sameColorChange,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_routes.length, (index) {
                      final isSelected = index == _selectedIndex;
                      final route = _routes[index];

                      // Define icons and labels for each route
                      IconData icon;
                      String label;

                      switch (route) {
                        case AppRoutes.home:
                          icon = Icons.home;
                          label = AppLocalizations.of(context)!.home;
                          break;
                        case AppRoutes.feed:
                          icon = Icons.directions_bike;
                          label = AppLocalizations.of(context)!.feed;
                          break;
                        case AppRoutes.pockets:
                          icon = Icons.account_balance_wallet;
                          label = AppLocalizations.of(context)!.earnings;
                          break;
                        case AppRoutes.more:
                          icon = Icons.settings;
                          label = AppLocalizations.of(context)!.settings;
                          break;
                        default:
                          icon = Icons.home;
                          label = AppLocalizations.of(context)!.home;
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onItemTapped(index),
                          child: Container(
                            padding: EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color:
                                  Colors
                                      .transparent, // No background color for any tab
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color:
                                      isSelected
                                          ? AppColors
                                              .primaryColor // Green for active tab
                                          : Colors
                                              .grey[400], // Grey for inactive tabs
                                  size: 24.sp,
                                ),
                                CustomText(
                                  text: label,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected
                                          ? AppColors.primaryColor
                                          : Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
