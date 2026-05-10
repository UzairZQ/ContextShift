import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/ai_service.dart';

class NotesModule extends StatefulWidget {
  const NotesModule({super.key});

  @override
  State<NotesModule> createState() => _NotesModuleState();
}

class _NotesModuleState extends State<NotesModule> {
  final _noteController = TextEditingController();
  bool _isAdding = false;

  void _submitNote() {
    if (_noteController.text.trim().isEmpty) return;
    FirebaseService.instance.addNote(content: _noteController.text.trim());
    if (mounted) {
      _noteController.clear();
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Notes', style: Theme.of(context).textTheme.headlineMedium),
            IconButton(
              onPressed: () => setState(() => _isAdding = !_isAdding),
              icon: Icon(_isAdding ? LucideIcons.x : LucideIcons.plus, color: AppTheme.primary),
            ),
          ],
        ),
        if (_isAdding) _buildNoteInput(),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchNotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final notes = snapshot.data!;
            if (notes.isEmpty) return _buildEmptyState();

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth > 800) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 500) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => _buildNoteCard(notes[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: const InputDecoration(
              hintText: 'Whisper a thought...',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _submitNote,
              child: const Text('Save Note', style: TextStyle(color: AppTheme.primary)),
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, bool> _summarizingIds = {};

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final String? summary = note['summary'];
    final bool isSummarizing = _summarizingIds[note['id']] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    summary,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              Expanded(
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ((note['tags'] as List?) ?? []).map((t) => '#$t').join(' '),
                      style: const TextStyle(color: AppTheme.primary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: isSummarizing ? null : () async {
                      setState(() => _summarizingIds[note['id']] = true);
                      final summary = await AiService.instance.summarizeNote(note['content'] ?? '');
                      if (summary != null) {
                        await FirebaseService.instance.updateNote(note['id'], note['content'], summary: summary);
                      }
                      if (mounted) setState(() => _summarizingIds[note['id']] = false);
                    },
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: isSummarizing ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: -8,
            top: -8,
            child: IconButton(
              onPressed: () => FirebaseService.instance.deleteNote(note['id']),
              icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Icon(LucideIcons.stickyNote, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Your thoughts are empty.\nTap + to capture one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
