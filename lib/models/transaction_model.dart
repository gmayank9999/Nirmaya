class TransactionModel {
  final String id;
  final String clinicId;
  final String treatmentId;
  final String patientId;
  final String? visitId;
  final String type;
  final String amount;
  final String? paymentMode;
  final String? referenceId;
  final String? notes;
  final String transactionDate;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  // Enriched
  final String? patientName;
  final String? treatmentTitle;

  const TransactionModel({
    required this.id,
    required this.clinicId,
    required this.treatmentId,
    required this.patientId,
    this.visitId,
    required this.type,
    required this.amount,
    this.paymentMode,
    this.referenceId,
    this.notes,
    required this.transactionDate,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.treatmentTitle,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      treatmentId: json['treatmentId'] as String,
      patientId: json['patientId'] as String,
      visitId: json['visitId'] as String?,
      type: json['type'] as String,
      amount: json['amount']?.toString() ?? '0',
      paymentMode: json['paymentMode'] as String?,
      referenceId: json['referenceId'] as String?,
      notes: json['notes'] as String?,
      transactionDate: json['createdAt'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      patientName: json['patientName'] as String?,
      treatmentTitle: json['treatmentTitle'] as String?,
    );
  }

  double get amountDouble => double.tryParse(amount) ?? 0;

  String get paymentModeDisplay {
    switch (paymentMode) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'bank':
        return 'Bank Transfer';
      default:
        return paymentMode ?? '-';
    }
  }

  String get typeDisplay {
    switch (type) {
      case 'payment':
        return 'Payment';
      case 'refund':
        return 'Refund';
      case 'adjustment':
        return 'Adjustment';
      default:
        return type;
    }
  }
}
