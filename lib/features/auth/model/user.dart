class User {
  final String id;
  final String email;
  final String name;
  final String? fullname;
  final String? avatar;
  final String? createdAt;
  final List<String>? roles;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.fullname,
    this.avatar,
    this.createdAt,
    this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      avatar: json['avatar'] ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String get username => name;
  String get createdAtStr => createdAt ?? '';
}
