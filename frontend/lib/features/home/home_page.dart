import 'package:flutter/material.dart';

import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          children: const [
            Expanded(
              child: _MetricCard(
                label: 'Green Score',
                value: '836',
                icon: Icons.trending_up,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Recycled',
                value: '48.5 kg',
                icon: Icons.recycling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Sorting Guide', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        ...MockData.categories.map(
          (category) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: AppTheme.sky,
                child: Text(category.binColor.substring(0, 1)),
              ),
              title: Text(category.title),
              subtitle: Text(category.description),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
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
