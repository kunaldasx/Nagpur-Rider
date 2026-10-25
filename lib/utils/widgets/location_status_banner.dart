import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import '../location_tracker.dart';
import 'custom_text.dart';

/// Explain background access before either platform can display its prompt.
Future<bool> explainBackgroundLocation(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l10n.locationAllowAlways),
              content: Text(l10n.locationBackgroundExplanation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.locationAllowAlways),
                ),
              ],
            ),
      ) ??
      false;
}

class LocationStatusBanner extends StatefulWidget {
  final LocationTracker? tracker;
  const LocationStatusBanner({super.key, this.tracker});
  @override
  State<LocationStatusBanner> createState() => _LocationStatusBannerState();
}

class _LocationStatusBannerState extends State<LocationStatusBanner> {
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracker = widget.tracker ?? LocationTracker();
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<LocationHealth>(
      valueListenable: tracker.health,
      builder: (context, health, _) {
        final age =
            health.lastSentAt == null
                ? null
                : DateTime.now()
                    .difference(health.lastSentAt!)
                    .inSeconds
                    .clamp(0, 99999);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: CustomText(
                text:
                    age == null
                        ? l10n.locationWaiting
                        : l10n.locationSentStatus(
                          age,
                          health.lastAccuracyMeters?.round() ?? 0,
                        ),
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            if (health.status != LocationHealthStatus.ok)
              LocationIssueBanner(status: health.status),
          ],
        );
      },
    );
  }
}

class LocationIssueBanner extends StatelessWidget {
  final LocationHealthStatus status;
  final String? message;
  const LocationIssueBanner({super.key, required this.status, this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text =
        message ??
        switch (status) {
          LocationHealthStatus.serviceOff => l10n.locationGpsOff,
          LocationHealthStatus.permissionDenied => l10n.locationAccessOff,
          LocationHealthStatus.backgroundDenied => l10n.locationBackgroundOff,
          LocationHealthStatus.weakSignal => l10n.locationWeakSignal,
          LocationHealthStatus.mockLocation => l10n.locationMock,
          LocationHealthStatus.stale => l10n.locationStale,
          LocationHealthStatus.ok => '',
        };
    final blocking = {
      LocationHealthStatus.serviceOff,
      LocationHealthStatus.permissionDenied,
      LocationHealthStatus.mockLocation,
    }.contains(status);
    final color = blocking ? AppColors.errorColor : Colors.amber.shade900;
    String? action;
    Future<void> Function()? fix;
    if (status == LocationHealthStatus.serviceOff) {
      action = l10n.locationTurnOn;
      fix = () async {
        await Geolocator.openLocationSettings();
      };
    } else if (status == LocationHealthStatus.permissionDenied) {
      action = l10n.locationOpenSettings;
      fix = () async {
        await Geolocator.openAppSettings();
      };
    } else if (status == LocationHealthStatus.backgroundDenied) {
      action = l10n.locationAllowAlways;
      fix = () async {
        try {
          await LocationTracker().checkDutyAccess(
            explainBackground: () => explainBackgroundLocation(context),
          );
          await LocationTracker().onResume();
        } catch (e) {
          debugPrint('[LocationTracker] permission: $e');
        }
      };
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: text, color: color, fontSize: 13),
          if (action != null) TextButton(onPressed: fix, child: Text(action)),
        ],
      ),
    );
  }
}
