// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Reward Model
// ------------------------------------------------------------------------------------------------
//
// [Reward] represents a prize that users can redeem using their accumulated
// green points. Displayed on the Rewards page in the "Reward Store" section.
// ------------------------------------------------------------------------------------------------

/// A redeemable prize in the EcoSort reward store.
///
/// * [id]             – unique identifier
/// * [title]          – reward name
/// * [description]    – details about what the reward offers
/// * [requiredPoints] – number of green points needed to redeem
/// * [redeemed]       – whether the current user has already claimed this reward
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.redeemed,
  });

  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final bool redeemed;

  /// Constructs a [Reward] from a JSON map received from the backend.
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredPoints: json['requiredPoints'] as int,
      redeemed: json['redeemed'] as bool,
    );
  }
}
