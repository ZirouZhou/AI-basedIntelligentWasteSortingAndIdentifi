typedef JsonMap = Map<String, dynamic>;

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

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'binColor': binColor,
      'examples': examples,
      'recyclingTips': recyclingTips,
    };
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

  JsonMap toJson() {
    return {
      'itemName': itemName,
      'category': category.toJson(),
      'confidence': confidence,
      'suggestions': suggestions,
    };
  }
}

class EcoAction {
  const EcoAction({
    required this.id,
    required this.title,
    required this.impact,
    required this.points,
    required this.completed,
  });

  final String id;
  final String title;
  final String impact;
  final int points;
  final bool completed;

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'impact': impact,
      'points': points,
      'completed': completed,
    };
  }
}

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

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'redeemed': redeemed,
    };
  }
}

class ForumPost {
  const ForumPost({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.tag,
    required this.likes,
    required this.replies,
    required this.createdAt,
  });

  final String id;
  final String author;
  final String title;
  final String content;
  final String tag;
  final int likes;
  final int replies;
  final String createdAt;

  JsonMap toJson() {
    return {
      'id': id,
      'author': author,
      'title': title,
      'content': content,
      'tag': tag,
      'likes': likes,
      'replies': replies,
      'createdAt': createdAt,
    };
  }
}

class MessageThread {
  const MessageThread({
    required this.id,
    required this.sender,
    required this.preview,
    required this.updatedAt,
    required this.unread,
  });

  final String id;
  final String sender;
  final String preview;
  final String updatedAt;
  final bool unread;

  JsonMap toJson() {
    return {
      'id': id,
      'sender': sender,
      'preview': preview,
      'updatedAt': updatedAt,
      'unread': unread,
    };
  }
}

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

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'city': city,
      'level': level,
      'greenScore': greenScore,
      'totalRecycledKg': totalRecycledKg,
      'avatarInitials': avatarInitials,
    };
  }
}
