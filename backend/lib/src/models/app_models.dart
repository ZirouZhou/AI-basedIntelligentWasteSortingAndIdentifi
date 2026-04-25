// ------------------------------------------------------------------------------------------------
// EcoSort AI Backend — Shared Data Models
// ------------------------------------------------------------------------------------------------
//
// This file defines the canonical Dart representations of every piece of
// domain data that flows between the backend and the Flutter frontend. Each
// class mirrors a JSON object returned by the REST API and provides a
// [toJson] method so Shelf handlers can serialise it easily.
//
// Models defined here:
//   • WasteCategory         – one of the four waste bins (blue/green/red/gray)
//   • ClassificationResult  – AI prediction for a user-submitted item
//   • EcoAction             – a sustainability task the user can complete
//   • Reward                – a prize redeemable with green points
//   • ForumPost             – a post in the community discussion board
//   • MessageThread         – an in-app message conversation
//   • AppUser               – the currently signed-in user profile
// ------------------------------------------------------------------------------------------------

/// Shortcut type alias for JSON maps used throughout the backend.
typedef JsonMap = Map<String, dynamic>;

// ------------------------------------------------------------------------------------------------
// WasteCategory
// ------------------------------------------------------------------------------------------------

/// Represents one of the four waste-sorting categories recognised by EcoSort.
///
/// * [id]          – machine-readable key (`recyclable`, `organic`, …)
/// * [title]       – human-readable label
/// * [description] – what belongs in this category
/// * [binColor]    – colour name of the physical bin (Blue / Green / Red / Gray)
/// * [examples]    – concrete items that belong here
/// * [recyclingTips] – disposal or recycling instructions
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

  /// Serialises this category to a JSON-compatible map.
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

// ------------------------------------------------------------------------------------------------
// ClassificationResult
// ------------------------------------------------------------------------------------------------

/// The result of running the AI / keyword classifier on a user-submitted item.
///
/// * [itemName]   – the name the user typed
/// * [category]   – the predicted [WasteCategory]
/// * [confidence] – confidence score between 0.0 and 1.0
/// * [suggestions] – disposal / recycling instructions for this item
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

  /// Serialises this classification result to a JSON-compatible map.
  JsonMap toJson() {
    return {
      'itemName': itemName,
      'category': category.toJson(),
      'confidence': confidence,
      'suggestions': suggestions,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// EcoAction
// ------------------------------------------------------------------------------------------------

/// A sustainability task or event that a user can participate in to earn points.
///
/// * [id]        – unique identifier
/// * [title]     – short description of the action
/// * [impact]    – environmental benefit summary
/// * [points]    – green points awarded on completion
/// * [completed] – whether the current user has finished this action
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

  /// Serialises this eco action to a JSON-compatible map.
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

// ------------------------------------------------------------------------------------------------
// Reward
// ------------------------------------------------------------------------------------------------

/// A prize that users can redeem using their accumulated green points.
///
/// * [id]             – unique identifier
/// * [title]          – reward name
/// * [description]    – details about the reward
/// * [requiredPoints] – points needed to redeem
/// * [redeemed]       – whether the user has already claimed this reward
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

  /// Serialises this reward to a JSON-compatible map.
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

// ------------------------------------------------------------------------------------------------
// ForumPost
// ------------------------------------------------------------------------------------------------

/// A post in the community discussion forum.
///
/// * [id]        – unique identifier
/// * [author]    – display name of the person who wrote the post
/// * [title]     – post headline
/// * [content]   – full body text
/// * [tag]       – topic label (e.g. "Sorting Tips", "Volunteer")
/// * [likes]     – number of likes
/// * [replies]   – number of reply comments
/// * [createdAt] – human-readable timestamp (e.g. "Today", "2 days ago")
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

  /// Serialises this forum post to a JSON-compatible map.
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

// ------------------------------------------------------------------------------------------------
// MessageThread
// ------------------------------------------------------------------------------------------------

/// An in-app message conversation thread.
///
/// * [id]        – unique identifier
/// * [sender]    – name of the message sender
/// * [preview]   – short preview of the latest message
/// * [updatedAt] – human-readable last-update time
/// * [unread]    – whether the thread has unread messages
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

  /// Serialises this message thread to a JSON-compatible map.
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

// ------------------------------------------------------------------------------------------------
// AppUser
// ------------------------------------------------------------------------------------------------

/// Profile data for the currently signed-in user.
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
  });

  final String id;
  final String name;
  final String email;
  final String city;
  final String level;
  final int greenScore;
  final double totalRecycledKg;
  final String avatarInitials;

  /// Serialises this user profile to a JSON-compatible map.
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
