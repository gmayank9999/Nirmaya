class VisitModel {
  final String id;
  final String clinicId;
  final String treatmentId;
  final String visitDate;
  final String? notes;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  const VisitModel({
    required this.id,
    required this.clinicId,
    required this.treatmentId,
    required this.visitDate,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      treatmentId: json['treatmentId'] as String,
      visitDate: json['visitDate'] as String? ?? '',
      notes: json['notes'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
