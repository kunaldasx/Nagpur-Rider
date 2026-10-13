import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/widgets/common.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/widgets/scan_camera_view.dart';

/// Shown full screen once the rider has accepted an order. The rider scans
/// the bag(s) the seller assigned (camera or typed), the server moves their
/// items to `collected`, then "Proceed to delivery" appears.
class BagScanPanel extends StatefulWidget {
  final RiderPopupOrder order;
  final bool isScanning;

  /// Tucks the popup away, e.g. while riding to the store.
  final VoidCallback onMinimize;

  /// Opens the route to the store.
  final VoidCallback onNavigateToStore;

  /// Every bag scanned and the rider moves on.
  final VoidCallback onProceed;

  const BagScanPanel({
    super.key,
    required this.order,
    required this.isScanning,
    required this.onMinimize,
    required this.onNavigateToStore,
    required this.onProceed,
  });

  @override
  State<BagScanPanel> createState() => _BagScanPanelState();
}

class _BagScanPanelState extends State<BagScanPanel> {
  /// The camera reports a barcode many times a second while it's in view.
  /// The same code is ignored until it has been out of view this long.
  static const _repeatDelay = Duration(milliseconds: 1500);

  MobileScannerController? _scanner;
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  /// The panel replaces the order card right where its Accept button was,
  /// so a double tap on Accept mustn't land on this panel's buttons.
  final _shownAt = DateTime.now();
  static const _tapGuard = Duration(milliseconds: 800);

  /// [action], unless the panel has only just appeared.
  VoidCallback _guarded(VoidCallback action) => () {
    if (DateTime.now().difference(_shownAt) < _tapGuard) return;
    action();
  };
  bool _manual = false;
  String? _message;
  bool _success = false;

  String? _lastCode;
  DateTime? _lastCodeAt;

  RiderPopupCubit get _cubit => context.read<RiderPopupCubit>();

  bool get _completed => widget.order.allBagsPickedUp;

