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
          style: AppTypography.titleLarge,
        ),
        actions: [
          // Demo trigger helper button
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.primary),
            tooltip: 'Simulate Approval Request',
            onPressed: () {
              HapticUtil.selection();
              client.triggerDemoScenario('db_migration');
            },
          ),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 48,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'All Clear',
                      style: AppTypography.titleLarge.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No pending permissions or approval requests from Antigravity.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bolt_rounded, size: 18),
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
