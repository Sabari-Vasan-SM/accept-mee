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
        return Icons.memory_rounded;
      case AgentStatus.waitingForApproval:
        return Icons.notification_important_rounded;
      case AgentStatus.paused:
        return Icons.pause_circle_rounded;
      case AgentStatus.completed:
        return Icons.check_circle_rounded;
      case AgentStatus.error:
        return Icons.error_outline_rounded;
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
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: state.status == AgentStatus.waitingForApproval
              ? AppColors.statusApproval.withOpacity(0.6)
              : AppColors.surfaceBorderHighlight,
          width: state.status == AgentStatus.waitingForApproval ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI Agent Badge & Uptime
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(state.status), size: 14, color: statusColor)
                        .animate(target: state.status == AgentStatus.working ? 1 : 0)
                        .rotate(duration: const Duration(seconds: 4)),
                    const SizedBox(width: 6),
                    Text(
                      state.status.label.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              if (state.uptimeSeconds > 0)
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateUtil.formatDuration(state.uptimeSeconds),
                      style: AppTypography.codeSnippet.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Main Task Description
          Text(
            state.currentTask,
            style: AppTypography.titleLarge.copyWith(
              fontSize: 18,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Micro Action / Current Step
          if (state.currentAction.isNotEmpty)
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.currentAction,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Progress Bar & Percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Progress',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    '${state.progress}%',
                    style: AppTypography.codeSnippet.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: state.progress / 100.0,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Agent Controls (Resume, Pause, Retry, Stop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: state.status == AgentStatus.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: state.status == AgentStatus.paused ? 'Resume' : 'Pause',
                color: AppColors.primary,
                onTap: () {
                  HapticUtil.medium();
                  if (state.status == AgentStatus.paused) {
                    client.resumeAgent();
                  } else {
                    client.pauseAgent();
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.replay_rounded,
                label: 'Retry',
                color: AppColors.textSecondary,
                onTap: () {
                  HapticUtil.medium();
                  client.retryTask();
                },
              ),
              _buildControlButton(
                icon: Icons.stop_circle_outlined,
                label: 'Stop',
                color: AppColors.statusError,
                onTap: () => _showStopConfirmDialog(context, client),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopConfirmDialog(BuildContext context, dynamic client) {
    HapticUtil.medium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.statusError, size: 24),
            const SizedBox(width: 10),
            Text('Stop Agent?', style: AppTypography.titleLarge),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
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
