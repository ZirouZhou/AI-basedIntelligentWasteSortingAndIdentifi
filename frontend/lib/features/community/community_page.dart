import 'package:flutter/material.dart';

import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Community Forum', style: textTheme.headlineLarge),
            ),
            IconButton.filled(
              onPressed: () {},
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
          children: const [
            Chip(label: Text('Sorting Tips')),
            Chip(label: Text('Campus News')),
            Chip(label: Text('Volunteer')),
            Chip(label: Text('Low Carbon Life')),
          ],
        ),
        const SizedBox(height: 20),
        ...MockData.forumPosts.map(
          (post) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.sky,
                        child: Icon(Icons.person, color: AppTheme.seed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.author, style: textTheme.titleMedium),
                            Text(post.createdAt, style: textTheme.bodyMedium),
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
                      const Icon(Icons.favorite_border, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.likes} likes'),
                      const SizedBox(width: 18),
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.replies} replies'),
                    ],
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
