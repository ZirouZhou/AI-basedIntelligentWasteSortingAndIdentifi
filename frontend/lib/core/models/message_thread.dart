// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — MessageThread Model
// ------------------------------------------------------------------------------------------------
//
// [MessageThread] represents an in-app message conversation thread.
// Displayed as a list on the Messages page.
// ------------------------------------------------------------------------------------------------

/// An in-app conversation thread.
///
/// * [id]        – unique identifier
/// * [sender]    – display name of the message sender
/// * [preview]   – short preview of the latest message content
/// * [updatedAt] – human-readable timestamp of the last update
/// * [unread]    – whether there are unread messages in this thread
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

  /// Constructs a [MessageThread] from a JSON map received from the backend.
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
