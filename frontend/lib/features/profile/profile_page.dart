import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/app_user.dart';
import '../../core/models/forum_post.dart';
import '../../core/models/profile_history_models.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userId,
    required this.profileDataRefreshSignal,
  });

  final String userId;
  final ValueListenable<int> profileDataRefreshSignal;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _apiClient = ApiClient();
  final _imagePicker = ImagePicker();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  AppUser? _user;
  List<RecognitionHistoryRecord> _recognitionHistory = const [];
  List<PointHistoryRecord> _pointHistory = const [];
  List<BadgeHistoryRecord> _badgeHistory = const [];
  List<ForumPost> _myPosts = const [];

  @override
  void initState() {
    super.initState();
    widget.profileDataRefreshSignal.addListener(_onProfileDataRefreshSignal);
    _loadAll();
  }

  @override
  void dispose() {
    widget.profileDataRefreshSignal.removeListener(_onProfileDataRefreshSignal);
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _onProfileDataRefreshSignal() async {
    if (!mounted) {
      return;
    }
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _apiClient.fetchProfile(widget.userId),
        _apiClient.fetchRecognitionHistory(userId: widget.userId, limit: 50),
        _apiClient.fetchPointHistory(userId: widget.userId, limit: 50),
        _apiClient.fetchBadgeHistory(userId: widget.userId, limit: 50),
        _apiClient.fetchUserForumPosts(userId: widget.userId, limit: 50),
      ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _user = results[0] as AppUser;
        _recognitionHistory = results[1] as List<RecognitionHistoryRecord>;
        _pointHistory = results[2] as List<PointHistoryRecord>;
        _badgeHistory = results[3] as List<BadgeHistoryRecord>;
        _myPosts = results[4] as List<ForumPost>;
      });
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

  Future<void> _openEditProfileDialog() async {
    final user = _user;
    if (user == null) {
      return;
    }
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final cityController = TextEditingController(text: user.city);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _runSaving(() async {
      final updated = await _apiClient.updateProfile(
        userId: widget.userId,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        city: cityController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _user = updated;
        _success = 'Profile updated successfully.';
      });
    });
  }

  Future<void> _openAvatarDialog() async {
    final action = await showModalBottomSheet<_AvatarUpdateAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from gallery'),
              onTap: () => Navigator.of(context).pop(_AvatarUpdateAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('Use image URL'),
              onTap: () => Navigator.of(context).pop(_AvatarUpdateAction.url),
            ),
          ],
        ),
      ),
    );

    if (action == _AvatarUpdateAction.gallery) {
      await _uploadAvatarFromGallery();
      return;
    }
    if (action != _AvatarUpdateAction.url) {
      return;
    }

    await _openAvatarUrlDialog();
  }

  Future<void> _openAvatarUrlDialog() async {
    final controller = TextEditingController(text: _user?.avatarUrl ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Avatar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Avatar URL',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final url = controller.text.trim();
    if (url.isEmpty) {
      return;
    }
    await _runSaving(() async {
      await _apiClient.updateAvatar(userId: widget.userId, avatarUrl: url);
      await _loadAll();
      if (!mounted) {
        return;
      }
      setState(() => _success = 'Avatar updated successfully.');
    });
  }

  Future<void> _uploadAvatarFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }

    final ext = picked.name.toLowerCase().split('.').last;
    final mimeType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

    await _runSaving(() async {
      await _apiClient.updateAvatar(userId: widget.userId, avatarUrl: dataUri);
      await _loadAll();
      if (!mounted) {
        return;
      }
      setState(() => _success = 'Avatar uploaded successfully.');
    });
  }

  Future<void> _openChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
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
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    final current = currentController.text.trim();
    final next = newController.text.trim();
    final confirm = confirmController.text.trim();
    if (next != confirm) {
      setState(() => _error = 'New password and confirmation do not match.');
      return;
    }

    await _runSaving(() async {
      await _apiClient.changePassword(
        userId: widget.userId,
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) {
        return;
      }
      setState(() => _success = 'Password changed successfully.');
    });
  }

  Future<void> _runSaving(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openRecognitionHistoryList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RecognitionHistoryListPage(records: _recognitionHistory),
      ),
    );
  }

  Future<void> _openPointBadgeHistoryList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PointBadgeHistoryListPage(
          pointHistory: _pointHistory,
          badgeHistory: _badgeHistory,
        ),
      ),
    );
  }

  Future<void> _openMyPostsList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MyPostsListPage(posts: _myPosts),
      ),
    );
  }

  Future<void> _logout() async {
    _apiClient.clearAuthToken();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = _user;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('My Profile', style: textTheme.headlineLarge),
          const SizedBox(height: 10),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _Banner(message: _error!, isError: true),
          ],
          if (_success != null) ...[
            const SizedBox(height: 10),
            _Banner(message: _success!, isError: false),
          ],
          const SizedBox(height: 14),
          if (user == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Loading profile...'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _saving ? null : _openAvatarDialog,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.seed,
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                ? Text(
                                    user.avatarInitials,
                                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: textTheme.titleLarge),
                              Text(user.email),
                              const SizedBox(height: 4),
                              Text('${user.city} · ${user.level}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _openEditProfileDialog,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Info'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _openChangePasswordDialog,
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Password'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (user != null)
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Green Score',
                    value: '${user.greenScore}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'CO2 Reduced',
                    value: '${user.totalCo2ReductionKg.toStringAsFixed(2)} kg',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 22),
          _HistoryCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Recognition History', style: textTheme.titleLarge),
              subtitle: Text(
                _recognitionHistory.isEmpty
                    ? 'No recognition history yet.'
                    : '${_recognitionHistory.length} records',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openRecognitionHistoryList,
            ),
          ),
          const SizedBox(height: 16),
          _HistoryCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Points & Badge History', style: textTheme.titleLarge),
              subtitle: Text(
                '${_pointHistory.length} point records, ${_badgeHistory.length} badge records',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openPointBadgeHistoryList,
            ),
          ),
          const SizedBox(height: 16),
          _HistoryCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('My Posts', style: textTheme.titleLarge),
              subtitle: Text(
                _myPosts.isEmpty ? 'No posts yet.' : '${_myPosts.length} posts',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openMyPostsList,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionHistoryListPage extends StatelessWidget {
  const _RecognitionHistoryListPage({
    required this.records,
  });

  final List<RecognitionHistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recognition History')),
      body: records.isEmpty
          ? const Center(child: Text('No recognition history yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = records[index];
                return ListTile(
                  title: Text('${item.rubbishLabel} (${item.categoryLabel})'),
                  subtitle: Text('${item.createdAt} | ${item.fileName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _RecognitionHistoryDetailPage(record: item),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemCount: records.length,
            ),
    );
  }
}

class _RecognitionHistoryDetailPage extends StatelessWidget {
  const _RecognitionHistoryDetailPage({
    required this.record,
  });

  final RecognitionHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recognition Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(record.rubbishLabel, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          _DetailRow(label: 'Category', value: record.categoryLabel),
          _DetailRow(label: 'Confidence', value: '${(record.confidence * 100).toStringAsFixed(0)}%'),
          _DetailRow(label: 'File', value: record.fileName),
          _DetailRow(label: 'Time', value: record.createdAt),
          _DetailRow(label: 'Image URL', value: record.imageUrl),
        ],
      ),
    );
  }
}

