import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../model/cod_payment.dart';
import '../../repo/cod_payment_repo.dart';

/// How the rider settled the COD amount for an order item.
enum CodPaymentOutcome {
  /// Rider collected cash; the delivery request must carry
  /// `payment_collection: {method: cash}`.
  cash,

  /// Razorpay webhook confirmed the UPI QR payment; deliver as usual.
  upiPaid,
}

enum _Step { chooseMethod, cash, upi }

/// Bottom sheet that asks the rider whether the customer pays by cash or UPI
/// before the final delivery. Resolves to `null` when the rider backs out.
class CodPaymentSheet extends StatefulWidget {
  final String orderItemId;
  final CodPaymentInstructions instructions;

  const CodPaymentSheet({
    super.key,
    required this.orderItemId,
    required this.instructions,
  });

  static Future<CodPaymentOutcome?> show(
    BuildContext context, {
    required String orderItemId,
    required CodPaymentInstructions instructions,
  }) {
    return showModalBottomSheet<CodPaymentOutcome>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (_) => CodPaymentSheet(
            orderItemId: orderItemId,
            instructions: instructions,
          ),
    );
  }

  @override
  State<CodPaymentSheet> createState() => _CodPaymentSheetState();
}

class _CodPaymentSheetState extends State<CodPaymentSheet> {
  static const _pollInterval = Duration(seconds: 3);

  final CodPaymentRepo _repo = CodPaymentRepo();

  late CodPaymentInstructions _instructions;
  _Step _step = _Step.chooseMethod;

  bool _creatingQr = false;
  String? _qrError;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _pollInFlight = false;
  Duration _remaining = Duration.zero;

  RazorpayQr? get _qr => _instructions.razorpayQr;
  bool get _upiPaid => _instructions.isCompleted || (_qr?.isCompleted ?? false);
  bool get _qrExpired => !_upiPaid && (_qr?.isExpired ?? false);

