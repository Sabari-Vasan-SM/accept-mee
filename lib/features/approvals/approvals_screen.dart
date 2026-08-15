import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../providers/approvals_provider.dart';
import 'widgets/approval_card.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovalsAsync = ref.watch(pendingApprovalsProvider);
    final approvals = pendingApprovalsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Approvals',
          style: AppTypography.headlineMedium,
        ),
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
                      'Nothing is waiting on you. Approval cards appear here the '
                      'moment Antigravity asks permission to run a tool.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
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
