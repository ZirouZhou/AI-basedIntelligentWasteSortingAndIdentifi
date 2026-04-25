// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — WasteCategory Model
// ------------------------------------------------------------------------------------------------
//
// [WasteCategory] represents one of the four waste-sorting bins recognised by
// the EcoSort system. This model is used both to display the sorting guide on
// the Home page and as the predicted category in classification results.
//
// [ClassificationResult] bundles a predicted category with the original item
// name, a confidence score, and disposal suggestions.
// ------------------------------------------------------------------------------------------------

/// One of the four waste-sorting categories: Recyclable, Organic, Hazardous, or Residual.
///
/// * [id]            – machine-readable key
/// * [title]         – human-readable category name
/// * [description]   – what belongs in this bin
/// * [binColor]      – physical bin colour (Blue / Green / Red / Gray)
/// * [examples]      – items that belong here
/// * [recyclingTips] – disposal or recycling guidelines
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

  /// Constructs a [WasteCategory] from a JSON map received from the backend.
  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      binColor: json['binColor'] as String,
      examples: (json['examples'] as List).cast<String>(),
      recyclingTips: (json['recyclingTips'] as List).cast<String>(),
    );
  }
}

/// The result of an AI / keyword classification for a user-submitted item.
///
/// * [itemName]    – the name the user typed or uploaded
/// * [category]    – the predicted [WasteCategory]
/// * [confidence]  – confidence score between 0.0 and 1.0
/// * [suggestions] – recommended disposal steps for this item
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

  /// Constructs a [ClassificationResult] from a JSON map received from the backend.
  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      itemName: json['itemName'] as String,
      category: WasteCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      suggestions: (json['suggestions'] as List).cast<String>(),
    );
  }
}
