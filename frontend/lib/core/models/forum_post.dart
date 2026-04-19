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
