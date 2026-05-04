class PatientModel {
  final String id;
  final String clinicId;
  final String name;
  final String phone;
  final String? email;
  final int? age;
  final String? gender;
  final String? heightCm;
  final String? weightKg;
  final String? bloodGroup;
  final String? address;
  final String? medicalHistory;
  final bool hasIdProof;
  final String? idProofFileUrl;
  final bool hasCghs;
  final String? cghsFileUrl;
  final bool hasEchs;
  final String? echsFileUrl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const PatientModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.phone,
    this.email,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.bloodGroup,
    this.address,
    this.medicalHistory,
    required this.hasIdProof,
    this.idProofFileUrl,
    required this.hasCghs,
    this.cghsFileUrl,
    required this.hasEchs,
    this.echsFileUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: json['heightCm']?.toString(),
      weightKg: json['weightKg']?.toString(),
      bloodGroup: json['bloodGroup'] as String?,
      address: json['address'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      hasIdProof: json['hasIdProof'] as bool? ?? false,
      idProofFileUrl: json['idProofFileUrl'] as String?,
      hasCghs: json['hasCghs'] as bool? ?? false,
      cghsFileUrl: json['cghsFileUrl'] as String?,
      hasEchs: json['hasEchs'] as bool? ?? false,
      echsFileUrl: json['echsFileUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get genderDisplay {
    if (gender == null) return '';
    return gender![0].toUpperCase() + gender!.substring(1);
  }
}
