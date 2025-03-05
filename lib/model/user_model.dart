class UserModel {
  final String id;
  final String email;
  final String role; // 'client' o 'deliveryman'
  final String? name;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'client',
      name: map['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
    };
  }
}
