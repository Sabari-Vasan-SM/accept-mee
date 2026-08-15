import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/approvals_provider.dart';
import 'widgets/approval_card.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovalsAsync = ref.watch(pendingApprovalsProvider);
    final client = ref.read(antigravityClientProvider);
    final approvals = pendingApprovalsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Approvals',
          style: AppTypography.headlineMedium,
        ),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.primary),
            tooltip: 'Simulate Approval Request',
            onPressed: () {
              HapticUtil.selection();
              client.triggerDemoScenario('db_migration');
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: approvals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 52,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'All Clear',
                      style: AppTypography.headlineLarge.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No pending permissions or approval requests from Antigravity.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: const Text('Simulate Test Request'),
                      onPressed: () {
                        HapticUtil.medium();
                        client.triggerDemoScenario('db_migration');
                      },
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: approvals.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return ApprovalCard(request: approvals[index]);
              },
            ),
    );
  }
}
