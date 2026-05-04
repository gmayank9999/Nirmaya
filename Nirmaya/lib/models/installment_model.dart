class InstallmentModel {
  final String id;
  final String clinicId;
  final String treatmentId;
  final String planName;
  final int totalInstallments;
  final String installmentAmount;
  final String dueDate;
  final String? paidDate;
  final String status;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  const InstallmentModel({
    required this.id,
    required this.clinicId,
    required this.treatmentId,
    required this.planName,
    required this.totalInstallments,
    required this.installmentAmount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      treatmentId: json['treatmentId'] as String,
      planName: json['planName'] as String? ?? '',
      totalInstallments: json['totalInstallments'] as int? ?? 0,
      installmentAmount: json['installmentAmount']?.toString() ?? '0',
      dueDate: json['dueDate'] as String? ?? '',
      paidDate: json['paidDate'] as String?,
      status: json['status'] as String? ?? 'pending',
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  double get installmentAmountDouble => double.tryParse(installmentAmount) ?? 0;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      default:
        return status;
    }
  }
}
