import 'package:flutter/material.dart';

import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const user = MockData.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('My Profile', style: textTheme.headlineLarge),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.seed,
                  child: Text(
                    user.avatarInitials,
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(user.email),
                      const SizedBox(height: 8),
                      Chip(label: Text(user.level)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                label: 'Green Score',
                value: '${user.greenScore}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileMetric(
                label: 'Recycled',
                value: '${user.totalRecycledKg} kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Account', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        const _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'City',
          subtitle: 'Shanghai',
        ),
        const _ProfileTile(
          icon: Icons.history,
          title: 'Sorting History',
          subtitle: 'View all classification records',
        ),
        const _ProfileTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Badges',
          subtitle: '3 badges unlocked',
        ),
        const _ProfileTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Notifications, language, and privacy',
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.sky,
          child: Icon(icon, color: AppTheme.seed),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
