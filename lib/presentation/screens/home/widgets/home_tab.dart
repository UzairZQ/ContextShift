import 'package:flutter/material.dart';

import '../../../../core/responsive.dart';
import 'ai_command_bar.dart';
import 'ai_insight_card.dart';
import 'ai_response_card.dart';
import 'dynamic_modules.dart';
import 'home_header.dart';
import 'mood_checkin.dart';
import 'stats_section.dart';
import 'thinking_card.dart';

class HomeTab extends StatelessWidget {
  final String greeting;
  final TextEditingController commandController;
  final bool isJarvisOnline;
  final bool hasCheckedJarvisStatus;
  final bool isProcessingCommand;
  final String offlineHint;
  final String? aiResponse;
  final Animation<double> responseAnimation;
  final bool isLoadingInsight;
  final String? aiInsight;
  final int focusMinutesToday;
  final String? todayMood;
  final List<String> moduleOrder;
  final String layoutRefresher;
  final Map<String, dynamic>? generativeCardPayload;
  final VoidCallback onOpenDashboard;
  final VoidCallback onGenerativeCardAction;
  final ValueChanged<String> onSubmitCommand;
  final ValueChanged<String> onSelectMood;
  final VoidCallback onDismissResponse;
  final VoidCallback onLogout;
  final bool isAuthGuest;

  const HomeTab({
    super.key,
    required this.greeting,
    required this.commandController,
    required this.isJarvisOnline,
    required this.hasCheckedJarvisStatus,
    required this.isProcessingCommand,
    required this.offlineHint,
    required this.aiResponse,
    required this.responseAnimation,
    required this.isLoadingInsight,
    required this.aiInsight,
    required this.focusMinutesToday,
    required this.todayMood,
    required this.moduleOrder,
    required this.layoutRefresher,
    required this.generativeCardPayload,
    required this.onOpenDashboard,
    required this.onGenerativeCardAction,
    required this.onSubmitCommand,
    required this.onSelectMood,
    required this.onDismissResponse,
    required this.onLogout,
    required this.isAuthGuest,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(
            isProcessingCommand: isProcessingCommand,
            isJarvisOnline: isJarvisOnline,
            onOpenDashboard: onOpenDashboard,
            onLogout: onLogout,
          ),
          const SizedBox(height: 16),
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  fontSize: Responsive.isMobile(context) ? 20 : 24,
                ),
          ),
          AiCommandBar(
            controller: commandController,
            isOnline: isJarvisOnline,
            isProcessing: isProcessingCommand,
            hasCheckedStatus: hasCheckedJarvisStatus,
            offlineHint: offlineHint,
            onSubmit: onSubmitCommand,
          ),
          const SizedBox(height: 16),
          if (aiResponse != null)
            AiResponseCard(
              animation: responseAnimation,
              message: aiResponse!,
              onDismiss: onDismissResponse,
            ),
          if (isProcessingCommand) const ThinkingCard(),
          DynamicModules(
            moduleOrder: moduleOrder,
            layoutRefresher: layoutRefresher,
            generativeCardPayload: generativeCardPayload,
            onGenerativeCardAction: onGenerativeCardAction,
          ),
          MoodCheckIn(selectedMood: todayMood, onSelect: onSelectMood),
          const SizedBox(height: 16),
          StatsSection(focusMinutesToday: focusMinutesToday),
          const SizedBox(height: 16),
          AiInsightCard(
            insight: aiInsight,
            isLoading: isLoadingInsight,
            onTap: onOpenDashboard,
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 80,
          ),
        ],
      ),
    );
  }
}
