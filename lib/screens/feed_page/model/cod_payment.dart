/// Response shape of the rider COD payment endpoints
/// (`payment-instructions` and `payment-qr`).
class CodPaymentInstructions {
  final bool required;
  final String paymentStatus;
  final String amount;
  final String currency;
  final List<String> acceptedMethods;
  final String? upiId;
  final RazorpayQr? razorpayQr;
  final PaymentCollection? paymentCollection;

  CodPaymentInstructions({
    required this.required,
    required this.paymentStatus,
    required this.amount,
    required this.currency,
    required this.acceptedMethods,
    this.upiId,
    this.razorpayQr,
    this.paymentCollection,
  });

  bool get isCompleted => paymentStatus.toLowerCase() == 'completed';
  bool get acceptsUpi => acceptedMethods.contains('upi');
  bool get acceptsCash =>
      acceptedMethods.isEmpty || acceptedMethods.contains('cash');

  factory CodPaymentInstructions.fromJson(Map<String, dynamic> json) {
    return CodPaymentInstructions(
      required: json['required'] == true,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'INR',
      acceptedMethods:
          (json['accepted_methods'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const ['cash'],
      upiId: json['upi_id']?.toString(),
      razorpayQr:
          json['razorpay_qr'] is Map<String, dynamic>
              ? RazorpayQr.fromJson(json['razorpay_qr'])
              : null,
      paymentCollection:
          json['payment_collection'] is Map<String, dynamic>
              ? PaymentCollection.fromJson(json['payment_collection'])
              : null,
    );
  }
}

class RazorpayQr {
  final String? id;
  final String? imageUrl;
  final String status;
  final DateTime? expiresAt;

  RazorpayQr({this.id, this.imageUrl, required this.status, this.expiresAt});

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isExpired =>
      status.toLowerCase() == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  factory RazorpayQr.fromJson(Map<String, dynamic> json) {
    return RazorpayQr(
      id: json['id']?.toString(),
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '')
          ?.toLocal(),
    );
  }
}

class PaymentCollection {
  final String? status;
  final String? method;
  final String? transactionReference;
  final String? confirmedAt;

  PaymentCollection({
    this.status,
    this.method,
    this.transactionReference,
    this.confirmedAt,
  });

  factory PaymentCollection.fromJson(Map<String, dynamic> json) {
    return PaymentCollection(
      status: json['status']?.toString(),
      method: json['method']?.toString(),
      transactionReference: json['transaction_reference']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
    );
  }
}
