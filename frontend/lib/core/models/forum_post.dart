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

  /// Constructs a [ForumPost] from a JSON map received from the backend.
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      author: json['author'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tag: json['tag'] as String,
      likes: json['likes'] as int,
      replies: json['replies'] as int,
      createdAt: json['createdAt'] as String,
    );
  }
}
