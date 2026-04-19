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

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      id: json['id'] as String,
      sender: json['sender'] as String,
      preview: json['preview'] as String,
      updatedAt: json['updatedAt'] as String,
      unread: json['unread'] as bool,
    );
  }
}
