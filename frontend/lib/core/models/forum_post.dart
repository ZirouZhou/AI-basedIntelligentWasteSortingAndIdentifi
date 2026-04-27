// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — ForumPost Model
// ------------------------------------------------------------------------------------------------
//
// [ForumPost] represents a single discussion thread in the community forum.
// Displayed on the Community page as a list of cards.
// ------------------------------------------------------------------------------------------------

/// A post in the community discussion board.
///
/// * [id]        – unique identifier
/// * [author]    – display name of the person who created the post
/// * [title]     – post headline
/// * [content]   – full body text
/// * [tag]       – topic category label (e.g. "Sorting Tips")
/// * [likes]     – number of likes
/// * [replies]   – number of comment replies
/// * [createdAt] – human-readable timestamp
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

  /// Constructs a [ForumPost] from a JSON map received from the backend.
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      authorId: (json['authorId'] ?? 'u1') as String,
      author: json['author'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tag: json['tag'] as String,
      likes: json['likes'] as int,
      replies: json['replies'] as int,
      createdAt: json['createdAt'] as String,
      likedByMe: (json['likedByMe'] ?? false) as bool,
    );
  }
}

/// A comment for one forum post. Supports nested replies.
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
    required this.likedByMe,
    required this.replies,
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

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    final replyList = (json['replies'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ForumComment.fromJson)
        .toList(growable: false);

    return ForumComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      parentCommentId: json['parentCommentId'] as String?,
      authorId: (json['authorId'] ?? 'u1') as String,
      author: json['author'] as String,
      content: json['content'] as String,
      likes: json['likes'] as int,
      createdAt: json['createdAt'] as String,
      likedByMe: (json['likedByMe'] ?? false) as bool,
      replies: replyList,
    );
  }
}
