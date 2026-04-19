import 'package:flutter/material.dart';

import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = MockData.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Eco Assessment & Rewards', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Track your sustainable behavior and exchange points for green rewards.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          color: AppTheme.moss,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: user.greenScore / 1000,
                        strokeWidth: 10,
                        backgroundColor: Colors.white24,
                        color: AppTheme.leaf,
                      ),
                      Center(
                        child: Text(
                          '${user.greenScore}',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.level,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are in the top 12% of campus recyclers this week.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Recent Eco Actions', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        ...MockData.ecoActions.map(
          (action) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    action.completed ? AppTheme.sky : const Color(0xFFFFF4D8),
                child: Icon(
                  action.completed ? Icons.check : Icons.flag_outlined,
                  color: action.completed ? AppTheme.seed : Colors.orange,
                ),
              ),
              title: Text(action.title),
              subtitle: Text(action.impact),
              trailing: Text(
                '+${action.points}',
                style: textTheme.titleMedium?.copyWith(color: AppTheme.seed),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Reward Store', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        ...MockData.rewards.map(
          (reward) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.sky,
                    child: Icon(Icons.card_giftcard, color: AppTheme.seed),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward.title, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(reward.description),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(
                      reward.redeemed
                          ? 'Redeemed'
                          : '${reward.requiredPoints} pts',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
