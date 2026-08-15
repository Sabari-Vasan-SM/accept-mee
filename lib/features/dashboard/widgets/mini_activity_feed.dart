import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/activity_event.dart';
import '../../../providers/activity_provider.dart';

class MiniActivityFeed extends ConsumerWidget {
  const MiniActivityFeed({super.key});

  IconData _getEventIcon(ActivityType type) {
    switch (type) {
      case ActivityType.fileEdit:
        return Icons.edit_document;
      case ActivityType.terminalCommand:
        return Icons.terminal_rounded;
      case ActivityType.testRun:
        return Icons.science_rounded;
      case ActivityType.approvalGranted:
        return Icons.verified_rounded;
      case ActivityType.approvalDenied:
        return Icons.block_rounded;
      case ActivityType.userInstruction:
        return Icons.chat_bubble_outline_rounded;
      case ActivityType.taskComplete:
        return Icons.check_circle_rounded;
      case ActivityType.errorWarning:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getEventColor(ActivityType type) {
    switch (type) {
      case ActivityType.fileEdit:
        return AppColors.primary;
      case ActivityType.terminalCommand:
        return AppColors.secondary;
      case ActivityType.testRun:
        return AppColors.statusSuccess;
      case ActivityType.approvalGranted:
        return AppColors.statusSuccess;
      case ActivityType.approvalDenied:
        return AppColors.statusError;
      case ActivityType.userInstruction:
        return AppColors.primaryLight;
      case ActivityType.taskComplete:
        return AppColors.statusSuccess;
      case ActivityType.errorWarning:
        return AppColors.statusWarning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityStreamProvider);
    final events = activityAsync.value ?? [];
    final recentEvents = events.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
                HapticUtil.selection();
                context.go('/activity');
              },
              child: Row(
                children: [
                  Text(
                    'Live Stream',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (recentEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Center(
              child: Text(
                'No activity events recorded yet.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentEvents.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final item = recentEvents[index];
                final iconColor = _getEventColor(item.type);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getEventIcon(item.type), size: 16, color: iconColor),
                  ),
                  title: Text(
                    item.title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.description,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateUtil.formatTimeAgo(item.timestamp),
                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                  onTap: () {
                    HapticUtil.selection();
                    context.go('/activity');
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
