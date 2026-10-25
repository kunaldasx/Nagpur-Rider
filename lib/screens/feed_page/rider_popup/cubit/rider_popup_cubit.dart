import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';

part 'rider_popup_state.dart';

/// Result of a bag scan, for the scan panel to react to.
enum BagScanOutcome { scanned, completed, alreadyScanned, wrongBag, failed }

/// Drives the rider order popup, the rider version of the seller's
/// incoming-order popup:
///
/// 1. [fetch] — orders with a seller bag are offered in the popup while the
///    rider is online. The offer stays until accepted or withdrawn.
/// 2. Once accepted (here, from the orders list via [openAccepted], or from
///    order details) the popup asks for the assigned bag(s) to be scanned:
///    [scanBag]. The server then moves the bag's preparing items to
///    `collected`.
/// 3. [finishPickup] — every bag scanned, the rider leaves for delivery.
///
/// Accepted orders waiting for a scan are saved on the device so the popup
/// comes back after a restart.
class RiderPopupCubit extends Cubit<RiderPopupState> {
  final RiderPopupRepo _repo;
  final Future<void> Function(int) _stopAlert;

  RiderPopupCubit({RiderPopupRepo? repo, Future<void> Function(int)? stopAlert})
    : _repo = repo ?? RiderPopupRepo(),
      _stopAlert = stopAlert ?? OrderAlertBridge.stopAlert,
      super(const RiderPopupState());

  static const _boxName = 'RiderPopupBox';
  static const _acceptedKey = 'acceptedOrders';

  bool _isFetching = false;
  bool _restored = false;
  int _generation = 0;

  /// Suppresses late fetch/accept responses after a backend withdrawal.
  final Set<int> _withdrawn = {};

  /// Orders already offered, so only a new one brings a minimized popup back.
  final Set<int> _offered = {};

  /// Last copy of each order seen in the list. The detail endpoint may not
  /// carry the bags, so they're taken from here after accepting.
  final Map<int, RiderPopupOrder> _lastSeen = {};

  static bool get _isLoggedIn => (Global.userToken ?? '').trim().isNotEmpty;

  Future<void> fetch() async {
    if (!_isLoggedIn) {
      if (state != const RiderPopupState() || _restored) clear();
      return;
    }
    if (_isFetching || state.isBusy) return;
    _isFetching = true;
    final generation = _generation;
    try {
      if (!_restored) {
        _restored = true;
        await _restore(generation);
      }
      final online = await Global.getDeliveryBoyStatus() == true;
      List<RiderPopupOrder>? available;
      if (online) {
        try {
          available = await _repo.availableOrders();
        } catch (e) {
          // Keep the last list: a dropped connection mustn't hide orders.
          debugPrint('[RiderPopup] fetch failed: $e');
        }
      } else {
        available = const [];
      }
      if (isClosed || generation != _generation || available == null) return;
      _publishAvailable(available);
    } finally {
      _isFetching = false;
    }
  }

  void _publishAvailable(List<RiderPopupOrder> orders) {
    for (final o in orders) {
      _lastSeen[o.id] = o;
    }
    final acceptedIds = state.accepted.map((o) => o.id).toSet();
    final available =
        orders
            .where(
              (o) =>
                  !_withdrawn.contains(o.id) &&
                  !acceptedIds.contains(o.id) &&
                  o.hasPreparingItem,
            )
            .toList()
          ..sort(_oldestFirst);
    // The card on screen stays on top until the rider acts on it.
    final current = state.available.firstOrNull?.id;
    final index = available.indexWhere((o) => o.id == current);
    if (index > 0) available.insert(0, available.removeAt(index));

    final hasNew = available.any((o) => !_offered.contains(o.id));
    _offered.addAll(available.map((o) => o.id));
    emit(
      state.copyWith(
        available: available,
        minimized: hasNew ? false : state.minimized,
        // Drop an accept error for an order that's gone.
        clearError:
            state.failedOrderId != null &&
            !state.queue.any((o) => o.id == state.failedOrderId),
      ),
    );
  }

