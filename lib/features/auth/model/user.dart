class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json){
    return User(
        id: json['userId'] ?? '',
        email: json['email'] ?? '',
        name: json['username'] ?? ''
    );
  }
}