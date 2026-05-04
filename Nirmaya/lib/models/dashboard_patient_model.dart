class DashboardPatientModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int? age;
  final String? gender;
  final bool hasIdProof;
  final String createdAt;
  final String updatedAt;
  final int treatmentCount;
  final int ongoingTreatmentCount;
  final int completedTreatmentCount;
  final String? lastVisitDate;
  final double totalFee;
  final double paidAmount;
  final double balance;

  const DashboardPatientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.age,
    this.gender,
    required this.hasIdProof,
    required this.createdAt,
    required this.updatedAt,
    required this.treatmentCount,
    required this.ongoingTreatmentCount,
    required this.completedTreatmentCount,
    this.lastVisitDate,
    required this.totalFee,
    required this.paidAmount,
    required this.balance,
  });

  factory DashboardPatientModel.fromJson(Map<String, dynamic> json) {
    return DashboardPatientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      hasIdProof: json['hasIdProof'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      treatmentCount: int.tryParse(json['treatmentCount'].toString()) ?? 0,
      ongoingTreatmentCount:
          int.tryParse(json['ongoingTreatmentCount'].toString()) ?? 0,
      completedTreatmentCount:
          int.tryParse(json['completedTreatmentCount'].toString()) ?? 0,
      lastVisitDate: json['lastVisitDate'] as String?,
      totalFee: double.tryParse(json['totalFee'].toString()) ?? 0,
      paidAmount: double.tryParse(json['paidAmount'].toString()) ?? 0,
      balance: double.tryParse(json['balance'].toString()) ?? 0,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
