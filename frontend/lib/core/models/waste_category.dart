class WasteCategory {
  const WasteCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.binColor,
    required this.examples,
    required this.recyclingTips,
  });

  final String id;
  final String title;
  final String description;
  final String binColor;
  final List<String> examples;
  final List<String> recyclingTips;

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      binColor: json['binColor'] as String,
      examples: List<String>.from(json['examples'] as List),
      recyclingTips: List<String>.from(json['recyclingTips'] as List),
    );
  }
}

class ClassificationResult {
  const ClassificationResult({
    required this.itemName,
    required this.category,
    required this.confidence,
    required this.suggestions,
  });

  final String itemName;
  final WasteCategory category;
  final double confidence;
  final List<String> suggestions;

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      itemName: json['itemName'] as String,
      category: WasteCategory.fromJson(json['category'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }
}
