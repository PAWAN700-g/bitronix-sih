enum UserRole {
  consumer,
  govtAuthority,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.consumer:
        return 'Household Consumer';
      case UserRole.govtAuthority:
        return 'Govt Water Authority Inspector';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? profilePicUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.consumer,
    this.department,
    this.profilePicUrl,
  });

  bool get isGovtAuthority => role == UserRole.govtAuthority;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? profilePicUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department,
      'profilePicUrl': profilePicUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] == 'govtAuthority' ? UserRole.govtAuthority : UserRole.consumer,
      department: json['department'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
    );
  }
}
