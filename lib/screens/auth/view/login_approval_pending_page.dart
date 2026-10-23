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
/// The rider asks the seller to approve, then taps "Check again", which
/// re-sends the same login from memory and receives the token once approved.
class LoginApprovalPendingPage extends StatelessWidget {
  const LoginApprovalPendingPage({super.key});

  void _backToLogin(BuildContext context) {
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
            ToastManager.show(context: context, message: state.message);
            GoRouter.of(context).go(AppRoutes.dashboard);
          } else if (state is AuthPendingApproval) {
            ToastManager.show(context: context, message: state.message);
          } else if (state is AuthFailure) {
            ToastManager.show(context: context, message: state.error);
            // A network error keeps the request retryable; anything the
            // backend rejected (e.g. seller declined) sends the rider back.
            if (!context.read<AuthBloc>().hasPendingLogin) {
              GoRouter.of(context).go(AppRoutes.login);
            }
          }
        },
        buildWhen: (_, current) =>
            current is AuthPendingApproval || current is AuthLoading,
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
                          'Ask your seller to approve your login, then tap "Check again".',
                      fontSize: 14.sp,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    Center(
                      child: CustomButton(
                        text: 'Check again',
                        textSize: 15.sp,
                        width: 240,
                        isLoading: isLoading,
                        onPressed:
                            () => context.read<AuthBloc>().add(
                              RetryPendingLoginRequest(),
                            ),
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
