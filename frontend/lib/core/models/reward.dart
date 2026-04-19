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
