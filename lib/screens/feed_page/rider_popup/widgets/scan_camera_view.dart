import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nagpur_rider/utils/services/scan_beep_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// First non-empty barcode value in [capture], or null.
String? firstBarcodeValue(BarcodeCapture capture) {
  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}

/// Live camera for the bag scanner: everything outside the scan window is
/// dimmed, the window has corner marks and a red aiming line, and only
/// barcodes inside the window are read. Same look as the seller app.
class ScanCameraView extends StatelessWidget {
  final MobileScannerController? controller;
  final void Function(BarcodeCapture capture)? onDetect;
  final VoidCallback onManualEntry;
  final String hint;

  /// Pinned to the bottom of the camera, e.g. the result of the last scan.
  final Widget? footer;

  const ScanCameraView({
    super.key,
    this.controller,
    this.onDetect,
    required this.onManualEntry,
    this.hint = "Point the camera at the bag's barcode.",
    this.footer,
  });

  /// Scan window for a camera of [size]: wide and short like a barcode,
  /// a little above the middle.
  static Rect windowFor(Size size) {
    final width = math.min(size.width * 0.82, 420.0);
    final height = math.min(width * 0.62, size.height * 0.5);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: width,
      height: height,
    );
  }

  /// Beeps for every code the camera reads, even one the panel then
  /// rejects, and hands the capture on.
  void _onDetect(BarcodeCapture capture) {
    final code = firstBarcodeValue(capture);
    if (code != null) ScanBeepService().onCodeRead(code);
    onDetect?.call(capture);
  }

  @override
  Widget build(BuildContext context) {
    // Load the beep while the camera starts so the first scan isn't silent.
    ScanBeepService().preload();
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest);
        final overlays = <Widget>[
          IgnorePointer(
            child: CustomPaint(painter: _ScanWindowPainter(window)),
          ),
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Center(child: _ScanHint(hint)),
          ),
          if (controller != null)
            Positioned(
              top: window.bottom + 8,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton.filledTonal(
                  tooltip: 'Flashlight',
                  onPressed: controller!.toggleTorch,
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
              ),
            ),
        ];
        return ClipRect(
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  scanWindow: window,
                  errorBuilder:
                      (context, error) => ScanCameraError(
                        permissionDenied:
                            error.errorCode ==
                            MobileScannerErrorCode.permissionDenied,
                        onManualEntry: onManualEntry,
                      ),
                ),
                // No aiming marks over the camera error and its buttons.
                if (controller == null)
                  ...overlays
                else
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller!,
                    builder:
                        (context, state, _) =>
                            state.error != null
                                ? const SizedBox.shrink()
                                : Stack(
                                  fit: StackFit.expand,
                                  children: overlays,
                                ),
                  ),
                if (footer != null)
                  Positioned(left: 12, right: 12, bottom: 12, child: footer!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanHint extends StatelessWidget {
  final String text;

  const _ScanHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanWindowPainter extends CustomPainter {
  final Rect window;

  const _ScanWindowPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(window, const Radius.circular(4));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final corner =
        Paint()
          ..color = const Color(0xFF2F6BFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.square;
    const arm = 24.0;
    final w = window;
    for (final (point, dx, dy) in [
      (w.topLeft, 1.0, 1.0),
      (w.topRight, -1.0, 1.0),
      (w.bottomLeft, 1.0, -1.0),
      (w.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(point, point.translate(arm * dx, 0), corner)
        ..drawLine(point, point.translate(0, arm * dy), corner);
    }

    canvas.drawLine(
      Offset(w.left + 10, w.center.dy),
      Offset(w.right - 10, w.center.dy),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ScanWindowPainter oldDelegate) =>
      oldDelegate.window != window;
}

class ScanCameraError extends StatelessWidget {
  final bool permissionDenied;
  final VoidCallback onManualEntry;

  const ScanCameraError({
    super.key,
    required this.permissionDenied,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70),
            const SizedBox(height: 10),
            Text(
              permissionDenied
                  ? 'Camera access is off. Allow it in Settings, or enter the code manually.'
                  : "The camera isn't available. Enter the code manually.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (permissionDenied)
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Open settings'),
                  ),
                TextButton(
                  onPressed: onManualEntry,
                  child: const Text('Enter manually'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
