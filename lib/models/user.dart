class User {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      phone: json['phone'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}
