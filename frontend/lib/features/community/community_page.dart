import 'package:flutter/material.dart';

import '../../core/models/forum_post.dart';
import '../../core/services/api_client.dart';
import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';
import '../messages/chat_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const _userId = 'u1';
  final _apiClient = ApiClient();
  final _tags = const [
    'Sorting Tips',
    'Campus News',
    'Volunteer',
    'Low Carbon Life',
    'General',
  ];

  List<ForumPost> _posts = const [];
  final Map<String, List<ForumComment>> _commentsByPost = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _apiClient.fetchForumPosts();
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = posts;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = MockData.forumPosts;
        _error = 'Backend unavailable. Showing demo posts.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleLike(ForumPost post) async {
    try {
      final updated = await _apiClient.toggleForumPostLike(
        postId: post.id,
        userId: _userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = _posts
            .map((item) => item.id == post.id ? updated : item)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like this post.')),
      );
    }
  }

  Future<void> _openChatByAvatar(ForumPost post) async {
    final peerId = post.authorId.trim();
    if (peerId.isEmpty || peerId == _userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open chat with this user.')),
      );
      return;
    }

    try {
      final conversationId = await _apiClient.getOrCreateDirectConversation(
        userId: _userId,
        peerUserId: peerId,
      );
      if (!mounted) {
        return;
      }
      final initials = _buildInitials(post.author);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            conversationId: conversationId,
            peerUserId: peerId,
            peerName: post.author,
            peerAvatarInitials: initials,
            currentUserId: _userId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat.')),
      );
    }
  }

  String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _openCreatePostDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTag = _tags.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Post'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Share your topic',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText: 'Write your environmental idea or question',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTag,
                      items: _tags
                          .map(
                            (tag) => DropdownMenuItem<String>(
                              value: tag,
                              child: Text(tag),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => selectedTag = value);
                      },
                      decoration: const InputDecoration(labelText: 'Tag'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    try {
      final created = await _apiClient.createForumPost(
        authorId: _userId,
        title: title,
        content: content,
        tag: selectedTag,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = [created, ..._posts];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish post.')),
      );
    }
  }

  Future<void> _openComments(ForumPost post) async {
    await _loadComments(post.id);
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CommentSheet(
          post: post,
          comments: _commentsByPost[post.id] ?? const [],
          onSubmit: (content, parentCommentId) async {
            try {
              await _apiClient.createForumComment(
                postId: post.id,
                authorId: _userId,
                content: content,
                parentCommentId: parentCommentId,
              );
              await _loadComments(post.id);
              await _loadPosts();
            } catch (_) {
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Failed to submit comment.')),
              );
            }
          },
          onLike: (commentId) async {
            try {
              await _apiClient.toggleForumCommentLike(
                commentId: commentId,
                userId: _userId,
              );
              await _loadComments(post.id);
            } catch (_) {
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Failed to like comment.')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _loadComments(String postId) async {
    try {
      final comments = await _apiClient.fetchForumComments(
        postId: postId,
        userId: _userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _commentsByPost[postId] = comments;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _commentsByPost[postId] = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Community Forum', style: textTheme.headlineLarge),
              ),
              IconButton.filled(
                onPressed: _openCreatePostDialog,
                icon: const Icon(Icons.add),
                tooltip: 'Create post',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share sorting questions, volunteer plans, and sustainable lifestyle ideas.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(label: Text(tag))).toList(growable: false),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: Colors.orange[800]),
            ),
          ],
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_posts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No posts yet. Create the first one!'),
              ),
            )
          else
            ..._posts.map(
              (post) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _openChatByAvatar(post),
                            child: const CircleAvatar(
                              backgroundColor: AppTheme.sky,
                              child: Icon(Icons.person, color: AppTheme.seed),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.author, style: textTheme.titleMedium),
                                Text(post.createdAt, style: textTheme.bodyMedium),
                                Text(
                                  'Tap avatar to chat',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppTheme.seed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(label: Text(post.tag)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(post.title, style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(post.content),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(post),
                            icon: Icon(
                              post.likedByMe ? Icons.favorite : Icons.favorite_border,
                              color: post.likedByMe ? Colors.red : null,
                            ),
                            tooltip: 'Like',
                          ),
                          Text('${post.likes} likes'),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => _openComments(post),
                            icon: const Icon(Icons.chat_bubble_outline),
                            tooltip: 'Comments',
                          ),
                          Text('${post.replies} replies'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({
    required this.post,
    required this.comments,
    required this.onSubmit,
    required this.onLike,
  });

  final ForumPost post;
  final List<ForumComment> comments;
  final Future<void> Function(String content, String? parentCommentId) onSubmit;
  final Future<void> Function(String commentId) onLike;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  String? _replyToId;
  String? _replyToAuthor;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    await widget.onSubmit(content, _replyToId);
    if (!mounted) {
      return;
    }
    setState(() {
      _controller.clear();
      _replyToId = null;
      _replyToAuthor = null;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, insets + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.post.title, style: textTheme.titleMedium),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.comments.isEmpty
                    ? const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No comments yet.'),
                        ),
                      ]
                    : widget.comments
                        .map((comment) => _CommentNode(
                              comment: comment,
                              level: 0,
                              onReply: (id, author) {
                                setState(() {
                                  _replyToId = id;
                                  _replyToAuthor = author;
                                });
                              },
                              onLike: widget.onLike,
                            ))
                        .toList(growable: false),
              ),
            ),
            if (_replyToId != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Replying to $_replyToAuthor')),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _replyToId = null;
                        _replyToAuthor = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentNode extends StatelessWidget {
  const _CommentNode({
    required this.comment,
    required this.level,
    required this.onReply,
    required this.onLike,
  });

  final ForumComment comment;
  final int level;
  final void Function(String id, String author) onReply;
  final Future<void> Function(String commentId) onLike;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final leftPadding = 8.0 + (level * 16.0);
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 8, bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.author, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 6),
              Row(
                children: [
                  InkWell(
                    onTap: () => onLike(comment.id),
                    child: Row(
                      children: [
                        Icon(
                          comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: comment.likedByMe ? Colors.red : null,
                        ),
                        const SizedBox(width: 4),
                        Text('${comment.likes}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => onReply(comment.id, comment.author),
                    child: const Text('Reply'),
                  ),
                  const Spacer(),
                  Text(
                    comment.createdAt,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              if (comment.replies.isNotEmpty)
                ...comment.replies.map(
                  (reply) => _CommentNode(
                    comment: reply,
                    level: level + 1,
                    onReply: onReply,
                    onLike: onLike,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
