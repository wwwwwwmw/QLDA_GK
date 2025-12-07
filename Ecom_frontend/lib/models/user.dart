class User {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'USER', 'SELLER', 'ADMIN'
  final String status;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
    );
  }
}
