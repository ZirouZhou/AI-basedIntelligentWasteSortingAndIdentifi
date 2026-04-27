class RecognitionHistoryRecord {
  const RecognitionHistoryRecord({
    required this.id,
    required this.fileName,
    required this.imageUrl,
    required this.categoryLabel,
    required this.rubbishLabel,
    required this.confidence,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String imageUrl;
  final String categoryLabel;
  final String rubbishLabel;
  final double confidence;
  final String createdAt;

  factory RecognitionHistoryRecord.fromJson(Map<String, dynamic> json) {
    return RecognitionHistoryRecord(
      id: json['id'] as int,
      fileName: json['fileName'] as String,
      imageUrl: json['imageUrl'] as String,
      categoryLabel: json['categoryLabel'] as String,
      rubbishLabel: json['rubbishLabel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }
}

class PointHistoryRecord {
  const PointHistoryRecord({
    required this.id,
    required this.userId,
    required this.changeAmount,
    required this.transactionType,
    this.relatedId,
    this.remark,
    required this.createdAt,
  });

  final int id;
  final String userId;
  final int changeAmount;
  final String transactionType;
  final String? relatedId;
  final String? remark;
  final String createdAt;

  factory PointHistoryRecord.fromJson(Map<String, dynamic> json) {
    return PointHistoryRecord(
      id: json['id'] as int,
      userId: json['userId'] as String,
      changeAmount: json['changeAmount'] as int,
      transactionType: json['transactionType'] as String,
      relatedId: json['relatedId'] as String?,
      remark: json['remark'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class BadgeHistoryRecord {
  const BadgeHistoryRecord({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.badgeTitle,
    required this.badgeIcon,
    required this.requiredPoints,
    required this.redeemedAt,
  });

  final int id;
  final String userId;
  final String badgeId;
  final String badgeTitle;
  final String badgeIcon;
  final int requiredPoints;
  final String redeemedAt;

  factory BadgeHistoryRecord.fromJson(Map<String, dynamic> json) {
    return BadgeHistoryRecord(
      id: json['id'] as int,
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      badgeTitle: json['badgeTitle'] as String,
      badgeIcon: json['badgeIcon'] as String,
      requiredPoints: json['requiredPoints'] as int,
      redeemedAt: json['redeemedAt'] as String,
    );
  }
}
