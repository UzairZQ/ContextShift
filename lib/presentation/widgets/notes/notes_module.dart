import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/ai_service.dart';
import '../../../core/firebase_service.dart';
import 'widgets/note_card.dart';
import 'widgets/note_input.dart';
import 'widgets/notes_empty_state.dart';

class NotesModule extends StatefulWidget {
  const NotesModule({super.key});

  @override
  State<NotesModule> createState() => _NotesModuleState();
}

class _NotesModuleState extends State<NotesModule> {
  final _noteController = TextEditingController();
  final Map<String, bool> _summarizingIds = {};
  bool _isAdding = false;

  void _toggleAdd() {
    setState(() => _isAdding = !_isAdding);
  }

  Future<void> _submitNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;
    await FirebaseService.instance.addNote(content: content);
    if (!mounted) return;
    _noteController.clear();
    setState(() => _isAdding = false);
  }

  Future<void> _summarize(String noteId, String content) async {
    if (_summarizingIds[noteId] ?? false) return;
    setState(() => _summarizingIds[noteId] = true);
    final summary = await AiService.instance.summarizeNote(content);
    if (summary != null) {
      await FirebaseService.instance.updateNote(
        noteId,
        content,
        summary: summary,
      );
    }
    if (mounted) setState(() => _summarizingIds[noteId] = false);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int _gridColumns(double width) {
    if (width > 800) return 4;
    if (width > 500) return 3;
    return 2;
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
            Text(
              'Quick Notes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            IconButton(
              onPressed: _toggleAdd,
              icon: Icon(
                _isAdding ? LucideIcons.x : LucideIcons.plus,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        if (_isAdding)
          NoteInput(controller: _noteController, onSubmit: _submitNote),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchNotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final notes = snapshot.data!;
            if (notes.isEmpty) return const NotesEmptyState();

            return LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns(constraints.maxWidth),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(
                    note: notes[index],
                    isSummarizing:
                        _summarizingIds[notes[index]['id']] ?? false,
                    onSummarize: () => _summarize(
                      notes[index]['id'],
                      notes[index]['content'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
