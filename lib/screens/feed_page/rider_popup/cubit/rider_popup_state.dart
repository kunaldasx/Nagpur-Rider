part of 'rider_popup_cubit.dart';

class RiderPopupState extends Equatable {
  /// Accepted orders whose bags the rider still has to scan (or has just
  /// scanned and not yet left the popup for delivery). Oldest first.
  final List<RiderPopupOrder> accepted;

  /// Unassigned orders with a seller bag, offered to the rider. Oldest first.
  final List<RiderPopupOrder> available;

  /// The rider tucked the popup away (e.g. to ride to the store). Accepted
  /// orders then wait behind a small "Scan bag" button.
  final bool minimized;

  final int? acceptingOrderId;
  final int? scanningOrderId;
  final int? failedOrderId;
  final String? errorMessage;

  /// Accepted orders opened from a screen that refreshes itself, so leaving
  /// the popup after the scan shouldn't open the order again.
  final Set<int> stayOnScreenIds;

  /// Bumped every time a bag scan completes an order's pickup, with that
  /// order's id, so open order screens can reload.
  final int pickupVersion;
  final int? lastPickedUpOrderId;

  const RiderPopupState({
    this.accepted = const [],
    this.available = const [],
    this.minimized = false,
    this.acceptingOrderId,
    this.scanningOrderId,
    this.failedOrderId,
    this.errorMessage,
    this.stayOnScreenIds = const {},
    this.pickupVersion = 0,
    this.lastPickedUpOrderId,
  });

  /// Accepted orders first (they block pickup), then new ones.
  List<RiderPopupOrder> get queue => [...accepted, ...available];

  RiderPopupOrder? get top => queue.firstOrNull;

  bool isAccepted(RiderPopupOrder order) =>
      accepted.any((o) => o.id == order.id);

  /// New orders waiting for Accept or Skip — the phone rings while any exist.
  bool get hasUnaccepted => available.isNotEmpty;

  /// The full-screen popup is up.
  bool get isShown => queue.isNotEmpty && !minimized;

  /// The popup is tucked away but an accepted order still needs its bag.
  bool get showsReminder => minimized && accepted.isNotEmpty;

  bool get isBusy => acceptingOrderId != null || scanningOrderId != null;

  RiderPopupState copyWith({
    List<RiderPopupOrder>? accepted,
    List<RiderPopupOrder>? available,
    bool? minimized,
    int? acceptingOrderId,
    int? scanningOrderId,
    int? failedOrderId,
    String? errorMessage,
    Set<int>? stayOnScreenIds,
    int? pickupVersion,
    int? lastPickedUpOrderId,
    bool clearAccepting = false,
    bool clearScanning = false,
    bool clearError = false,
  }) {
    return RiderPopupState(
      accepted: accepted ?? this.accepted,
      available: available ?? this.available,
      minimized: minimized ?? this.minimized,
      acceptingOrderId:
          clearAccepting ? null : (acceptingOrderId ?? this.acceptingOrderId),
      scanningOrderId:
          clearScanning ? null : (scanningOrderId ?? this.scanningOrderId),
      failedOrderId: clearError ? null : (failedOrderId ?? this.failedOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      stayOnScreenIds: stayOnScreenIds ?? this.stayOnScreenIds,
      pickupVersion: pickupVersion ?? this.pickupVersion,
      lastPickedUpOrderId: lastPickedUpOrderId ?? this.lastPickedUpOrderId,
    );
  }

  @override
  List<Object?> get props => [
    accepted,
    available,
    minimized,
    acceptingOrderId,
    scanningOrderId,
    failedOrderId,
    errorMessage,
    stayOnScreenIds,
    pickupVersion,
    lastPickedUpOrderId,
  ];
}
