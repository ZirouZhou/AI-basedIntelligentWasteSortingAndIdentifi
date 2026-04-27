/// Conversation summary shown in message list.
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

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummary(
      id: json['id'] as String,
      peerUserId: json['peerUserId'] as String,
      peerName: json['peerName'] as String,
      peerAvatarInitials: json['peerAvatarInitials'] as String,
      preview: json['preview'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      latestMessageType: json['latestMessageType'] as String? ?? 'text',
    );
  }
}

/// One message in a chat conversation.
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

  bool get isImage => messageType == 'image';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num).toInt(),
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatarInitials: json['senderAvatarInitials'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