  static int _oldestFirst(RiderPopupOrder a, RiderPopupOrder b) {
    final at = a.createdAt, bt = b.createdAt;
    if (at == null || bt == null) return a.id.compareTo(b.id);
    return at.compareTo(bt);
  }

  /// Brings back accepted orders still waiting for a bag scan, unless the
  /// server says they were picked up, delivered or cancelled since.
  Future<void> _restore(int generation) async {
    final saved = await _load();
    if (saved.isEmpty) return;
    final kept = <RiderPopupOrder>[];
    for (final order in saved) {
      try {
        final fresh = order.keepBagsIn(await _repo.orderDetail(order.id));
        if (fresh.isClosed || !fresh.hasBag || fresh.allBagsPickedUp) continue;
        kept.add(fresh);
      } catch (e) {
        // Offline: keep it rather than lose the required scan.
        debugPrint('[RiderPopup] restore check failed for ${order.id}: $e');
        kept.add(order);
      }
    }
    if (isClosed || generation != _generation) return;
    emit(state.copyWith(accepted: _mergeAccepted(kept)));
    _save();
  }

  List<RiderPopupOrder> _mergeAccepted(List<RiderPopupOrder> orders) {
    final byId = {for (final o in state.accepted) o.id: o};
    for (final o in orders) {
      byId[o.id] = o;
    }
    return byId.values.toList();
  }

  /// Accepts [order] from the popup. On success it stays in the popup for
  /// the bag scan. Returns true when accepted.
  Future<bool> accept(RiderPopupOrder order) async {
    if (state.isBusy) return false;
    final generation = _generation;
    emit(state.copyWith(acceptingOrderId: order.id, clearError: true));
    try {
      await _repo.accept(order.id);
    } catch (e) {
      if (!isClosed && generation == _generation) {
        final refused =
            e is OfferAcceptException &&
            e.result.outcome != AlertAcceptOutcome.retry;
        if (refused) {
          _withdrawn.add(order.id);
          await _stopAlert(order.id);
          if (isClosed || generation != _generation) return false;
        }
        emit(
          state.copyWith(
            clearAccepting: true,
            available:
                refused
                    ? state.available.where((o) => o.id != order.id).toList()
                    : null,
            failedOrderId: order.id,
            errorMessage: e.toString(),
          ),
        );
      }
      return false;
    }
    if (isClosed ||
        generation != _generation ||
        _withdrawn.contains(order.id)) {
      return false;
    }

    // The detail carries the bag state as it is now.
    var accepted = order;
    try {
      accepted = order.keepBagsIn(await _repo.orderDetail(order.id));
    } catch (e) {
      debugPrint('[RiderPopup] detail after accept failed: $e');
    }
    if (isClosed ||
        generation != _generation ||
        _withdrawn.contains(order.id)) {
      return false;
    }
    emit(
      state.copyWith(
        clearAccepting: true,
        accepted: _mergeAccepted([accepted]),
        available: state.available.where((o) => o.id != order.id).toList(),
        minimized: false,
      ),
    );
    _save();
    return true;
  }

  /// A backend cancellation removes an offer even if a fetch is in flight.
  Future<void> offerWithdrawn(
    int orderId,
    String reason, {
    String? message,
  }) async {
    final generation = _generation;
    _withdrawn.add(orderId);
    final accepted = state.accepted.where((o) => o.id == orderId).firstOrNull;
    emit(
      state.copyWith(
        available: state.available.where((o) => o.id != orderId).toList(),
        clearAccepting: state.acceptingOrderId == orderId,
        failedOrderId: orderId,
        errorMessage:
            message ??
            (reason == 'reassigned' ? 'Order reassigned' : 'Order cancelled'),
      ),
    );
    await _stopAlert(orderId);
    if (accepted == null || accepted.allBagsPickedUp) return;
    try {
      final detail = await _repo.orderDetail(orderId);
      if (isClosed || generation != _generation) return;
      // The previous assignment is known from acceptance/detail. The spec's
      // detail example omits it; a withdrawal is authoritative in that case.
      final previousRider = accepted.raw['delivery_boy_id'];
      final nextRider = detail.raw['delivery_boy_id'];
      if (detail.isClosed ||
          nextRider == null ||
          previousRider == null ||
          '$nextRider' != '$previousRider') {
        _removeAccepted(orderId, keepError: true);
      }
    } catch (e) {
      debugPrint('[RiderPopup] withdrawal detail failed: $e');
      if (!isClosed && generation == _generation) {
        // A confirmed withdrawal cannot leave a scannable stale card.
        _removeAccepted(orderId, keepError: true);
      }
    }
  }

