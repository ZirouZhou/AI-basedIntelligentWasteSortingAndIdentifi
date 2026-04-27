/// A configurable eco action type for carbon-reduction evaluation.
class EcoActionCatalogItem {
  const EcoActionCatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.unitLabel,
    required this.co2KgPerUnit,
    required this.pointsPerUnit,
    required this.active,
  });

  final String id;
  final String title;
  final String description;
  final String unitLabel;
  final double co2KgPerUnit;
  final int pointsPerUnit;
  final bool active;

  factory EcoActionCatalogItem.fromJson(Map<String, dynamic> json) {
    return EcoActionCatalogItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      unitLabel: json['unitLabel'] as String,
      co2KgPerUnit: (json['co2KgPerUnit'] as num).toDouble(),
      pointsPerUnit: json['pointsPerUnit'] as int,
      active: json['active'] as bool,
    );
  }
}

/// One submitted eco-action record with calculated CO2 reduction + points.
class EcoActionRecord {
  const EcoActionRecord({
    required this.id,
    required this.userId,
    required this.catalogActionId,
    required this.actionTitle,
    required this.quantity,
    required this.unitLabel,
    required this.co2ReductionKg,
    required this.pointsAwarded,
    required this.createdAt,
    this.note,
  });

  final int id;
  final String userId;
  final String catalogActionId;
  final String actionTitle;
  final double quantity;
  final String unitLabel;
  final double co2ReductionKg;
  final int pointsAwarded;
  final String createdAt;
  final String? note;

  factory EcoActionRecord.fromJson(Map<String, dynamic> json) {
    return EcoActionRecord(
      id: json['id'] as int,
      userId: json['userId'] as String,
      catalogActionId: json['catalogActionId'] as String,
      actionTitle: json['actionTitle'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitLabel: json['unitLabel'] as String,
      co2ReductionKg: (json['co2ReductionKg'] as num).toDouble(),
      pointsAwarded: json['pointsAwarded'] as int,
      createdAt: json['createdAt'] as String,
      note: json['note'] as String?,
    );
  }
}

/// Result returned after evaluating one eco action.
class EcoActionEvaluationResult {
  const EcoActionEvaluationResult({
    required this.record,
    required this.newPointsBalance,
    required this.totalCo2ReductionKg,
  });

  final EcoActionRecord record;
  final int newPointsBalance;
  final double totalCo2ReductionKg;

  factory EcoActionEvaluationResult.fromJson(Map<String, dynamic> json) {
    return EcoActionEvaluationResult(
      record: EcoActionRecord.fromJson(json['record'] as Map<String, dynamic>),
      newPointsBalance: json['newPointsBalance'] as int,
      totalCo2ReductionKg: (json['totalCo2ReductionKg'] as num).toDouble(),
    );
  }
}

/// Badge redeem item in reward module.
class BadgeItem {
  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.icon,
    required this.redeemed,
    required this.redeemable,
    this.redeemedAt,
  });

  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final String icon;
  final bool redeemed;
  final bool redeemable;
  final String? redeemedAt;

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredPoints: json['requiredPoints'] as int,
      icon: json['icon'] as String,
      redeemed: json['redeemed'] as bool,
      redeemable: json['redeemable'] as bool,
      redeemedAt: json['redeemedAt'] as String?,
    );
  }
}

/// Badge redeem result payload.
class BadgeRedeemResult {
  const BadgeRedeemResult({
    required this.badge,
    required this.newPointsBalance,
  });

  final BadgeItem badge;
  final int newPointsBalance;

  factory BadgeRedeemResult.fromJson(Map<String, dynamic> json) {
    return BadgeRedeemResult(
      badge: BadgeItem.fromJson(json['badge'] as Map<String, dynamic>),
      newPointsBalance: json['newPointsBalance'] as int,
    );
  }
}

/// Dashboard summary for eco-assessment and reward module.
class EcoDashboard {
  const EcoDashboard({
    required this.userId,
    required this.currentPoints,
    required this.totalCo2ReductionKg,
    required this.totalEvaluations,
    required this.badgesRedeemed,
  });

  final String userId;
  final int currentPoints;
  final double totalCo2ReductionKg;
  final int totalEvaluations;
  final int badgesRedeemed;

  factory EcoDashboard.fromJson(Map<String, dynamic> json) {
    return EcoDashboard(
      userId: json['userId'] as String,
      currentPoints: json['currentPoints'] as int,
      totalCo2ReductionKg: (json['totalCo2ReductionKg'] as num).toDouble(),
      totalEvaluations: json['totalEvaluations'] as int,
      badgesRedeemed: json['badgesRedeemed'] as int,
    );
  }
}
