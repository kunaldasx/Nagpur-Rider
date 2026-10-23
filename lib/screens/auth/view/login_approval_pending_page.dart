import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import '../../../config/colors.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/toast_message.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../bloc/auth_bloc/auth_event.dart';
import '../bloc/auth_bloc/auth_state.dart';

/// Shown after an email/password login creates a seller approval request.
/// Checks approval every six seconds, or when the rider taps "Check again",
/// by re-sending the same login from memory until the seller approves it.
class LoginApprovalPendingPage extends StatefulWidget {
  const LoginApprovalPendingPage({super.key});

  @override
  State<LoginApprovalPendingPage> createState() =>
      _LoginApprovalPendingPageState();
}

class _LoginApprovalPendingPageState extends State<LoginApprovalPendingPage> {
  Timer? _autoCheckTimer;
  Timer? _retryCooldown;
  int _cooldownSeconds = 0;
  bool _isAutomaticCheck = false;

  @override
  void initState() {
    super.initState();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState != null &&
          lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      _checkAgain(automatic: true);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _retryCooldown?.cancel();
    super.dispose();
  }

  void _checkAgain({bool automatic = false}) {
    final bloc = context.read<AuthBloc>();
    if (!bloc.hasPendingLogin ||
        _cooldownSeconds > 0 ||
        bloc.state is AuthLoading) {
      return;
    }

    _isAutomaticCheck = automatic;
    setState(() => _cooldownSeconds = 5);
    _retryCooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds == 0) timer.cancel();
    });
    bloc.add(RetryPendingLoginRequest());
  }

  void _backToLogin(BuildContext context) {
    _autoCheckTimer?.cancel();
    context.read<AuthBloc>().add(CancelPendingLoginRequest());
    GoRouter.of(context).go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin(context);
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _autoCheckTimer?.cancel();
            ToastManager.show(context: context, message: state.message);
            GoRouter.of(context).go(AppRoutes.dashboard);
          } else if (state is AuthPendingApproval) {
            if (!_isAutomaticCheck) {
              ToastManager.show(context: context, message: state.message);
            }
          } else if (state is AuthFailure) {
            ToastManager.show(context: context, message: state.error);
            // A network error keeps the request retryable; anything the
            // backend rejected (e.g. seller declined) sends the rider back.
            if (!context.read<AuthBloc>().hasPendingLogin) {
              _autoCheckTimer?.cancel();
              GoRouter.of(context).go(AppRoutes.login);
            }
          }
        },
        buildWhen:
            (_, current) =>
                current is AuthPendingApproval ||
                current is AuthLoading ||
                current is AuthFailure,
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final pending = state is AuthPendingApproval ? state : null;
          final lastPending =
              pending ?? context.read<AuthBloc>().lastPendingApproval;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _backToLogin(context),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 72.sp,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(height: 20.h),
                    CustomText(
                      text: 'Waiting for seller approval',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    CustomText(
                      text:
                          lastPending?.message.isNotEmpty == true
                              ? lastPending!.message
                              : 'Your rider login request is waiting for seller approval.',
                      fontSize: 15.sp,
                      textAlign: TextAlign.center,
                    ),
                    if (lastPending != null) ...[
                      SizedBox(height: 16.h),
                      CustomText(
                        text: lastPending.email,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                      if (lastPending.requestedAt != null) ...[
                        SizedBox(height: 4.h),
                        CustomText(
                          text:
                              'Requested at ${DateFormat('dd MMM yyyy, hh:mm a').format(lastPending.requestedAt!.toLocal())}',
                          fontSize: 13.sp,
                          color: Colors.grey,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                    SizedBox(height: 12.h),
                    CustomText(
                      text:
                          'Ask your seller to approve your login. We check automatically every 6 seconds, or you can tap "Check again".',
                      fontSize: 14.sp,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    Center(
                      child: CustomButton(
                        text:
                            _cooldownSeconds > 0
                                ? 'Check again (${_cooldownSeconds}s)'
                                : 'Check again',
                        textSize: 15.sp,
                        width: 240,
                        isLoading: isLoading,
                        onPressed: _cooldownSeconds > 0 ? null : _checkAgain,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => _backToLogin(context),
                      child: CustomText(
                        text: 'Back to login',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
