class UserProfile {
  UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String role;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? '') as String,
      phone: map['phone'] as String?,
      role: (map['role'] ?? 'citizen') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      };
}
