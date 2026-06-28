import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../shared/context_shift_primitives.dart';

class CommandHistory extends StatelessWidget {
  const CommandHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchAiCommands(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _EmptyHistory();
            }

            return Column(
              children: snapshot.data!
                  .map((cmd) => _HistoryItem(cmd: cmd))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const ContextPanel(
      padding: EdgeInsets.all(24),
      child: Text(
        'No command history yet.\nAsk JARVIS to turn context into an action.',
        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> cmd;

  const _HistoryItem({required this.cmd});

  @override
  Widget build(BuildContext context) {
    return ContextPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      accent: AppTheme.intelligence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.terminal,
                size: 14,
                color: AppTheme.intelligence,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${cmd['command'] ?? ''}"',
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cmd['response'] ?? '',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
