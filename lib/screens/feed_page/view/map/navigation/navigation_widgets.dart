import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

import '../../../../../config/colors.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../store_pickup_route/services/map_service.dart';
import 'turn_by_turn_navigator.dart';

const Color _bannerColor = Color(0xFF0F6E56);
const Color _bannerDarkColor = Color(0xFF085041);

IconData maneuverIcon(String? maneuver) {
  switch (maneuver) {
    case null:
      return Icons.place;
    case 'TURN_LEFT':
      return Icons.turn_left;
    case 'TURN_RIGHT':
      return Icons.turn_right;
    case 'TURN_SLIGHT_LEFT':
      return Icons.turn_slight_left;
    case 'TURN_SLIGHT_RIGHT':
      return Icons.turn_slight_right;
    case 'TURN_SHARP_LEFT':
      return Icons.turn_sharp_left;
    case 'TURN_SHARP_RIGHT':
      return Icons.turn_sharp_right;
    case 'UTURN_LEFT':
      return Icons.u_turn_left;
    case 'UTURN_RIGHT':
      return Icons.u_turn_right;
    case 'ROUNDABOUT_LEFT':
      return Icons.roundabout_left;
    case 'ROUNDABOUT_RIGHT':
      return Icons.roundabout_right;
    case 'FORK_LEFT':
      return Icons.fork_left;
    case 'FORK_RIGHT':
      return Icons.fork_right;
    case 'RAMP_LEFT':
      return Icons.ramp_left;
    case 'RAMP_RIGHT':
      return Icons.ramp_right;
    case 'MERGE':
      return Icons.merge;
    case 'FERRY':
    case 'FERRY_TRAIN':
      return Icons.directions_boat;
    case 'DEPART':
      return Icons.navigation;
    default:
      return Icons.straight;
  }
}

/// Green banner at the top: next maneuver, distance to it, and a "Then"
/// chip for the maneuver after.
class NavigationBanner extends StatelessWidget {
  final NavProgress progress;

  const NavigationBanner({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upcoming = progress.upcoming;
    final title =
        upcoming != null
            ? TurnByTurnNavigator.primaryInstruction(upcoming)
            : l10n.arriveAtDestination;
    final subtitle =
        upcoming != null
            ? TurnByTurnNavigator.secondaryInstruction(upcoming)
            : null;
    final then = progress.then;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: _bannerColor,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Icon(
                maneuverIcon(upcoming?.maneuver),
                color: Colors.white,
                size: 40.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: TurnByTurnNavigator.displayDistance(
                        progress.distanceToManeuverMeters,
                      ),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    CustomText(
                      text: title,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      CustomText(
                        text: subtitle,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (then != null)
          Container(
            margin: EdgeInsets.only(left: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _bannerDarkColor,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(10.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: l10n.thenLabel,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                SizedBox(width: 6.w),
                Icon(
                  maneuverIcon(then.maneuver),
                  color: Colors.white,
                  size: 18.sp,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bottom bar while navigating: exit, time/distance/arrival, steps list.
class NavigationBottomBar extends StatelessWidget {
  final NavProgress progress;
  final bool isDarkTheme;
  final VoidCallback onExit;
  final VoidCallback onShowSteps;

  const NavigationBottomBar({
    super.key,
    required this.progress,
    required this.isDarkTheme,
    required this.onExit,
    required this.onShowSteps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = (progress.remainingSeconds / 60).ceil().clamp(1, 100000);
    final arrival = DateTime.now().add(
      Duration(seconds: progress.remainingSeconds.round()),
    );
    final arrivalText = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(arrival);

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.close,
            tooltip: l10n.exitNavigation,
            color: Colors.red.shade700,
            background: Colors.red.withValues(alpha: 0.12),
            onPressed: onExit,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: l10n.routeMinutes(minutes),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
                CustomText(
                  text:
                      '${TurnByTurnNavigator.displayDistance(progress.remainingMeters)} · $arrivalText',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: l10n.routeSteps,
            color: isDarkTheme ? Colors.white : Colors.grey.shade800,
            background:
                isDarkTheme
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
            onPressed: onShowSteps,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color background;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(icon, color: color, size: 24.sp),
          ),
        ),
      ),
    );
  }
}

/// Round white map button (mute, overview).
class NavigationMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const NavigationMapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(icon, color: AppColors.primaryColor, size: 22.sp),
          ),
        ),
      ),
    );
  }
}

/// "Re-centre" pill shown once the rider pans the map away.
class RecenterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecenterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.navigation,
                color: AppColors.primaryColor,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              CustomText(
                text: AppLocalizations.of(context)!.recenter,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Current speed in a round sign, like Google Maps.
class SpeedBubble extends StatelessWidget {
  final double speedMetersPerSecond;

  const SpeedBubble({super.key, required this.speedMetersPerSecond});

  @override
  Widget build(BuildContext context) {
    final kmh =
        (speedMetersPerSecond.isFinite ? speedMetersPerSecond * 3.6 : 0)
            .clamp(0, 300)
            .round();
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade800, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6.r,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: '$kmh',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          CustomText(
            text: AppLocalizations.of(context)!.kmPerHour,
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}

/// Full list of turns, with the step the rider is on highlighted.
Future<void> showRouteStepsSheet(
  BuildContext context, {
  required List<NavStep> steps,
  required int currentStepIndex,
  required String summary,
  required String destination,
  required bool isDarkTheme,
  required VoidCallback onOpenInGoogleMaps,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: summary,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: l10n.toDestination(destination),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: steps.length + 1,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                  itemBuilder: (context, index) {
                    if (index == steps.length) {
                      return ListTile(
                        leading: const Icon(Icons.place, color: Colors.red),
                        title: CustomText(
                          text: l10n.arriveAtDestination,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    final step = steps[index];
                    final isCurrent = index == currentStepIndex;
                    final detail = TurnByTurnNavigator.secondaryInstruction(
                      step,
                    );
                    return Container(
                      color:
                          isCurrent
                              ? Colors.green.withValues(alpha: 0.12)
                              : null,
                      child: ListTile(
                        leading: Icon(
                          maneuverIcon(step.maneuver),
                          color: isCurrent ? Colors.green[700] : null,
                        ),
                        title: CustomText(
                          text: TurnByTurnNavigator.primaryInstruction(step),
                          fontSize: 14.sp,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                        subtitle: CustomText(
                          text: [
                            TurnByTurnNavigator.displayDistance(
                              step.distanceMeters,
                            ),
                            if (detail != null) detail,
                          ].join(' · '),
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onOpenInGoogleMaps();
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.openInGoogleMaps),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
