import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final String? summary = note['summary'];
    final tags = (note['tags'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: summary != null
                    ? _Summary(text: summary)
                    : const SizedBox.shrink(),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete note',
                onPressed: () =>
                    DatabaseService.instance.deleteNote(note['id']),
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                note['content'] ?? '',
                style: TextStyle(
                  color: summary != null ? Colors.white60 : Colors.white,
                  fontSize: 14,
                ),
                maxLines: summary != null ? 3 : 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tags.map((t) => '#$t').join(' '),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String text;

  const _Summary({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