  @override
  void initState() {
    super.initState();
    _syncCamera();
    // Pick up a bag reassigned by the seller or scanned elsewhere.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.refreshAccepted(widget.order);
    });
  }

  @override
  void didUpdateWidget(covariant BagScanPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCamera();
  }

  @override
  void dispose() {
    _scanner?.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Keeps the camera running only while there's a bag to scan with it.
  void _syncCamera() {
    if (!_manual && !_completed) {
      _scanner ??= MobileScannerController(formats: const [BarcodeFormat.all]);
    } else {
      _scanner?.dispose();
      _scanner = null;
    }
  }

  void _setManual(bool manual) {
    _manual = manual;
    // autofocus alone doesn't take inside the popup's own Overlay.
    if (manual) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _manual) _codeFocus.requestFocus();
      });
    }
    _codeController.clear();
    _lastCode = null;
    _syncCamera();
    setState(() => _message = null);
  }

  void _onDetect(BarcodeCapture capture) {
    final code = firstBarcodeValue(capture);
    if (code == null || !mounted || _manual || widget.isScanning) return;
    final now = DateTime.now();
    final repeated =
        code == _lastCode && now.difference(_lastCodeAt!) < _repeatDelay;
    _lastCodeAt = now;
    if (repeated) return;
    _lastCode = code;
    _scan(code);
  }

  Future<void> _scan(String code) async {
    code = code.trim();
    if (code.isEmpty) {
      setState(() {
        _success = false;
        _message = 'Enter the bag barcode';
      });
      return;
    }
    final (outcome, message) = await _cubit.scanBag(widget.order, code);
    if (!mounted) return;
    final ok =
        outcome == BagScanOutcome.scanned ||
        outcome == BagScanOutcome.completed;
    if (ok) {
      HapticFeedback.mediumImpact();
      _codeController.clear();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() {
      _success = ok;
      _message = message.isEmpty ? null : message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return ColoredBox(
      color: popupSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            order: order,
            completed: _completed,
            onMinimize: widget.onMinimize,
          ),
          if (!_completed)
            SizedBox(
              height: _manual ? null : 260,
              child: _manual ? _buildManual() : _buildCamera(),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              children: [
                if (_completed) const _CompletedBanner(),
                PopupSection(
                  title:
                      order.baggedSellerOrders.length == 1
                          ? 'ASSIGNED BAG'
                          : 'ASSIGNED BAGS',
                  child: Column(
                    children: [
                      for (final s in order.baggedSellerOrders)
                        BagRow(sellerOrder: s),
                    ],
                  ),
                ),
                PopupSection(
                  title: 'STORE / SELLER',
                  child: Column(
                    children: [
                      for (final c in order.pickupContacts)
                        ContactRow(
                          icon: Icons.storefront_outlined,
                          name: c.name,
                          phone: c.phone,
                        ),
                      if (order.pickupContacts.isEmpty)
                        const ContactRow(
                          icon: Icons.storefront_outlined,
                          name: 'No contact available',
                          phone: '',
                        ),
                    ],
                  ),
                ),
                PopupSection(
                  title: 'CUSTOMER',
                  child: ContactRow(
                    icon: Icons.person_outline,
                    name: order.customerName,
                    phone: order.customerPhone,
                    subtitle: order.customerAddress,
                  ),
                ),
                if (order.items.isNotEmpty)
                  PopupSection(
                    title: 'ITEMS',
                    child: Column(
                      children: [
                        for (final item in order.items)
                          PopupItemRow(item: item),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupBottomBar(child: _buildActions()),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return ScanCameraView(
      controller: _scanner,
      onDetect: _onDetect,
      onManualEntry: () => _setManual(true),
      footer:
          widget.isScanning
              ? const _ScanMessage(text: 'Checking bag…', success: true)
              : _message != null
              ? _ScanMessage(text: _message!, success: _success)
              : null,
    );
  }

  Widget _buildManual() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeController,
            focusNode: _codeFocus,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: widget.isScanning ? null : _scan,
            decoration: InputDecoration(
              labelText: 'Bag barcode',
              hintText:
                  order.baggedSellerOrders
                      .where((s) => !s.bag!.isPickedUp)
                      .map((s) => s.bag!.barcode)
                      .where((code) => code.isNotEmpty)
                      .firstOrNull,
              prefixIcon: const Icon(Icons.keyboard_outlined),
              errorText: !_success ? _message : null,
              errorMaxLines: 3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_success && _message != null) ...[
            const SizedBox(height: 6),
            Text(
              _message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  RiderPopupOrder get order => widget.order;

  Widget _buildActions() {
    if (_completed) {
      return PopupPrimaryButton(
        label: 'Proceed to delivery',
        icon: Icons.delivery_dining,
        color: Colors.green.shade600,
        onPressed: _guarded(widget.onProceed),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: PopupOutlinedButton(
            icon: _manual ? Icons.qr_code_scanner : Icons.keyboard_outlined,
            tooltip: _manual ? 'Use camera' : 'Enter code manually',
            onPressed: () => _setManual(!_manual),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              _manual
                  ? PopupPrimaryButton(
                    label: 'Scan bag',
                    icon: Icons.check,
                    isLoading: widget.isScanning,
                    onPressed: () => _scan(_codeController.text),
                  )
                  : PopupPrimaryButton(
                    label: 'Navigate to store',
                    icon: Icons.navigation_outlined,
                    onPressed: _guarded(widget.onNavigateToStore),
                  ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final RiderPopupOrder order;
  final bool completed;
  final VoidCallback onMinimize;

  const _Header({
    required this.order,
    required this.completed,
    required this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? 'Bag picked up' : 'Scan the assigned bag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order #${order.orderNumber}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!completed)
            IconButton(
              tooltip: 'Minimize',
              onPressed: onMinimize,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade600;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: green, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bag verified. The items are marked as collected — you can '
              'head to the customer now.',
              style: TextStyle(color: green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Result of the last scan, pinned over the bottom of the camera.
class _ScanMessage extends StatelessWidget {
  final String text;
  final bool success;

  const _ScanMessage({required this.text, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade700 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
