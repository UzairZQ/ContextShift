import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/local_llm/model_downloader.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../onboarding/widgets/model_download_screen.dart';

class ModelManagementTile extends StatefulWidget {
  const ModelManagementTile({super.key});

  @override
  State<ModelManagementTile> createState() => _ModelManagementTileState();
}

class _ModelManagementTileState extends State<ModelManagementTile> {
  final Map<String, bool> _downloadStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    debugPrint('[ModelManagementTile] Refreshing download status...');
    setState(() => _loading = true);
    try {
      final e2b = await ModelDownloader.instance.isModelDownloaded(
        ModelDefinition.e2b,
      );
      final e4b = await ModelDownloader.instance.isModelDownloaded(
        ModelDefinition.e4b,
      );
      debugPrint('[ModelManagementTile] E2B: $e2b, E4B: $e4b');
      if (mounted) {
        setState(() {
          _downloadStatus['e2b'] = e2b;
          _downloadStatus['e4b'] = e4b;
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[ModelManagementTile] Error refreshing: $e');
      debugPrint('[ModelManagementTile]   Stack: $stack');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'AI Models',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          )
        else ...[
          _buildModelCard(ModelDefinition.e2b, _downloadStatus['e2b'] ?? false),
          const SizedBox(height: 12),
          _buildModelCard(ModelDefinition.e4b, _downloadStatus['e4b'] ?? false),
        ],
      ],
    );
  }

  Widget _buildModelCard(ModelDefinition model, bool isDownloaded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              model.tier == ModelTier.e2b
                  ? LucideIcons.zap
                  : LucideIcons.sparkles,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemma 4 ${model.displayName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDownloaded
                      ? '${model.downloadSizeFormatted} — Installed'
                      : model.downloadSizeFormatted,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDownloaded
                        ? AppTheme.success
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(model, isDownloaded),
        ],
      ),
    );
  }

  Widget _buildActionButton(ModelDefinition model, bool isDownloaded) {
    if (isDownloaded) {
      return PopupMenuButton<String>(
        icon: const Icon(
          LucideIcons.moreVertical,
          color: AppTheme.onSurfaceVariant,
        ),
        color: AppTheme.surfaceHigh,
        onSelected: (value) async {
          if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.background,
                title: const Text(
                  'Delete Model?',
                  style: TextStyle(color: AppTheme.onSurface),
                ),
                content: Text(
                  'Delete ${model.displayName} (${model.downloadSizeFormatted})? '
                  'It will need to be re-downloaded.',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              debugPrint('[ModelManagementTile] Deleting ${model.displayName}');
              await ModelDownloader.instance.deleteModel(model);
              _refreshStatus();
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 18, color: AppTheme.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppTheme.error)),
              ],
            ),
          ),
        ],
      );
    }

    if (model.requiresPurchase) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Premium',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.warning,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        debugPrint(
          '[ModelManagementTile] Navigate to download: ${model.displayName}',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModelDownloadScreen(
              model: model,
              isOnboarding: false,
              onComplete: () {
                Navigator.pop(context);
                _refreshStatus();
              },
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Download',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
