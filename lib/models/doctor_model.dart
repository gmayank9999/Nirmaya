class DoctorModel {
  final String id;
  final String name;
  final String? specialization;
  final String? phone;
  final bool isActive;

  const DoctorModel({
    required this.id,
    required this.name,
    this.specialization,
    this.phone,
    required this.isActive,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
