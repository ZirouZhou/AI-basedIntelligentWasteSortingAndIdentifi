import 'package:flutter/material.dart';

import '../../core/models/chat_models.dart';
import '../../core/services/api_client.dart';
import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final ApiClient _apiClient;
  bool _loading = true;
  String? _error;
  List<ChatConversationSummary> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _load();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversations = await _apiClient.fetchChatConversations(
        userId: widget.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _conversations = conversations);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _conversations = MockData.messages
            .where((item) => item.peerUserId != widget.userId)
            .toList(growable: false);
        _error = 'Backend unavailable. Showing demo conversations.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openConversation(ChatConversationSummary item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          conversationId: item.id,
          peerUserId: item.peerUserId,
          peerName: item.peerName,
          peerAvatarInitials: item.peerAvatarInitials,
          currentUserId: widget.userId,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('Messages', style: textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Chat with community members in real time, including text and image messages.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
                ),
              ),
            )
          else if (_conversations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('No chat conversations yet.'),
              ),
            )
          else
            ..._conversations.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _openConversation(item),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.sky,
                        child: Text(item.peerAvatarInitials),
                      ),
                      if (item.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Text(
                              '${item.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(item.peerName),
                  subtitle: Text(item.preview),
                  trailing: Text(item.updatedAt, style: textTheme.bodySmall),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
