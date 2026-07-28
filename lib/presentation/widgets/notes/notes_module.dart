import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../shared/module_cards.dart';
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
  bool _isAdding = false;
  bool _isSaving = false;

  void _toggleAdd() {
    setState(() => _isAdding = !_isAdding);
  }

  Future<void> _submitNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await DatabaseService.instance.addNote(content: content);
      if (!mounted) return;
      _noteController.clear();
      setState(() => _isAdding = false);
    } catch (error, stackTrace) {
      debugPrint('[NotesModule] Save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save note. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        ModuleHeaderCard(
          title: 'Journal archive',
          subtitle: 'Keep the moments worth returning to.',
          icon: LucideIcons.bookOpen,
          accent: AppTheme.primary,
          trailing: IconButton(
            tooltip: _isAdding ? 'Close note editor' : 'Add journal entry',
            onPressed: _toggleAdd,
            icon: Icon(
              _isAdding ? LucideIcons.x : LucideIcons.plus,
              color: AppTheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        if (_isAdding)
          NoteInput(
            controller: _noteController,
            onSubmit: _submitNote,
            isSaving: _isSaving,
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchNotes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Notes are temporarily unavailable. Pull to try again.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              );
            }
            if (!snapshot.hasData) return const SizedBox.shrink();
            final notes = snapshot.data!;
            if (notes.isEmpty) return const NotesEmptyState();

            return LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns(constraints.maxWidth),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(note: notes[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
