import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/projects_provider.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  IconData _getProjectIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_bag_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'attach_money':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.code_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final agentStateAsync = ref.watch(agentStateProvider);
    final client = ref.read(antigravityClientProvider);

    final projects = projectsAsync.value ?? [];
    final activeProjectId = agentStateAsync.value?.activeProject ?? 'ecommerce-admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Projects', style: AppTypography.headlineMedium),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: projects.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final project = projects[index];
          final isActive = project.id == activeProjectId;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.outlineVariant,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  HapticUtil.selection();
                  client.selectProject(project.id);
                  context.go('/dashboard');
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _getProjectIcon(project.icon),
                              size: 24,
                              color: isActive ? AppColors.onPrimaryContainer : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      project.name,
                                      style: AppTypography.headlineMedium.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.onPrimaryContainer,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.fork_right_rounded,
                                        size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      project.branch,
                                      style: AppTypography.codeSnippet.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isActive
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isActive ? AppColors.primary : AppColors.textMuted,
                            size: 24,
                          ),
                        ],
                      ),
                      if (project.path.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text(
                            project.path,
                            style: AppTypography.codeSnippet.copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
