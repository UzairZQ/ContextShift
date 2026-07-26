import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'about_context_shift_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsInfoScaffold(
      title: 'Privacy',
      subtitle: 'Your productivity data is designed to stay on your phone.',
      icon: LucideIcons.shieldCheck,
      children: [
        InfoHero(
          title: 'Private by default.',
          body:
              'ContextShift is built as an offline-first app. Your tasks, habits, focus sessions, notes, mood logs, chat history, saved cards, and local JARVIS memory are stored on your device in the app database.',
        ),
        InfoCard(
          icon: LucideIcons.database,
          title: 'What stays local',
          body:
              'Your profile, tasks, habits, notes, mood entries, focus history, generated cards, and JARVIS conversations are saved locally. They are not uploaded to a ContextShift server.',
        ),
        InfoCard(
          icon: LucideIcons.cpu,
          title: 'On-device AI',
          body:
              'When you download the Gemma model, JARVIS can answer and generate cards on-device. The app builds a compact local context snapshot from your own data and sends it to the model running on your phone.',
        ),
        InfoCard(
          icon: LucideIcons.hardDriveDownload,
          title: 'Model downloads',
          body:
              'The model download needs internet access because the model file is fetched from the configured download source. After that, normal JARVIS inference is designed to run locally.',
        ),
        InfoCard(
          icon: LucideIcons.mic,
          title: 'Dictation',
          body:
              'If you use voice input, speech recognition is handled by the operating system speech service. You can avoid dictation and type instead if you prefer.',
        ),
        InfoCard(
          icon: LucideIcons.bug,
          title: 'Crash diagnostics',
          body:
              'Crash reports, when enabled for release builds, are used only to understand why the app crashed and where it failed. They are not meant to collect your tasks, notes, chats, habits, mood logs, or generated card content.',
        ),
        InfoCard(
          icon: LucideIcons.cloudOff,
          title: 'What we do not do',
          body:
              'No account is required, no cloud sync is required, and your day-to-day productivity content is not sent to an app backend for AI processing.',
        ),
      ],
    );
  }
}
