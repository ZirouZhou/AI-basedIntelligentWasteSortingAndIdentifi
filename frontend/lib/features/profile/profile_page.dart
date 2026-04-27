import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/app_user.dart';
import '../../core/models/forum_post.dart';
import '../../core/models/profile_history_models.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userId,
  });

  final String userId;

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
    _loadAll();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
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
        _apiClient.fetchRecognitionHistory(userId: widget.userId, limit: 20),
        _apiClient.fetchPointHistory(userId: widget.userId, limit: 20),
        _apiClient.fetchBadgeHistory(userId: widget.userId, limit: 20),
        _apiClient.fetchUserForumPosts(userId: widget.userId, limit: 20),
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
          Text('Recognition History', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _HistoryCard(
            child: _recognitionHistory.isEmpty
                ? const Text('No recognition history yet.')
                : Column(
                    children: _recognitionHistory
                        .map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item.rubbishLabel} (${item.categoryLabel})'),
                            subtitle: Text('${item.createdAt} · ${item.fileName}'),
                            trailing: Text('${(item.confidence * 100).toStringAsFixed(0)}%'),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          Text('Points & Badge History', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _HistoryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Point Records', style: textTheme.titleMedium),
                const SizedBox(height: 6),
                if (_pointHistory.isEmpty)
                  const Text('No point history yet.')
                else
                  ..._pointHistory.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.transactionType),
                      subtitle: Text(item.createdAt),
                      trailing: Text(
                        item.changeAmount > 0
                            ? '+${item.changeAmount}'
                            : '${item.changeAmount}',
                        style: TextStyle(
                          color: item.changeAmount >= 0 ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 24),
                Text('Badge Records', style: textTheme.titleMedium),
                const SizedBox(height: 6),
                if (_badgeHistory.isEmpty)
                  const Text('No badge history yet.')
                else
                  ..._badgeHistory.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.badgeIcon} ${item.badgeTitle}'),
                      subtitle: Text(item.redeemedAt),
                      trailing: Text('-${item.requiredPoints}'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('My Posts', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _HistoryCard(
            child: _myPosts.isEmpty
                ? const Text('No posts yet.')
                : Column(
                    children: _myPosts
                        .map(
                          (post) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(post.title),
                            subtitle: Text('${post.createdAt} · ${post.tag}'),
                            trailing: Text('❤️ ${post.likes}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
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
