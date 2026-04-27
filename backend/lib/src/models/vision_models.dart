typedef VisionJson = Map<String, dynamic>;

/// One candidate element returned by Alibaba Cloud garbage classification.
class AliyunRubbishElement {
  const AliyunRubbishElement({
    required this.category,
    required this.categoryScore,
    required this.rubbish,
    required this.rubbishScore,
  });

  final String category;
  final double categoryScore;
  final String rubbish;
  final double rubbishScore;

  factory AliyunRubbishElement.fromJson(Map<String, dynamic> json) {
    return AliyunRubbishElement(
      category: (json['Category'] ?? '').toString(),
      categoryScore: (json['CategoryScore'] as num?)?.toDouble() ?? 0,
      rubbish: (json['Rubbish'] ?? '').toString(),
      rubbishScore: (json['RubbishScore'] as num?)?.toDouble() ?? 0,
    );
  }

  VisionJson toJson() {
    return {
      'category': category,
      'categoryScore': categoryScore,
      'rubbish': rubbish,
      'rubbishScore': rubbishScore,
    };
  }
}

/// Raw response payload from Alibaba Cloud `ClassifyingRubbish`.
class AliyunRubbishResponse {
  const AliyunRubbishResponse({
    required this.requestId,
    required this.sensitive,
    required this.elements,
    required this.imageUrl,
    required this.rawPayload,
  });

  final String requestId;
  final bool sensitive;
  final List<AliyunRubbishElement> elements;
  final String imageUrl;
  final VisionJson rawPayload;
}
