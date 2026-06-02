import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class NoteInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const NoteInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
            controller: controller,
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
              onPressed: onSubmit,
              child: const Text(
                'Save Note',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
