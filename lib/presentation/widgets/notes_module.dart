import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';

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
    _noteController.clear();
    setState(() => _isAdding = false);
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

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) => _buildNoteCard(notes[index]),
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

  Widget _buildNoteCard(Map<String, dynamic> note) {
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
              Expanded(
                child: Text(
                  note['content'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              if ((note['tags'] as List?)?.isNotEmpty ?? false)
                Text(
                  (note['tags'] as List).map((t) => '#$t').join(' '),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 10),
                ),
            ],
          ),
          Positioned(
            right: -8,
            bottom: -8,
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
        padding: const EdgeInsets.symmetric(vertical: 40.0),
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
