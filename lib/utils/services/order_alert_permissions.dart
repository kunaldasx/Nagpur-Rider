import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';

/// What incoming-order alerts need to ring reliably, checked when the rider
/// goes on duty. Each missing item is explained; nothing is requested
/// without the rider tapping it.
class OrderAlertPermissions {
  OrderAlertPermissions._();

  static bool _showing = false;

  /// Shows what's missing, if anything. Android only.
  static Future<void> check(BuildContext context) async {
    if (!Platform.isAndroid || _showing) return;
    final missing = await _missing();
    if (missing.isEmpty || !context.mounted) return;
    _showing = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => _PermissionsDialog(initial: missing),
      );
    } finally {
      _showing = false;
    }
  }

  static Future<List<_Item>> _missing() async {
    return [
      if (!await Permission.notification.isGranted) _Item.notifications,
      if (!await OrderAlertBridge.canUseFullScreenIntent()) _Item.fullScreen,
      if (!await Permission.systemAlertWindow.isGranted) _Item.openOverApps,
      if (!await Permission.ignoreBatteryOptimizations.isGranted) _Item.battery,
      if (await OrderAlertBridge.isAlarmMuted()) _Item.alarmVolume,
    ];
  }
}

enum _Item {
  notifications(
    Icons.notifications_active_outlined,
    'Notifications',
    'New orders are shown as a notification with an Accept button.',
    'Allow',
  ),
  fullScreen(
    Icons.screen_lock_portrait_outlined,
    'Show over lock screen',
    'Shows the new order on the screen while your phone is locked.',
    'Allow',
  ),
  openOverApps(
    Icons.open_in_new_rounded,
    'Display over other apps',
    'Opens the new order by itself while you use your phone or another app.',
    'Allow',
  ),
  battery(
    Icons.battery_alert_outlined,
    'No battery restrictions',
    'Stops Android from delaying new orders while the app is closed.',
    'Allow',
  ),
  alarmVolume(
    Icons.volume_off_outlined,
    'Alarm volume is off',
    'Orders ring at alarm volume. Turn it up with the volume buttons.',
    null,
  );

  final IconData icon;
  final String title;
  final String reason;
  final String? action;

  const _Item(this.icon, this.title, this.reason, this.action);

  Future<void> fix() async {
    switch (this) {
      case _Item.notifications:
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) await openAppSettings();
        break;
      case _Item.fullScreen:
        await OrderAlertBridge.openFullScreenIntentSettings();
        break;
      case _Item.openOverApps:
        // Opens the system "Display over other apps" page for this app.
        await Permission.systemAlertWindow.request();
        break;
      case _Item.battery:
        await Permission.ignoreBatteryOptimizations.request();
        break;
      case _Item.alarmVolume:
        break;
    }
  }
}

class _PermissionsDialog extends StatefulWidget {
  final List<_Item> initial;

  const _PermissionsDialog({required this.initial});

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog>
    with WidgetsBindingObserver {
  late List<_Item> _missing = widget.initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Settings pages are left with Back: re-check what's still missing then.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final missing = await OrderAlertPermissions._missing();
    if (!mounted) return;
    if (missing.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _missing = missing);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Get every new order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'While you are on duty, new orders ring until you accept them, '
              'even when the app is closed. This phone needs:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final item in _missing)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.reason),
                trailing:
                    item.action == null
                        ? null
                        : TextButton(
                          onPressed: () async {
                            await item.fix();
                            await _refresh();
                          },
                          child: Text(item.action!),
                        ),
              ),
            const SizedBox(height: 4),
            Text(
              'On Xiaomi, Oppo, Vivo, Realme and OnePlus phones, also turn on '
              'Autostart for this app in its settings.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: openAppSettings,
          child: const Text('App settings'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
      ],
    );
  }
}
