class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePicUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicUrl': profilePicUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profilePicUrl: json['profilePicUrl'] as String?,
    );
  }
}
