import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/permission_request.dart';
import '../../../providers/antigravity_provider.dart';
import '../approval_detail_sheet.dart';

class ApprovalCard extends ConsumerWidget {
  final PermissionRequest request;

  const ApprovalCard({super.key, required this.request});

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return AppColors.statusError;
      case RiskLevel.medium:
        return AppColors.statusWarning;
      case RiskLevel.low:
        return AppColors.statusSuccess;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(antigravityClientProvider);
    final riskColor = _getRiskColor(request.riskLevel);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineVariant, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticUtil.selection();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => ApprovalDetailSheet(request: request),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type & Risk Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            request.type == 'terminal_command'
                                ? Icons.terminal_rounded
                                : Icons.shield_rounded,
                            size: 18,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          request.title,
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${request.riskLevel.name.toUpperCase()} RISK',
                        style: AppTypography.labelSmall.copyWith(
                          color: riskColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

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
                    request.description,
                    style: AppTypography.codeSnippet.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 12),

                // Project & Time
                Row(
                  children: [
                    const Icon(Icons.folder_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      request.project,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      DateUtil.formatTimeAgo(request.createdAt),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    // Deny
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusError,
                          side: const BorderSide(color: AppColors.statusError, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          HapticUtil.error();
                          client.denyRequest(request.id);
                        },
                        child: Text(
                          'DENY',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.statusError,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Allow Once
                    Expanded(
                      flex: 6,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          HapticUtil.success();
                          client.approveRequest(request.id, alwaysAllow: false);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'ALLOW ONCE',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontSize: 13,
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
