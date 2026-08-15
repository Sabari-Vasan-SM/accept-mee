import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/activity_event.dart';

class ActivityItemTile extends StatefulWidget {
  final ActivityEvent event;

  const ActivityItemTile({super.key, required this.event});

  @override
  State<ActivityItemTile> createState() => _ActivityItemTileState();
}

class _ActivityItemTileState extends State<ActivityItemTile> {
  bool _isExpanded = false;

  IconData _getIcon(ActivityType type) {
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

  Color _getColor(ActivityType type) {
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
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = _getColor(event.type);
    final hasDiff = event.diff != null && event.diff!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(event.type), size: 20, color: color),
            ),
            title: Text(
              event.title,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                event.description,
                style: AppTypography.bodyMedium,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateUtil.formatTimeAgo(event.timestamp),
                  style: AppTypography.labelSmall.copyWith(fontSize: 11),
                ),
                if (hasDiff)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            onTap: hasDiff
                ? () {
                    HapticUtil.selection();
                    setState(() => _isExpanded = !_isExpanded);
                  }
                : null,
          ),

          if (hasDiff && _isExpanded) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: AppColors.background,
              child: SelectableText(
                event.diff!,
                style: AppTypography.codeSnippet.copyWith(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
