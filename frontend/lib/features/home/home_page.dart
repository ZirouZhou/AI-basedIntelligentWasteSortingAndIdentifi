import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';

/// Home page dashboard.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.userId,
    required this.onNavigateToTab,
    required this.profileDataRefreshSignal,
  });

  final String userId;
  final ValueChanged<int> onNavigateToTab;
  final ValueListenable<int> profileDataRefreshSignal;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _apiClient = ApiClient();
  int? _greenScore;
  double? _recycledKg;

  @override
  void initState() {
    super.initState();
    widget.profileDataRefreshSignal.addListener(_refreshProfileSummary);
    _refreshProfileSummary();
  }

  @override
  void dispose() {
    widget.profileDataRefreshSignal.removeListener(_refreshProfileSummary);
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _refreshProfileSummary() async {
    try {
      final user = await _apiClient.fetchProfile(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _greenScore = user.greenScore;
        _recycledKg = user.totalRecycledKg;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('EcoSort AI', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Identify waste instantly, build greener habits, and connect with a low-carbon community.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D2E), Color(0xFF2EAD72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, size: 42, color: Colors.white),
              const SizedBox(height: 18),
              Text(
                'Today is a good day to sort smarter.',
                style: textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan an item, learn the correct bin, and earn points for every verified eco action.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Green Score',
                value: '${_greenScore ?? 0}',
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Recycled',
                value: '${(_recycledKg ?? 0).toStringAsFixed(1)} kg',
                icon: Icons.recycling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Navigation', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        _QuickNavCard(
          title: 'Start AI Classification',
          subtitle: 'Open camera/gallery recognition page',
          icon: Icons.camera_alt_outlined,
          onTap: () => widget.onNavigateToTab(1),
        ),
        const SizedBox(height: 10),
        _QuickNavCard(
          title: 'View Rewards',
          subtitle: 'Check points, eco actions and badges',
          icon: Icons.emoji_events_outlined,
          onTap: () => widget.onNavigateToTab(2),
        ),
        const SizedBox(height: 10),
        _QuickNavCard(
          title: 'Community Forum',
          subtitle: 'Discuss recycling and low-carbon ideas',
          icon: Icons.forum_outlined,
          onTap: () => widget.onNavigateToTab(3),
        ),
        const SizedBox(height: 10),
        _QuickNavCard(
          title: 'My Profile',
          subtitle: 'View recognition history and account settings',
          icon: Icons.person_outline,
          onTap: () => widget.onNavigateToTab(5),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.seed),
            const SizedBox(height: 14),
            Text(value, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppTheme.seed),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
