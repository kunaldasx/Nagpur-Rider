import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/utils/services/order_ringtone_service.dart';

/// Drives the rider order popup from outside the router:
/// - rings (phone ringtone + vibration, like the seller app) while a new
///   order is waiting to be accepted or skipped
/// - re-checks available orders on resume and on a timer
/// - handles the Android back button while the popup is up: an accepted
///   order's scan panel minimizes, a new order card needs Accept or Skip
///
/// Must sit ABOVE `MaterialApp.router` so its back-button observer is
/// registered before the router's and gets the first say.
class RiderPopupController extends StatefulWidget {
  final Widget child;

  const RiderPopupController({super.key, required this.child});

  @override
  State<RiderPopupController> createState() => _RiderPopupControllerState();
}

class _RiderPopupControllerState extends State<RiderPopupController>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _pollTimer;

  RiderPopupCubit get _cubit => context.read<RiderPopupCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.fetch();
    _startPolling();
    // The listener below only reacts to changes, so cover orders that were
    // already queued before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRinging(_cubit.state);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    OrderRingtoneService().stop();
    super.dispose();
  }

  void _syncRinging(RiderPopupState state) {
    if (state.hasUnaccepted) {
      OrderRingtoneService().start();
    } else {
      OrderRingtoneService().stop();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _cubit.fetch());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cubit.fetch();
        if (_cubit.state.hasUnaccepted) {
          // A call or another app may have taken audio focus meanwhile.
          OrderRingtoneService().stop().then(
            (_) => OrderRingtoneService().start(),
          );
        }
        _startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async {
    // true = handled, so neither the router nor Android closes anything.
    final state = _cubit.state;
    if (!state.isShown) return false;
    final top = state.top;
    if (top != null && state.isAccepted(top) && !top.allBagsPickedUp) {
      _cubit.setMinimized(true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RiderPopupCubit, RiderPopupState>(
      listenWhen: (prev, curr) => prev.hasUnaccepted != curr.hasUnaccepted,
      listener: (context, state) => _syncRinging(state),
      child: widget.child,
    );
  }
}
