class TreatmentModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String title;
  final String status;
  final String startDate;
  final String? estimatedEndDate;
  final String? actualEndDate;
  final double totalFee;
  final String? discountType;
  final double? discountValue;
  final double finalFee;
  final String? notes;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  final double? paidAmount;
  final double? balance;
  final String? patientName;

  const TreatmentModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.title,
    required this.status,
    required this.startDate,
    this.estimatedEndDate,
    this.actualEndDate,
    required this.totalFee,
    this.discountType,
    this.discountValue,
    required this.finalFee,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.paidAmount,
    this.balance,
    this.patientName,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) =>
        v != null ? double.tryParse(v.toString()) : null;

    return TreatmentModel(
      id: json['id']?.toString() ?? '',
      clinicId: json['clinicId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      estimatedEndDate: json['estimatedEndDate'] as String?,
      actualEndDate: json['actualEndDate'] as String?,
      totalFee: parseDouble(json['totalFee']) ?? 0,
      discountType: json['discountType'] as String?,
      discountValue: parseDouble(json['discountValue']),
      finalFee: parseDouble(json['finalFee']) ?? 0,
      notes: json['notes'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      paidAmount: parseDouble(json['paidAmount']),
      balance: parseDouble(json['balance']),
      patientName: json['patientName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'title': title,
      'status': status,
      'startDate': startDate,
      if (estimatedEndDate != null) 'estimatedEndDate': estimatedEndDate,
      if (actualEndDate != null) 'actualEndDate': actualEndDate,
      'totalFee': totalFee,
      if (discountType != null) 'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      'finalFee': finalFee,
      if (notes != null) 'notes': notes,
    };
  }

  double get finalFeeDouble => finalFee;
  double get paidAmountDouble => paidAmount ?? 0;
  double get balanceDouble => balance ?? (finalFee - paidAmountDouble);
  String get treatmentTitle => title;

  bool get isFullyPaid => balanceDouble <= 0;

  String get statusDisplay {
    switch (status) {
      case 'planned':
        return 'Planned';
      case 'ongoing':
        return 'Ongoing';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
