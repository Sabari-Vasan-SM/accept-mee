import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/agent_state.dart';
import '../../../providers/antigravity_provider.dart';

class AgentHeroCard extends ConsumerWidget {
  const AgentHeroCard({super.key});

  Color _getStatusColor(AgentStatus status) {
    switch (status) {
      case AgentStatus.working:
        return AppColors.statusWorking;
      case AgentStatus.waitingForApproval:
        return AppColors.statusApproval;
      case AgentStatus.paused:
        return AppColors.statusPaused;
      case AgentStatus.completed:
        return AppColors.statusSuccess;
      case AgentStatus.error:
        return AppColors.statusError;
      case AgentStatus.connecting:
        return AppColors.primary;
      case AgentStatus.idle:
      case AgentStatus.offline:
        return AppColors.statusIdle;
    }
  }

  IconData _getStatusIcon(AgentStatus status) {
    switch (status) {
      case AgentStatus.working:
        return Icons.auto_awesome_rounded;
      case AgentStatus.waitingForApproval:
        return Icons.notification_important_rounded;
      case AgentStatus.paused:
        return Icons.pause_circle_filled_rounded;
      case AgentStatus.completed:
        return Icons.check_circle_rounded;
      case AgentStatus.error:
        return Icons.error_rounded;
      case AgentStatus.connecting:
        return Icons.sync_rounded;
      case AgentStatus.idle:
      case AgentStatus.offline:
        return Icons.radio_button_checked_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentStateAsync = ref.watch(agentStateProvider);
    final client = ref.read(antigravityClientProvider);
    final state = agentStateAsync.value ?? AgentStateModel.initial();
    final statusColor = _getStatusColor(state.status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: state.status == AgentStatus.waitingForApproval
              ? AppColors.statusApproval
              : AppColors.outlineVariant,
          width: state.status == AgentStatus.waitingForApproval ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Agent Status Pill & Uptime Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // M3 Expressive Agent Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(state.status), size: 16, color: statusColor)
                        .animate(target: state.status == AgentStatus.working ? 1 : 0)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.15, 1.15),
                          duration: const Duration(seconds: 1),
                        ),
                    const SizedBox(width: 8),
                    Text(
                      state.status.label.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Uptime Badge
              if (state.uptimeSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        DateUtil.formatDuration(state.uptimeSeconds),
                        style: AppTypography.codeSnippet.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Task Description Headline
          Text(
            state.currentTask,
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Micro Action Banner
          if (state.currentAction.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.currentAction,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Progress Track with Percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Completion',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.progress}%',
                      style: AppTypography.codeSnippet.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progress / 100.0,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // M3 Expressive Action Pill Buttons
          Row(
            children: [
              // Resume / Pause Button
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    HapticUtil.medium();
                    if (state.status == AgentStatus.paused) {
                      client.resumeAgent();
                    } else {
                      client.pauseAgent();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.status == AgentStatus.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.status == AgentStatus.paused ? 'Resume' : 'Pause',
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Retry Button
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    HapticUtil.medium();
                    client.retryTask();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.replay_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text('Retry', style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Stop Button
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorContainer.withValues(alpha: 0.5),
                    foregroundColor: AppColors.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => _showStopConfirmDialog(context, client),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stop_rounded, size: 18, color: AppColors.statusError),
                      const SizedBox(width: 6),
                      Text(
                        'Stop',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.statusError,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStopConfirmDialog(BuildContext context, dynamic client) {
    HapticUtil.medium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.statusError, size: 26),
            const SizedBox(width: 10),
            Text('Stop Agent?', style: AppTypography.headlineMedium),
          ],
        ),
        content: Text(
          'Are you sure you want to stop the active coding agent? Ongoing work will be paused and reset.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              HapticUtil.error();
              client.stopAgent();
              Navigator.pop(ctx);
            },
            child: const Text('Stop Agent'),
          ),
        ],
      ),
    );
  }
}
