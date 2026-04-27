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
    required this.identifiedItem,
    required this.englandCategoryName,
    required this.ukDisposalBin,
    required this.ukDisposalTips,
  });

  final String itemName;
  final WasteCategory category;
  final double confidence;
  final List<String> suggestions;
  final String identifiedItem;
  final String englandCategoryName;
  final String ukDisposalBin;
  final List<String> ukDisposalTips;

  /// Serialises this classification result to a JSON-compatible map.
  JsonMap toJson() {
    return {
      'itemName': itemName,
      'category': category.toJson(),
      'confidence': confidence,
      'suggestions': suggestions,
      'identifiedItem': identifiedItem,
      'englandCategoryName': englandCategoryName,
      'ukDisposalBin': ukDisposalBin,
      'ukDisposalTips': ukDisposalTips,
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
    this.authorId = 'u1',
    required this.author,
    required this.title,
    required this.content,
    required this.tag,
    required this.likes,
    required this.replies,
    required this.createdAt,
    this.likedByMe = false,
  });

  final String id;
  final String authorId;
  final String author;
  final String title;
  final String content;
  final String tag;
  final int likes;
  final int replies;
  final String createdAt;
  final bool likedByMe;

  /// Serialises this forum post to a JSON-compatible map.
  JsonMap toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'author': author,
      'title': title,
      'content': content,
      'tag': tag,
      'likes': likes,
      'replies': replies,
      'createdAt': createdAt,
      'likedByMe': likedByMe,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// ForumComment
// ------------------------------------------------------------------------------------------------

/// A comment in the community forum. Supports nested replies.
class ForumComment {
  const ForumComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorId,
    required this.author,
    required this.content,
    required this.likes,
    required this.createdAt,
    this.likedByMe = false,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String? parentCommentId;
  final String authorId;
  final String author;
  final String content;
  final int likes;
  final String createdAt;
  final bool likedByMe;
  final List<ForumComment> replies;

  JsonMap toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'authorId': authorId,
      'author': author,
      'content': content,
      'likes': likes,
      'createdAt': createdAt,
      'likedByMe': likedByMe,
      'replies': replies.map((item) => item.toJson()).toList(growable: false),
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
// ChatConversationSummary
// ------------------------------------------------------------------------------------------------

/// A direct chat conversation summary for one user.
class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatarInitials,
    required this.preview,
    required this.updatedAt,
    required this.unreadCount,
    required this.latestMessageType,
  });

  final String id;
  final String peerUserId;
  final String peerName;
  final String peerAvatarInitials;
  final String preview;
  final String updatedAt;
  final int unreadCount;
  final String latestMessageType;

  JsonMap toJson() {
    return {
      'id': id,
      'peerUserId': peerUserId,
      'peerName': peerName,
      'peerAvatarInitials': peerAvatarInitials,
      'preview': preview,
      'updatedAt': updatedAt,
      'unreadCount': unreadCount,
      'latestMessageType': latestMessageType,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// ChatMessage
// ------------------------------------------------------------------------------------------------

/// One chat message in a conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarInitials,
    required this.messageType,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatarInitials;
  final String messageType;
  final String content;
  final String createdAt;

  JsonMap toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarInitials': senderAvatarInitials,
      'messageType': messageType,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// AuthSession
// ------------------------------------------------------------------------------------------------

/// Authentication payload returned by register/login endpoints.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final String expiresAt;
  final AppUser user;

  JsonMap toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt,
      'user': user.toJson(),
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
      'avatarUrl': avatarUrl,
      'totalCo2ReductionKg': totalCo2ReductionKg,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// UserRecognitionRecord
// ------------------------------------------------------------------------------------------------

/// One image-recognition history record for a user.
class UserRecognitionRecord {
  const UserRecognitionRecord({
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

  JsonMap toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'imageUrl': imageUrl,
      'categoryLabel': categoryLabel,
      'rubbishLabel': rubbishLabel,
      'confidence': confidence,
      'createdAt': createdAt,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// UserPointHistoryRecord
// ------------------------------------------------------------------------------------------------

/// One point change record in user reward history.
class UserPointHistoryRecord {
  const UserPointHistoryRecord({
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

  JsonMap toJson() {
    return {
      'id': id,
      'userId': userId,
      'changeAmount': changeAmount,
      'transactionType': transactionType,
      'relatedId': relatedId,
      'remark': remark,
      'createdAt': createdAt,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// UserBadgeHistoryRecord
// ------------------------------------------------------------------------------------------------

/// One redeemed badge record in user reward history.
class UserBadgeHistoryRecord {
  const UserBadgeHistoryRecord({
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

  JsonMap toJson() {
    return {
      'id': id,
      'userId': userId,
      'badgeId': badgeId,
      'badgeTitle': badgeTitle,
      'badgeIcon': badgeIcon,
      'requiredPoints': requiredPoints,
      'redeemedAt': redeemedAt,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// EcoActionCatalogItem
// ------------------------------------------------------------------------------------------------

/// A configurable eco behavior type used for carbon-reduction evaluation.
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

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'unitLabel': unitLabel,
      'co2KgPerUnit': co2KgPerUnit,
      'pointsPerUnit': pointsPerUnit,
      'active': active,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// EcoActionRecord
// ------------------------------------------------------------------------------------------------

/// A completed eco behavior record submitted by the user.
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

  JsonMap toJson() {
    return {
      'id': id,
      'userId': userId,
      'catalogActionId': catalogActionId,
      'actionTitle': actionTitle,
      'quantity': quantity,
      'unitLabel': unitLabel,
      'co2ReductionKg': co2ReductionKg,
      'pointsAwarded': pointsAwarded,
      'createdAt': createdAt,
      'note': note,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// EcoActionEvaluationResult
// ------------------------------------------------------------------------------------------------

/// Result returned after evaluating and storing a user eco action.
class EcoActionEvaluationResult {
  const EcoActionEvaluationResult({
    required this.record,
    required this.newPointsBalance,
    required this.totalCo2ReductionKg,
  });

  final EcoActionRecord record;
  final int newPointsBalance;
  final double totalCo2ReductionKg;

  JsonMap toJson() {
    return {
      'record': record.toJson(),
      'newPointsBalance': newPointsBalance,
      'totalCo2ReductionKg': totalCo2ReductionKg,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// Badge
// ------------------------------------------------------------------------------------------------

/// Badge that can be redeemed by spending accumulated points.
class Badge {
  const Badge({
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

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'icon': icon,
      'redeemed': redeemed,
      'redeemable': redeemable,
      'redeemedAt': redeemedAt,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// BadgeRedeemResult
// ------------------------------------------------------------------------------------------------

/// Result returned after redeeming a badge.
class BadgeRedeemResult {
  const BadgeRedeemResult({
    required this.badge,
    required this.newPointsBalance,
  });

  final Badge badge;
  final int newPointsBalance;

  JsonMap toJson() {
    return {
      'badge': badge.toJson(),
      'newPointsBalance': newPointsBalance,
    };
  }
}

// ------------------------------------------------------------------------------------------------
// EcoDashboard
// ------------------------------------------------------------------------------------------------

/// Dashboard summary for eco assessment and rewards module.
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

  JsonMap toJson() {
    return {
      'userId': userId,
      'currentPoints': currentPoints,
      'totalCo2ReductionKg': totalCo2ReductionKg,
      'totalEvaluations': totalEvaluations,
      'badgesRedeemed': badgesRedeemed,
    };
  }
}
