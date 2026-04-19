import 'package:flutter/material.dart';

import '../../core/state/mock_data.dart';
import '../../core/theme/app_theme.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Messages', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Receive green reports, forum replies, reward updates, and system notices.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        ...MockData.messages.map(
          (message) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Stack(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.sky,
                    child: Icon(Icons.mail_outline, color: AppTheme.seed),
                  ),
                  if (message.unread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(message.sender),
              subtitle: Text(message.preview),
              trailing: Text(message.updatedAt, style: textTheme.bodyMedium),
            ),
          ),
        ),
      ],
    );
  }
}
