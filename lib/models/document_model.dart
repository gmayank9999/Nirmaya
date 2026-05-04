class DocumentModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String? treatmentId;
  final String? visitId;
  final String category;
  final String fileUrl;
  final String? name;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String uploadedBy;
  final bool isDeleted;
  final String createdAt;

  const DocumentModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.treatmentId,
    this.visitId,
    required this.category,
    required this.fileUrl,
    this.name,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedBy,
    required this.isDeleted,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      patientId: json['patientId'] as String,
      treatmentId: json['treatmentId'] as String?,
      visitId: json['visitId'] as String?,
      category: json['category'] as String,
      fileUrl: json['fileUrl'] as String? ?? '',
      name: json['name'] as String?,
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'prescription':
        return 'Prescription';
      case 'report':
        return 'Report';
      case 'cghs':
        return 'CGHS';
      case 'echs':
        return 'ECHS';
      case 'id_proof':
        return 'ID Proof';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  bool get isImage => mimeType.startsWith('image/');

  String get fileSizeDisplay {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
