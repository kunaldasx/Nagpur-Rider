import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/alert_accept_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/widgets/common.dart';

/// Sits in `MaterialApp.builder`, above the order popup. Covers the app
/// while an order accepted from its incoming-order alert is confirmed with
/// the backend, and when that fails.
class AlertAcceptLayer extends StatelessWidget {
  final Widget child;

  const AlertAcceptLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertAcceptCubit, AlertAcceptState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state.isShown)
              Positioned.fill(child: _AcceptCard(state: state)),
          ],
        );
      },
    );
  }
}

class _AcceptCard extends StatelessWidget {
  final AlertAcceptState state;

  const _AcceptCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AlertAcceptCubit>();
    final orderId = state.orderId;

    final (Widget icon, String title) = switch (state.phase) {
      AlertAcceptPhase.retry => (
        Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.error),
        "Couldn't accept order #$orderId",
      ),
      AlertAcceptPhase.unavailable => (
        Icon(Icons.info_outline_rounded, size: 40, color: Colors.orange[700]),
        'Order #$orderId is no longer yours',
      ),
      _ => (
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        'Accepting order #$orderId…',
      ),
    };

    final subtitle = switch (state.phase) {
      AlertAcceptPhase.accepting => 'Confirming with the server',
      AlertAcceptPhase.retry =>
        '${state.message}\nThe order keeps ringing until it is accepted.',
      _ => state.message,
    };

    return Material(
      color: popupSurface(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(child: icon),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const Spacer(),
              if (state.phase == AlertAcceptPhase.retry) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: cubit.retry,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: cubit.dismiss,
                  child: const Text('Close'),
                ),
              ],
              if (state.phase == AlertAcceptPhase.unavailable)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: cubit.dismiss,
                  child: const Text('OK'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
