import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/chat_models.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatarInitials,
    this.currentUserId = 'u1',
  });

  final String conversationId;
  final String peerUserId;
  final String peerName;
  final String peerAvatarInitials;
  final String currentUserId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ApiClient _apiClient;
  late final TextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _textController = TextEditingController();
    _initialLoad();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollNewMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await _apiClient.fetchChatMessages(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
      });
      await _markRead();
      _jumpToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pollNewMessages() async {
    if (!mounted) {
      return;
    }
    final latestId = _messages.isEmpty ? null : _messages.last.id;
    try {
      final incoming = await _apiClient.fetchChatMessages(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        afterMessageId: latestId,
        limit: 100,
      );
      if (!mounted || incoming.isEmpty) {
        return;
      }
      setState(() => _messages.addAll(incoming));
      await _markRead();
      _jumpToBottom();
    } catch (_) {}
  }

  Future<void> _markRead() async {
    await _apiClient.markChatConversationRead(
      userId: widget.currentUserId,
      conversationId: widget.conversationId,
    );
  }

  Future<void> _sendText() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      final message = await _apiClient.sendChatTextMessage(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        content: content,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(message);
        _textController.clear();
      });
      _jumpToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }

    final ext = picked.name.toLowerCase().split('.').last;
    String mimeType;
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else {
      mimeType = 'image/jpeg';
    }
    final payload = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() => _sending = true);
    try {
      final message = await _apiClient.sendChatImageMessage(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
        imageUrl: payload,
      );
      if (!mounted) {
        return;
      }
      setState(() => _messages.add(message));
      _jumpToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image send failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.sky,
              child: Text(widget.peerAvatarInitials),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.peerName)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final mine = message.senderId == widget.currentUserId;
                return _MessageBubble(
                  message: message,
                  mine: mine,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _sendImage,
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Send image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _sendText,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
  });

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = mine ? AppTheme.seed : Colors.white;
    final textColor = mine ? Colors.white : Colors.black87;
    final isDataImage = message.content.startsWith('data:image');
    final imageBytes = isDataImage ? _decodeDataUri(message.content) : null;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mine ? AppTheme.seed : AppTheme.sky),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 210,
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        message.content,
                        width: 210,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return SizedBox(
                            width: 210,
                            child: Text(
                              message.content,
                              style: TextStyle(color: textColor),
                            ),
                          );
                        },
                      ),
              )
            else
              Text(message.content, style: TextStyle(color: textColor)),
            const SizedBox(height: 4),
            Text(
              message.createdAt,
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Uint8List? _decodeDataUri(String input) {
    final commaIndex = input.indexOf(',');
    if (commaIndex < 0 || commaIndex >= input.length - 1) {
      return null;
    }
    final base64Part = input.substring(commaIndex + 1);
    try {
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }
}
