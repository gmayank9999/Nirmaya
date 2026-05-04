class FollowupModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String treatmentId;
  final String scheduledDate;
  final String status;
  final String? notes;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  // Enriched
  final String? patientName;
  final String? patientPhone;
  final String? treatmentTitle;

  const FollowupModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.treatmentId,
    required this.scheduledDate,
    required this.status,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.patientPhone,
    this.treatmentTitle,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      patientId: json['patientId'] as String,
      treatmentId: json['treatmentId'] as String,
      scheduledDate: json['scheduledDate'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      patientName: json['patientName'] as String?,
      patientPhone: json['patientPhone'] as String?,
      treatmentTitle: json['treatmentTitle'] as String?,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'missed':
        return 'Missed';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
    }
  }
}
