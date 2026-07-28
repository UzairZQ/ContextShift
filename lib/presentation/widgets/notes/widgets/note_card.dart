import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../shared/module_cards.dart';

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;

  static const _accents = [
    Color(0xFF8DB8FF),
    Color(0xFFFFD166),
    Color(0xFFC7A6FF),
    Color(0xFF8FE3CF),
    Color(0xFFFF9DAA),
  ];

  const NoteCard({super.key, required this.note});

  Future<void> _delete(BuildContext context) async {
    try {
      await DatabaseService.instance.deleteNote(note['id']);
    } catch (error, stackTrace) {
      debugPrint('[NoteCard] Delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete note. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _open(BuildContext context) {
    final accent = _accentForNote();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _JournalDetailSheet(note: note, accent: accent),
    );
  }

  Color _accentForNote() {
    final id = int.tryParse(note['id']?.toString() ?? '') ?? 0;
    return _accents[id.abs() % _accents.length];
  }

  @override
  Widget build(BuildContext context) {
    final String? summary = note['summary'];
    final tags = (note['tags'] as List?) ?? [];
    final content = note['content']?.toString() ?? '';
    final accent = _accentForNote();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: moduleCardDecoration(
            accent: accent,
            borderRadius: 16,
            fill: AppTheme.surfaceContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: summary != null
                        ? _Summary(text: summary, accent: accent)
                        : Text(
                            'Journal entry',
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete journal entry',
                    onPressed: () => _delete(context),
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
                    content,
                    style: TextStyle(
                      color: summary != null ? Colors.white60 : Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),
                    maxLines: summary != null ? 3 : 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tags.map((t) => '#$t').join(' '),
                      style: TextStyle(color: accent, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(LucideIcons.arrowUpRight, size: 14, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String text;
  final Color accent;

  const _Summary({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _JournalDetailSheet extends StatelessWidget {
  final Map<String, dynamic> note;
  final Color accent;

  const _JournalDetailSheet({required this.note, required this.accent});

  @override
  Widget build(BuildContext context) {
    final summary = note['summary']?.toString().trim();
    final content = note['content']?.toString() ?? '';
    final tags = (note['tags'] as List?) ?? [];
    final updatedAt = note['updatedAt'];
    final date = updatedAt is DateTime
        ? MaterialLocalizations.of(context).formatMediumDate(updatedAt)
        : null;

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(LucideIcons.bookOpen, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Journal entry',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (date != null) ...[
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              if (summary != null && summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurface.withValues(alpha: 0.92),
                  height: 1.55,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text('#$tag'),
                          labelStyle: TextStyle(color: accent, fontSize: 12),
                          backgroundColor: accent.withValues(alpha: 0.1),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
