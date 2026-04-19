class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
    required this.level,
    required this.greenScore,
    required this.totalRecycledKg,
    required this.avatarInitials,
  });

  final String id;
  final String name;
  final String email;
  final String city;
  final String level;
  final int greenScore;
  final double totalRecycledKg;
  final String avatarInitials;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      city: json['city'] as String,
      level: json['level'] as String,
      greenScore: json['greenScore'] as int,
      totalRecycledKg: (json['totalRecycledKg'] as num).toDouble(),
      avatarInitials: json['avatarInitials'] as String,
    );
  }
}