  /// Opens the bag scan for the already accepted order [orderId], e.g. right
  /// after accepting it from the orders list, or when the rider tries to
  /// collect items before scanning. Returns false (and opens nothing) when
  /// the order has no bag left to scan, or couldn't be loaded.
  ///
  /// [stayOnScreen]: the caller refreshes itself after the scan, so the
  /// popup shouldn't open the order details when the rider moves on.
  Future<bool> openAccepted(int orderId, {bool stayOnScreen = false}) async {
    if (!_isLoggedIn) return false;
    final generation = _generation;
    // Bags may only be known from the orders list.
    final known =
        state.queue.where((o) => o.id == orderId).firstOrNull ??
        _lastSeen[orderId];
    RiderPopupOrder order;
    try {
      final fresh = await _repo.orderDetail(orderId);
      order = known?.keepBagsIn(fresh) ?? fresh;
    } catch (e) {
      debugPrint('[RiderPopup] open $orderId failed: $e');
      if (known == null) return false;
      order = known;
    }
    if (isClosed || generation != _generation) return false;
    if (!order.hasBag || order.allBagsPickedUp) return false;
    // Put it first so it's the one on screen.
    emit(
      state.copyWith(
        accepted: [order, ...state.accepted.where((o) => o.id != orderId)],
        available: state.available.where((o) => o.id != orderId).toList(),
        minimized: false,
        stayOnScreenIds:
            stayOnScreen
                ? {...state.stayOnScreenIds, orderId}
                : ({...state.stayOnScreenIds}..remove(orderId)),
      ),
    );
    _save();
    return true;
  }

  /// Re-reads the bag state of accepted [order] from the server, so a bag
  /// scanned on another device or reassigned by the seller shows correctly.
  Future<void> refreshAccepted(RiderPopupOrder order) async {
    final generation = _generation;
    try {
      final detail = await _repo.orderDetail(order.id);
      if (isClosed || generation != _generation || state.isBusy) return;
      final current = state.accepted.where((o) => o.id == order.id).firstOrNull;
      if (current == null) return;
      final fresh = current.keepBagsIn(detail);
      if (fresh.isClosed) {
        _removeAccepted(order.id);
        return;
      }
      emit(
        state.copyWith(
          accepted: [
            for (final o in state.accepted) o.id == order.id ? fresh : o,
          ],
        ),
      );
      _save();
    } catch (e) {
      debugPrint('[RiderPopup] refresh ${order.id} failed: $e');
    }
  }

