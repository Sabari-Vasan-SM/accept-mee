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
        return Icons.edit_note_rounded;
      case ActivityType.terminalCommand:
        return Icons.terminal_rounded;
      case ActivityType.testRun:
        return Icons.science_rounded;
      case ActivityType.approvalGranted:
        return Icons.verified_user_rounded;
      case ActivityType.approvalDenied:
        return Icons.cancel_rounded;
      case ActivityType.userInstruction:
        return Icons.forum_rounded;
      case ActivityType.taskComplete:
        return Icons.task_alt_rounded;
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
        return AppColors.tertiary;
      case ActivityType.approvalGranted:
        return AppColors.statusSuccess;
      case ActivityType.approvalDenied:
        return AppColors.statusError;
      case ActivityType.userInstruction:
        return AppColors.onPrimaryContainer;
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
              style: AppTypography.headlineMedium.copyWith(fontSize: 18),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () {
                HapticUtil.selection();
                context.go('/activity');
              },
              label: Text(
                'Live Stream',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (recentEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Text(
                'No activity events recorded yet.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Material(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentEvents.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1, indent: 64),
                itemBuilder: (context, index) {
                  final item = recentEvents[index];
                  final iconColor = _getEventColor(item.type);

                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getEventIcon(item.type), size: 18, color: iconColor),
                    ),
                    title: Text(
                      item.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.description,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateUtil.formatTimeAgo(item.timestamp),
                        style: AppTypography.labelSmall.copyWith(fontSize: 10),
                      ),
                    ),
                    onTap: () {
                      HapticUtil.selection();
                      context.go('/activity');
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
