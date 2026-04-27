// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — AppUser Model
// ------------------------------------------------------------------------------------------------
//
// [AppUser] holds the profile data of the currently signed-in user.
// Displayed on the Profile page and referenced from the Home page header.
// ------------------------------------------------------------------------------------------------

/// Profile information for the currently signed-in EcoSort user.
///
/// * [id]              – unique user identifier
/// * [name]            – full display name
/// * [email]           – email address
/// * [city]            – user's home city
/// * [level]           – eco level title (e.g. "Eco Pioneer")
/// * [greenScore]      – cumulative green score points
/// * [totalRecycledKg] – total weight of waste properly recycled (kg)
/// * [avatarInitials]  – initials shown in the avatar circle
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
    this.avatarUrl,
    this.totalCo2ReductionKg = 0,
  });

  final String id;
  final String name;
  final String email;
  final String city;
  final String level;
  final int greenScore;
  final double totalRecycledKg;
  final String avatarInitials;
  final String? avatarUrl;
  final double totalCo2ReductionKg;

  /// Constructs an [AppUser] from a JSON map received from the backend.
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
      avatarUrl: json['avatarUrl'] as String?,
      totalCo2ReductionKg:
          (json['totalCo2ReductionKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