  @override
  void initState() {
    super.initState();
    _instructions = widget.instructions;
    // Cash is the only option when QR payments are unavailable.
    if (!_instructions.acceptsUpi) _step = _Step.cash;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  String get _amountText {
    final symbol = _instructions.currency.toUpperCase() == 'INR'
        ? '₹'
        : '${_instructions.currency} ';
    final value = double.tryParse(_instructions.amount);
    return '$symbol${value?.toStringAsFixed(2) ?? _instructions.amount}';
  }

  // ---------------------------------------------------------------- UPI flow

  Future<void> _startUpi() async {
    setState(() {
      _step = _Step.upi;
      _creatingQr = true;
      _qrError = null;
    });
    try {
      final result = await _repo.createPaymentQr(widget.orderItemId);
      if (!mounted) return;
      setState(() {
        _instructions = result;
        _creatingQr = false;
      });
      _onQrUpdated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingQr = false;
        _qrError = e.toString();
      });
    }
  }

  /// Starts or stops polling/countdown depending on the latest QR status.
  void _onQrUpdated() {
    if (_upiPaid || _qr == null || _qrExpired) {
      _stopTimers();
      if (mounted) setState(() {});
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => _poll());
    _countdownTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCountdown(),
    );
    _tickCountdown();
  }

  void _tickCountdown() {
    final expiresAt = _qr?.expiresAt;
    if (!mounted || expiresAt == null) return;
    final left = expiresAt.difference(DateTime.now());
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
    if (left.isNegative) _onQrUpdated();
  }

  Future<void> _poll() async {
    if (_pollInFlight || !mounted) return;
    _pollInFlight = true;
    try {
      final result = await _repo.getPaymentInstructions(widget.orderItemId);
      if (!mounted || _step != _Step.upi) return;
      setState(() => _instructions = result);
      _onQrUpdated();
    } catch (_) {
      // Transient network failure: keep polling.
    } finally {
      _pollInFlight = false;
    }
  }

  void _backToMethods() {
    _stopTimers();
    setState(() {
      _step = _Step.chooseMethod;
      _qrError = null;
    });
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _buildHeader(),
            SizedBox(height: 16.h),
            _buildAmountCard(),
            SizedBox(height: 20.h),
            switch (_step) {
              _Step.chooseMethod => _buildMethodChooser(),
              _Step.cash => _buildCashStep(),
              _Step.upi => _buildUpiStep(),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canGoBack =
        _step != _Step.chooseMethod && _instructions.acceptsUpi && !_upiPaid;
    return Row(
      children: [
        if (canGoBack)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _backToMethods,
          ),
        Expanded(
          child: CustomText(
            text: switch (_step) {
              _Step.chooseMethod => 'Collect Payment',
              _Step.cash => 'Cash Payment',
              _Step.upi => 'UPI Payment',
            },
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!_upiPaid)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          CustomText(
            text: 'Amount to collect',
            fontSize: 13.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 4.h),
          CustomText(
            text: _amountText,
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          text: 'How is the customer paying?',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 12.h),
        _methodTile(
          icon: Icons.payments_outlined,
          title: 'Cash',
          subtitle: 'Collect cash from the customer',
          color: Colors.green,
          onTap: () => setState(() => _step = _Step.cash),
        ),
        SizedBox(height: 12.h),
        _methodTile(
          icon: Icons.qr_code_2,
          title: 'UPI',
          subtitle: 'Customer scans a QR with any UPI app',
          color: AppColors.primaryColor,
          onTap: _startUpi,
        ),
      ],
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: title,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: subtitle,
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(
              child: CustomText(
                text:
                    'Collect $_amountText in cash from the customer, then confirm below. This amount is added to your cash ledger.',
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _primaryButton(
          label: 'Cash Collected – Mark Delivered',
          color: Colors.green,
          onPressed: () => Navigator.of(context).pop(CodPaymentOutcome.cash),
        ),
      ],
    );
  }

  Widget _buildUpiStep() {
    if (_creatingQr) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 12.h),
            CustomText(text: 'Generating UPI QR…', fontSize: 13.sp),
          ],
        ),
      );
    }

    if (_qrError != null) {
      return _buildUpiError(_qrError!);
    }

    if (_upiPaid) return _buildUpiSuccess();

    if (_qr == null) {
      return _buildUpiError('UPI QR is not available right now.');
    }

    if (_qrExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.timer_off_outlined, size: 56.sp, color: Colors.orange),
          SizedBox(height: 8.h),
          CustomText(
            text: 'This QR has expired.',
            textAlign: TextAlign.center,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          _primaryButton(
            label: 'Generate New QR',
            color: AppColors.primaryColor,
            onPressed: _startUpi,
          ),
        ],
      );
    }

    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status first so it stays visible above the tall Razorpay poster.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8.w),
            CustomText(
              text: 'Waiting for payment confirmation…',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        if (_qr!.expiresAt != null) ...[
          SizedBox(height: 4.h),
          CustomText(
            text: 'QR expires in $minutes:$seconds',
            textAlign: TextAlign.center,
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ],
        SizedBox(height: 12.h),
        _buildQrImage(),
        SizedBox(height: 10.h),
        CustomText(
          text: 'Ask the customer to scan this QR with any UPI app. Tap the QR to enlarge.',
          textAlign: TextAlign.center,
          fontSize: 13.sp,
        ),
        SizedBox(height: 10.h),
        CustomText(
          text:
              'Do not rely on the customer\'s payment screen. Delivery unlocks automatically once the payment is confirmed.',
          textAlign: TextAlign.center,
          fontSize: 11.sp,
          color: Colors.grey,
        ),
      ],
    );
  }

  // Razorpay's QR poster is 674x1644 with large empty margins; this is the
  // QR code itself (plus its quiet zone) inside it, as fractions of the image.
  static const _cropLeft = 133 / 674;
  static const _cropTop = 645 / 1644;
  static const _cropWidth = 406 / 674;
  static const _cropHeight = 405 / 1644;
  static const _posterAspect = 674 / 1644;

  /// Shows only the QR code from the Razorpay poster at full sheet width.
  /// Tapping opens the whole poster full screen.
  Widget _buildQrImage() {
    final url = _qr!.imageUrl;
    if (url == null) {
      return SizedBox(
        height: 300.h,
        child: const Center(child: Icon(Icons.qr_code_2, size: 64)),
      );
    }
    return GestureDetector(
      onTap: () => _openQrFullScreen(url),
      child: AspectRatio(
        aspectRatio: (_cropWidth * _posterAspect) / _cropHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = constraints.maxWidth / _cropWidth;
            final imageHeight = imageWidth / _posterAspect;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -imageWidth * _cropLeft,
                    top: -imageHeight * _cropTop,
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.network(
                      url,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder:
                          (context, child, progress) =>
                              progress == null ? child : const SizedBox(),
                      errorBuilder: (context, error, stack) => const SizedBox(),
                    ),
                  ),
                  // Loading / error overlays sized to the visible crop.
                  Positioned.fill(
                    child: Image.network(
                      url,
                      frameBuilder:
                          (context, child, frame, sync) =>
                              frame == null
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : const SizedBox(),
                      errorBuilder:
                          (context, error, stack) => Center(
                            child: TextButton.icon(
                              onPressed: _startUpi,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reload QR'),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openQrFullScreen(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.white,
      builder:
          (dialogContext) => GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  height: double.infinity,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildUpiSuccess() {
    final reference = _instructions.paymentCollection?.transactionReference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
        SizedBox(height: 8.h),
        CustomText(
          text: 'Payment Received',
          textAlign: TextAlign.center,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: Colors.green,
        ),
        if (reference != null) ...[
          SizedBox(height: 4.h),
          CustomText(
            text: 'Ref: $reference',
            textAlign: TextAlign.center,
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ],
        SizedBox(height: 20.h),
        _primaryButton(
          label: 'Continue to Delivery',
          color: Colors.green,
          onPressed: () => Navigator.of(context).pop(CodPaymentOutcome.upiPaid),
        ),
      ],
    );
  }

  Widget _buildUpiError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 48.sp, color: AppColors.errorColor),
        SizedBox(height: 8.h),
        CustomText(
          text: message,
          textAlign: TextAlign.center,
          fontSize: 13.sp,
        ),
        SizedBox(height: 16.h),
        _primaryButton(
          label: 'Retry',
          color: AppColors.primaryColor,
          onPressed: _startUpi,
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () {
            _stopTimers();
            setState(() {
              _qrError = null;
              _step = _Step.cash;
            });
          },
          child: const Text('Collect cash instead'),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: CustomText(
          text: label,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
