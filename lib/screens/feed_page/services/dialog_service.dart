import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/currency_formatter.dart';
import '../../../config/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/widgets/toast_message.dart';
import '../model/available_orders.dart';

class DialogService {
  static void showCodPopup(BuildContext context, Orders? order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.money, color: Colors.green),
              SizedBox(width: 8.w),
              CustomText(
                text: AppLocalizations.of(context)!.cashOnDelivery,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.pleaseCollectCash,
                fontSize: 14.sp,
              ),
              SizedBox(height: 16.h),
              CustomText(
                text:
                    '${AppLocalizations.of(context)!.amount}: ${CurrencyFormatter.formatAmount(context, order?.finalTotal ?? '0')}',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: CustomText(
                text: AppLocalizations.of(context)!.ok,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  static void showEarningsPopup(
    BuildContext context,
    Orders? order,
    ConfettiController confettiController,
    bool hasShownConfetti,
    VoidCallback onClose,
  ) {
    // Show confetti only if it hasn't been shown for this order yet
    if (!hasShownConfetti) {
      confettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64.sp),
              SizedBox(height: 16.h),
              CustomText(
                text: AppLocalizations.of(context)!.orderCompleted,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: AppLocalizations.of(context)!.congratulations,
                fontSize: 14.sp,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              // Container(
                // padding: EdgeInsets.all(16.w),
                // decoration: BoxDecoration(
                  // color: AppColors.primaryColor.withValues(alpha: 0.1),
                  // borderRadius: BorderRadius.circular(8.r),
                // ),
                // child: Column(
                  // children: [
                    // CustomText(
                      // text: AppLocalizations.of(context)!.yourEarningsBreakdown,
                      // fontWeight: FontWeight.bold,
                      // fontSize: 16.sp,
                    // ),
                    // SizedBox(height: 12.h),
                    // // Breakdown details
                    // if (order?.earnings?.breakdown != null) ...[
                      // _buildBreakdownRow(
                        // context,
                        // AppLocalizations.of(context)!.baseFee,
                        // order?.earnings?.breakdown?.baseFee,
                      // ),
                      // _buildBreakdownRow(
                        // context,
                        // AppLocalizations.of(context)!.storePickupFee,
                        // order?.earnings?.breakdown?.perStorePickupFee,
                      // ),
                      // _buildBreakdownRow(
                        // context,
                        // AppLocalizations.of(context)!.distanceFee,
                        // order?.earnings?.breakdown?.distanceBasedFee,
                      // ),
                      // _buildBreakdownRow(
                        // context,
                        // AppLocalizations.of(context)!.orderIncentive,
                        // order?.earnings?.breakdown?.perOrderIncentive,
                      // ),
                      // Divider(),
                      // _buildBreakdownRow(
                        // context,
                        // AppLocalizations.of(context)!.totalEarnings,
                        // _calculateTotalEarnings(order?.earnings?.breakdown),
                        // isTotal: true,
                      // ),
                    // ],
                  // ],
                // ),
              // ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose();
                      },
                      text: AppLocalizations.of(context)!.goToHome,
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    double? amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: 14.sp,
            color: isTotal ? AppColors.primaryColor : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
          CustomText(
            text: CurrencyFormatter.formatAmount(
              context,
              amount?.toString() ?? '0',
            ),
            fontSize: 14.sp,
            color: isTotal ? AppColors.primaryColor : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ],
      ),
    );
  }

  static double? _calculateTotalEarnings(EarningsBreakdown? breakdown) {
    if (breakdown == null) return null;

    double total = 0.0;
    if (breakdown.baseFee != null) total += breakdown.baseFee!;
    if (breakdown.perStorePickupFee != null) {
      total += breakdown.perStorePickupFee!;
    }
    if (breakdown.distanceBasedFee != null) {
      total += breakdown.distanceBasedFee!;
    }
    if (breakdown.perOrderIncentive != null) {
      total += breakdown.perOrderIncentive!;
    }

    return total;
  }

  static Future<String?> showDeliveryOtpDialog(BuildContext context) async {
    String otp = '';
    String? errorMessage;

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: AppLocalizations.of(context)!.deliveryOtpRequired,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text:
                        AppLocalizations.of(
                          context,
                        )!.pleaseEnterOtpFromCustomer,
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        otp = value;
                        errorMessage = null; // Clear error when user types
                      });
                    },
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.enterOtp,
                      border: OutlineInputBorder(),
                      counterText: '',
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: CustomText(
                    text: AppLocalizations.of(context)!.cancel,
                    color: Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (otp.isEmpty || otp.length < 6) {
                      setState(() {
                        errorMessage =
                            AppLocalizations.of(context)!.pleaseEnterValidOtp;
                      });
                      return; // Don't close dialog, show error
                    }
                    Navigator.of(context).pop(otp);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: CustomText(
                    text: AppLocalizations.of(context)!.verifyOtp,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  static Future<void> showCustomerOtpDialog(
    BuildContext context,
    Orders? order,
  ) async {
    // Check if any item requires OTP
    bool requiresOtp = false;
    if (order?.items != null) {
      for (var item in order!.items!) {
        if (item.product?.requiresOtp == 1) {
          requiresOtp = true;
          break;
        }
      }
    }

    if (!requiresOtp) {
      // No OTP required, proceed with delivery
      return;
    }

    String otp = '';

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.orange),
              SizedBox(width: 8.w),
              CustomText(
                text: AppLocalizations.of(context)!.customerOtpRequired,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.pleaseEnterOtpFromCustomer,
                fontSize: 14,
              ),
              SizedBox(height: 4.h),
              CustomText(
                text:
                    order?.shippingName ??
                    AppLocalizations.of(context)!.customer,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 16.h),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enterCustomerOtp,
                  hintText: AppLocalizations.of(context)!.sixDigitCode,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  otp = value;
                },
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 100.w,
                    height: 40.h,
                    color: Colors.red,
                    child: CustomText(
                      text: AppLocalizations.of(context)!.cancel,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                CustomButton(
                  height: 40.h,
                  textSize: 15.sp,
                  text: AppLocalizations.of(context)!.verifyAndDeliver,
                  onPressed: () {
                    if (otp.length == 6) {
                      context.pop(otp);
                    }
                  },
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.white,
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      // For now, show success message
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.otpVerifiedSuccessfully,
        type: ToastType.success,
      );
    }
  }
}
