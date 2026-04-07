import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'widgets/greeting_module.dart';
import 'widgets/task_module.dart';
import 'widgets/habit_module.dart';
import 'widgets/focus_module.dart';
import 'widgets/ai_insights_module.dart';

class ContextShiftCatalog {
  static Catalog getCatalog() {
    final greetingItem = CatalogItem(
      name: 'GreetingModule',
      dataSchema: S.object(properties: {'greetingText': S.string()}),
      widgetBuilder: (context) {
        final dataMap = context.data as Map<String, dynamic>?;
        final text = dataMap?['greetingText'] as String?;
        return text != null ? GreetingModule(greetingText: text) : const GreetingModule();
      },
    );

    final aiInsightItem = CatalogItem(
      name: 'AiInsightsModule',
      dataSchema: S.object(properties: {'insightText': S.string()}),
      widgetBuilder: (context) {
        final dataMap = context.data as Map<String, dynamic>?;
        final text = dataMap?['insightText'] as String?;
        return text != null ? AiInsightsModule(insightText: text) : const AiInsightsModule();
      },
    );

    final focusItem = CatalogItem(
      name: 'FocusTimerModule',
      dataSchema: S.object(),
      widgetBuilder: (context) => const FocusTimerModule(),
    );

    final taskItem = CatalogItem(
      name: 'TasksModule',
      dataSchema: S.object(),
      widgetBuilder: (context) => const TasksModule(),
    );

    final habitItem = CatalogItem(
      name: 'HabitModule',
      dataSchema: S.object(),
      widgetBuilder: (context) => const HabitModule(),
    );

    final rootItem = CatalogItem(
      name: 'RootLayout',
      dataSchema: S.object(),
      widgetBuilder: (context) {
        final dataMap = context.data as Map<String, dynamic>?;
        final childIds = dataMap?['children'] as List<dynamic>? ?? [];
        return Column(
          children: childIds.map((id) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: context.buildChild(id as String),
          )).toList(),
        );
      },
    );

    return Catalog([
      rootItem,
      greetingItem,
      aiInsightItem,
      focusItem,
      taskItem,
      habitItem,
    ], catalogId: 'context_shift_catalog');
  }
}
