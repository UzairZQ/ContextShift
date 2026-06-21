import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';

class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Icon(
              LucideIcons.stickyNote,
              size: 48,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Your thoughts are empty.\nTap + to capture one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
