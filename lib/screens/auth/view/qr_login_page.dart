import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import '../../../config/colors.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/toast_message.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../bloc/auth_bloc/auth_event.dart';
import '../bloc/auth_bloc/auth_state.dart';

/// Scans the rider QR shown in the seller app and logs in with it.
class QrLoginPage extends StatefulWidget {
  const QrLoginPage({super.key});

  @override
  State<QrLoginPage> createState() => _QrLoginPageState();
}

class _QrLoginPageState extends State<QrLoginPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isSubmitting = false;
  String? _submittedQrToken;

  // A rejected QR stays invalid, so it is not re-sent on every frame
  // (the endpoint allows 10 attempts per minute).
  String? _rejectedQrToken;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isSubmitting) return;

    for (final barcode in capture.barcodes) {
      // The QR content is the opaque qr_payload; send it exactly as scanned.
      final qrToken = barcode.rawValue;
      if (qrToken == null || qrToken.isEmpty) continue;
      if (qrToken == _rejectedQrToken) return;

      setState(() {
        _isSubmitting = true;
        _submittedQrToken = qrToken;
        _errorMessage = null;
      });
      context.read<AuthBloc>().add(QrLoginRequest(qrToken: qrToken));
      return;
    }
  }

  void _scanAgain() {
    setState(() {
      _rejectedQrToken = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanBoxSize = 250.w;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, __) => _isSubmitting,
      listener: (context, state) {
        if (state is AuthSuccess) {
          ToastManager.show(context: context, message: state.message);
          GoRouter.of(context).go(AppRoutes.dashboard);
        } else if (state is AuthFailure) {
          setState(() {
            _isSubmitting = false;
            _rejectedQrToken = _submittedQrToken;
            _errorMessage = state.error;
          });
          ToastManager.show(context: context, message: state.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Scan QR to Login'),
          actions: [
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                  onPressed: _controller.toggleTorch,
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _cameraError(error),
            ),
            Center(
              child: Container(
                width: scanBoxSize,
                height: scanBoxSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
            Positioned(
              left: 24.w,
              right: 24.w,
              bottom: 40.h,
              child: _statusPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPanel() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSubmitting) ...[
            const CircularProgressIndicator(),
            SizedBox(height: 12.h),
            CustomText(text: 'Logging you in...', fontSize: 14.sp),
          ] else if (_errorMessage != null) ...[
            CustomText(
              text: _errorMessage!,
              fontSize: 14.sp,
              color: Colors.red,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _scanAgain,
              child: CustomText(
                text: 'Scan again',
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            CustomText(
              text:
                  'Ask your seller to open your rider QR code and point the camera at it.',
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _cameraError(MobileScannerException error) {
    final message =
        error.errorCode == MobileScannerErrorCode.permissionDenied
            ? 'Camera permission is required to scan the login QR code. Please allow it in Settings.'
            : 'Unable to start the camera.';
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: CustomText(
          text: message,
          color: Colors.white,
          fontSize: 15.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
