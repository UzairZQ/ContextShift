import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/responsive.dart';
import '../../../widgets/context_shift_wordmark.dart';
import 'ai_pulsar.dart';

class HomeHeader extends StatelessWidget {
  final bool isProcessingCommand;
  final bool isJarvisOnline;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenProfile;
  final bool isAuthGuest;
  final bool hideWordmark;

  const HomeHeader({
    super.key,
    required this.isProcessingCommand,
    required this.isJarvisOnline,
    required this.onOpenDashboard,
    required this.onOpenProfile,
    this.isAuthGuest = false,
    this.hideWordmark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Spacing.xxl, bottom: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: hideWordmark ? 0 : 1,
                  child: const ContextShiftWordmark(),
                ),
                Text(
                  '${DatabaseService.instance.firstName}\'s sanctuary',
                  style: TextStyle(
                    color: AppTheme.intelligence,
                    fontSize: Responsive.isMobile(context) ? 10 : 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CircleIconButton(
                icon: LucideIcons.chartNoAxesColumn,
                onTap: onOpenDashboard,
                tooltip: 'Dashboard',
              ),
              SizedBox(width: Spacing.sm),
              _CircleIconButton(
                icon: LucideIcons.settings,
                onTap: onOpenProfile,
                tooltip: 'Settings',
              ),
              SizedBox(width: Spacing.sm),
              SizedBox(
                width: 40,
                height: 40,
                child: AiPulsar(
                  isAnalyzing: isProcessingCommand,
                  isOnline: isJarvisOnline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceHigh,
            shape: const CircleBorder(),
            minimumSize: const Size(HitTarget.icon, HitTarget.icon),
            fixedSize: const Size(HitTarget.icon, HitTarget.icon),
          ),
          splashRadius: 24,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
