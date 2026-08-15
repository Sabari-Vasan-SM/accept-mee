import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/permission_request.dart';
import '../../../providers/antigravity_provider.dart';

class ApprovalDetailSheet extends ConsumerStatefulWidget {
  final PermissionRequest request;

  const ApprovalDetailSheet({super.key, required this.request});

  @override
  ConsumerState<ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends ConsumerState<ApprovalDetailSheet> {
  final _reasonController = TextEditingController();
  bool _showReasonField = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final client = ref.read(antigravityClientProvider);
    final req = widget.request;
    final riskColor = _getRiskColor(req.riskLevel);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // Header Title & Risk Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.title,
                    style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${req.riskLevel.name.toUpperCase()} RISK',
                    style: AppTypography.labelSmall.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Command / Action Payload Box
            Text(
              'Requested Command',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: SelectableText(
                req.details.command ?? req.description,
                style: AppTypography.codeSnippet.copyWith(fontSize: 14),
              ),
            ),

            const SizedBox(height: 18),

            // Metadata Grid
            _buildMetaRow('Project', req.project, Icons.folder_rounded),
            const SizedBox(height: 10),
            _buildMetaRow('Device', req.device, Icons.laptop_mac_rounded),
            const SizedBox(height: 10),
            _buildMetaRow('Requested', DateUtil.formatTimeAgo(req.createdAt), Icons.schedule_rounded),

            if (req.details.impact != null) ...[
              const SizedBox(height: 16),
              Text(
                'Impact Analysis',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  req.details.impact!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],

            if (_showReasonField) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Optional denial feedback or instructions...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                // DENY BUTTON
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusError,
                      side: const BorderSide(color: AppColors.statusError, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      if (!_showReasonField) {
                        setState(() => _showReasonField = true);
                      } else {
                        HapticUtil.error();
                        client.denyRequest(
                          req.id,
                          reason: _reasonController.text.trim().isNotEmpty
                              ? _reasonController.text.trim()
                              : null,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _showReasonField ? 'CONFIRM' : 'DENY',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.statusError,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ALLOW ONCE
                Expanded(
                  flex: 4,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      HapticUtil.success();
                      client.approveRequest(req.id, alwaysAllow: false);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'ALLOW ONCE',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ALWAYS ALLOW
                Expanded(
                  flex: 4,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      HapticUtil.success();
                      client.approveRequest(req.id, alwaysAllow: true);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'ALWAYS',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