  /// Checks [code] against the bags assigned to [order], then has the
  /// server mark the matching bag picked up. Returns the outcome and the
  /// message to show.
  Future<(BagScanOutcome, String)> scanBag(
    RiderPopupOrder order,
    String code,
  ) async {
    code = code.trim();
    if (state.isBusy) {
      return (BagScanOutcome.failed, 'Please wait for the last scan.');
    }
    final current =
        state.accepted.where((o) => o.id == order.id).firstOrNull ?? order;
    if (code.isEmpty) {
      return (BagScanOutcome.wrongBag, 'Enter the bag barcode');
    }
    final pending =
        current.baggedSellerOrders.where((s) => !s.bag!.isPickedUp).toList();
    final match =
        current.baggedSellerOrders
            .where((s) => s.bag!.matches(code))
            .firstOrNull;
    // The server withholds barcodes it doesn't want typed in: then it alone
    // checks the scanned code against the assigned bag.
    final serverChecks = pending.any((s) => !s.bag!.hasKnownBarcode);
    // Only the bag the seller assigned counts, never a freeform one.
    if (match == null && !serverChecks) {
      final expected = current.baggedSellerOrders
          .where((s) => !s.bag!.isPickedUp)
          .map((s) => s.bag!.barcode)
          .join(', ');
      return (
        BagScanOutcome.wrongBag,
        'This bag is not assigned to this order. Scan $expected.',
      );
    }
    if (match != null && match.bag!.isPickedUp) {
      return (
        BagScanOutcome.alreadyScanned,
        'Bag ${match.bag!.barcode} is already scanned.',
      );
    }

    final generation = _generation;
    emit(state.copyWith(scanningOrderId: order.id, clearError: true));
    try {
      final result = await _repo.scanBag(order.id, match?.bag!.barcode ?? code);
      if (isClosed || generation != _generation) {
        return (BagScanOutcome.failed, '');
      }
      final sellerOrderId =
          result.sellerOrderId ??
          match?.id ??
          (pending.length == 1 ? pending.single.id : null);
      var updated =
          sellerOrderId == null
              ? current
              : current.withBag(sellerOrderId, result.bag);
      // Can't tell which bag it was: ask the server for the bag states.
      if (sellerOrderId == null || !updated.allBagsPickedUp) {
        try {
          updated = updated.keepBagsIn(await _repo.orderDetail(order.id));
        } catch (e) {
          debugPrint('[RiderPopup] detail after scan failed: $e');
        }
      }
      final completed = updated.allBagsPickedUp;
      emit(
        state.copyWith(
          clearScanning: true,
          accepted: [
            for (final o in state.accepted) o.id == order.id ? updated : o,
          ],
          pickupVersion: completed ? state.pickupVersion + 1 : null,
          lastPickedUpOrderId: completed ? order.id : null,
        ),
      );
      _save();
      return completed
          ? (BagScanOutcome.completed, 'All bags picked up.')
          : (
            BagScanOutcome.scanned,
            'Bag ${result.bag.barcode.isNotEmpty ? result.bag.barcode : code} '
                'picked up. Scan the next bag.',
          );
    } catch (e) {
      if (!isClosed && generation == _generation) {
        emit(state.copyWith(clearScanning: true));
      }
      return (BagScanOutcome.failed, e.toString());
    }
  }

  /// Every bag of [order] is scanned: the order leaves the popup. Returns
  /// true when the caller should open the order to continue the delivery.
  bool finishPickup(RiderPopupOrder order) {
    final stay = state.stayOnScreenIds.contains(order.id);
    _removeAccepted(order.id);
    return !stay;
  }

  void _removeAccepted(int orderId, {bool keepError = false}) {
    emit(
      state.copyWith(
        accepted: state.accepted.where((o) => o.id != orderId).toList(),
        stayOnScreenIds: {...state.stayOnScreenIds}..remove(orderId),
        clearError: !keepError && state.failedOrderId == orderId,
      ),
    );
    _save();
  }

  void setMinimized(bool value) {
    if (!isClosed && state.minimized != value) {
      emit(state.copyWith(minimized: value));
    }
  }

  Future<List<RiderPopupOrder>> _load() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_acceptedKey);
      if (raw is! String || raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      return [
        if (list is List)
          for (final json in list)
            if (RiderPopupOrder.tryParse(json) case final order?) order,
      ];
    } catch (e) {
      debugPrint('[RiderPopup] load failed: $e');
      return const [];
    }
  }

  Future<void>? _pendingSave;

  @override
  Future<void> close() {
    final closing = super.close();
    final saving = _pendingSave;
    return saving == null ? closing : saving.then((_) => closing);
  }

  Future<void> _save() {
    final orders = [for (final o in state.accepted) o.raw];
    return _pendingSave = (_pendingSave ?? Future<void>.value()).then(
      (_) => _persist(orders),
    );
  }

  Future<void> _persist(List<Map<String, dynamic>> orders) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_acceptedKey, jsonEncode(orders));
    } catch (e) {
      debugPrint('[RiderPopup] save failed: $e');
    }
  }

  /// Called on logout.
  void clear() {
    _generation++;
    _restored = false;
    _withdrawn.clear();
    _offered.clear();
    _lastSeen.clear();
    emit(const RiderPopupState());
    _save();
  }
}
