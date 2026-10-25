import 'package:flutter/material.dart';
import 'package:nagpur_rider/utils/location_handler.dart';
import 'package:nagpur_rider/config/global.dart';
import 'location_tracker.dart';

class LocationMonitor extends StatefulWidget {
  final Widget child;

  const LocationMonitor({super.key, required this.child});

  @override
  State<LocationMonitor> createState() => _LocationMonitorState();
}

class _LocationMonitorState extends State<LocationMonitor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure environment is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationHandler.initialize();
        _restoreDuty();
      }
    });
  }

  Future<void> _restoreDuty() async {
    if ((Global.userToken ?? '').trim().isEmpty) return;
    if (await Global.getDeliveryBoyStatus() == true &&
        mounted &&
        (Global.userToken ?? '').trim().isNotEmpty) {
      await LocationTracker().startTracking();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationHandler.checkLocationAvailability();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