class _PointBadgeHistoryListPage extends StatelessWidget {
  const _PointBadgeHistoryListPage({
    required this.pointHistory,
    required this.badgeHistory,
  });

  final List<PointHistoryRecord> pointHistory;
  final List<BadgeHistoryRecord> badgeHistory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Points & Badges')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Point Records'),
          const SizedBox(height: 8),
          if (pointHistory.isEmpty)
            const ListTile(title: Text('No point history yet.'))
          else
            ...pointHistory.map(
              (item) => ListTile(
                title: Text(item.transactionType),
                subtitle: Text(item.createdAt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _PointHistoryDetailPage(record: item),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 24),
          const Text('Badge Records'),
          const SizedBox(height: 8),
          if (badgeHistory.isEmpty)
            const ListTile(title: Text('No badge history yet.'))
          else
            ...badgeHistory.map(
              (item) => ListTile(
                title: Text('${item.badgeIcon} ${item.badgeTitle}'),
                subtitle: Text(item.redeemedAt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _BadgeHistoryDetailPage(record: item),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PointHistoryDetailPage extends StatelessWidget {
  const _PointHistoryDetailPage({
    required this.record,
  });

  final PointHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Point Record Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Transaction Type', value: record.transactionType),
          _DetailRow(label: 'Change', value: '${record.changeAmount}'),
          _DetailRow(label: 'Related ID', value: record.relatedId ?? '-'),
          _DetailRow(label: 'Remark', value: record.remark ?? '-'),
          _DetailRow(label: 'Time', value: record.createdAt),
        ],
      ),
    );
  }
}

class _BadgeHistoryDetailPage extends StatelessWidget {
  const _BadgeHistoryDetailPage({
    required this.record,
  });

  final BadgeHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badge Record Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Badge', value: '${record.badgeIcon} ${record.badgeTitle}'),
          _DetailRow(label: 'Badge ID', value: record.badgeId),
          _DetailRow(label: 'Required Points', value: '${record.requiredPoints}'),
          _DetailRow(label: 'Redeemed At', value: record.redeemedAt),
        ],
      ),
    );
  }
}

class _MyPostsListPage extends StatelessWidget {
  const _MyPostsListPage({
    required this.posts,
  });

  final List<ForumPost> posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: posts.isEmpty
          ? const Center(child: Text('No posts yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post.title),
                  subtitle: Text('${post.createdAt} | ${post.tag}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _MyPostDetailPage(post: post),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemCount: posts.length,
            ),
    );
  }
}

class _MyPostDetailPage extends StatelessWidget {
  const _MyPostDetailPage({
    required this.post,
  });

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(post.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          _DetailRow(label: 'Author', value: post.author),
          _DetailRow(label: 'Tag', value: post.tag),
          _DetailRow(label: 'Created At', value: post.createdAt),
          _DetailRow(label: 'Likes', value: '${post.likes}'),
          _DetailRow(label: 'Replies', value: '${post.replies}'),
          const SizedBox(height: 10),
          Text(post.content, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: textTheme.titleSmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFBEAEA) : const Color(0xFFE7F7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

enum _AvatarUpdateAction { gallery, url }
