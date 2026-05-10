import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import './task_module.dart';

class GenerativeCardModule extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback? onAction;

  const GenerativeCardModule({
    super.key,
    required this.cardData,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = cardData['title'] as String? ?? 'Intelligence';
    final type = cardData['type'] as String? ?? 'advice'; // workout | planner | advice
    final description = cardData['description'] as String? ?? '';
    final listItems = (cardData['list_items'] as List<dynamic>?) ?? [];
    final actionLabel = cardData['action_label'] as String?;

    IconData headerIcon = LucideIcons.sparkles;
    Color themeColor = AppTheme.primary;

    if (type == 'workout') {
      headerIcon = LucideIcons.dumbbell;
      themeColor = Colors.orangeAccent;
    } else if (type == 'planner') {
      headerIcon = LucideIcons.calendarClock;
      themeColor = Colors.cyanAccent;
    } else if (type == 'advice') {
      headerIcon = LucideIcons.lightbulb;
      themeColor = Colors.purpleAccent;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (type == 'planner' || type == 'workout')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'INTERACTABLE',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // List Items
          if (listItems.isNotEmpty)
            ...listItems.map((item) {
              final String text = (item is Map) ? (item['text'] ?? '') : item.toString();
              final Map<String, dynamic>? taskPayload =
                  (item is Map && item['task_payload'] is Map)
                      ? Map<String, dynamic>.from(item['task_payload'] as Map)
                      : null;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: (taskPayload != null)
                    ? () => TasksModule.showAddTaskSheet(
                        context,
                        initialTitle: taskPayload['title'],
                        initialPriority: taskPayload['priority'],
                      )
                    : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: taskPayload != null 
                          ? themeColor.withValues(alpha: 0.15) 
                          : Colors.white.withValues(alpha: 0.05)
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            taskPayload != null ? LucideIcons.plusCircle : LucideIcons.checkCircle2,
                            color: taskPayload != null ? themeColor : themeColor.withValues(alpha: 0.4),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: taskPayload != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          
          if (listItems.isNotEmpty) const SizedBox(height: 8),

          // Action Button (Optional footer action)
          if (actionLabel != null && actionLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.withValues(alpha: 0.2),
                  foregroundColor: themeColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: themeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  actionLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
