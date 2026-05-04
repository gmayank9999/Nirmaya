class UserModel {
  final String id;
  final String clinicId;
  final String phone;
  final String fullName;
  final String role;

  const UserModel({
    required this.id,
    required this.clinicId,
    required this.phone,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clinicId': clinicId,
        'phone': phone,
        'fullName': fullName,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
}
