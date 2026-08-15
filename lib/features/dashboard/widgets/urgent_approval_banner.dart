import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/approvals_provider.dart';

class UrgentApprovalBanner extends ConsumerWidget {
  const UrgentApprovalBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovalsAsync = ref.watch(pendingApprovalsProvider);
    final client = ref.read(antigravityClientProvider);

    final approvals = pendingApprovalsAsync.value ?? [];
    if (approvals.isEmpty) return const SizedBox.shrink();

    final req = approvals.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.approvalContainer,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.statusApproval, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusApproval.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticUtil.selection();
            context.push('/approvals');
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgent Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.statusApproval,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.15, 1.15),
                              duration: 800.ms,
                            ),
                        const SizedBox(width: 10),
                        Text(
                          'PERMISSION REQUIRED',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.onApprovalContainer,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    if (approvals.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${approvals.length - 1} more',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.statusApproval,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  'Antigravity wants to execute command:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onApprovalContainer.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                // Command Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Text(
                    req.description,
                    style: AppTypography.codeSnippet.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.folder_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      'Project: ${req.project}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      'Inspect Details →',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Large Expressive Action Buttons
                Row(
                  children: [
                    // DENY BUTTON
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusError,
                          side: const BorderSide(color: AppColors.statusError, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          HapticUtil.error();
                          client.denyRequest(req.id);
                        },
                        child: Text(
                          'DENY',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.statusError,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ALLOW ONCE BUTTON
                    Expanded(
                      flex: 6,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          HapticUtil.success();
                          client.approveRequest(req.id, alwaysAllow: false);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ALLOW ONCE',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
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
          ),
        ),
      ),
    );
  }
}
