import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/responsive.dart';
import 'ai_pulsar.dart';

class HomeHeader extends StatelessWidget {
  final bool isProcessingCommand;
  final bool isJarvisOnline;
  final VoidCallback onOpenDashboard;
  final VoidCallback onLogout;
  final bool isAuthGuest;

  const HomeHeader({
    super.key,
    required this.isProcessingCommand,
    required this.isJarvisOnline,
    required this.onOpenDashboard,
    required this.onLogout,
    this.isAuthGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ContextShift',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: -1,
                        fontWeight: FontWeight.w900,
                        fontSize: Responsive.isMobile(context) ? 28 : 36,
                      ),
                ),
                Text(
                  '${DatabaseService.instance.firstName}\'s Sanctuary',
                  style: TextStyle(
                    color: AppTheme.primary,
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
                icon: LucideIcons.barChart2,
                onTap: onOpenDashboard,
              ),
              if (!isAuthGuest) ...[
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: LucideIcons.logOut,
                  onTap: onLogout,
                ),
              ],
              const SizedBox(width: 8),
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

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceHigh,
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
