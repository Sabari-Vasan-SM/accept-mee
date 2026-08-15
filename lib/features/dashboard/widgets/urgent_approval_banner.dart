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
        color: const Color(0xFF261908),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.statusApproval, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusApproval.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticUtil.selection();
            context.push('/approvals');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgent Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: AppColors.statusApproval,
                          size: 20,
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.15, 1.15),
                              duration: 800.ms,
                            ),
                        const SizedBox(width: 8),
                        Text(
                          'PERMISSION REQUIRED',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.statusApproval,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (approvals.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusApproval.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${approvals.length - 1} more',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.statusApproval,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Antigravity wants to execute:',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 8),

                // Command Display Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    req.description,
                    style: AppTypography.codeSnippet.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Project: ${req.project}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to inspect',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Buttons: Large and easy to tap with one hand
                Row(
                  children: [
                    // DENY BUTTON
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusError,
                          side: const BorderSide(color: AppColors.statusError, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ALLOW ONCE BUTTON
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.statusSuccess.withOpacity(0.4),
                        ),
                        onPressed: () {
                          HapticUtil.success();
                          client.approveRequest(req.id, alwaysAllow: false);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'ALLOW ONCE',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
