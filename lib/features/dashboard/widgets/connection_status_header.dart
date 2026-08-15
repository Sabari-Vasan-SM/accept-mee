import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/projects_provider.dart';
import '../../../services/antigravity_client.dart';

class ConnectionStatusHeader extends ConsumerWidget {
  const ConnectionStatusHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatusAsync = ref.watch(connectionStatusProvider);
    final agentStateAsync = ref.watch(agentStateProvider);
    final activeProject = ref.watch(activeProjectProvider);

    final connectionStatus = connectionStatusAsync.value ?? ConnectionStatus.disconnected;
    final agentState = agentStateAsync.value;

    final isOnline = connectionStatus == ConnectionStatus.connected;
    final computerName = agentState?.connectedComputer ?? 'MacBook Pro';
    final projectName = activeProject?.name ?? 'ecommerce-admin';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left Title & Status Gem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'ANTIGRAVITY',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // M3 Expressive Live Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.tertiaryContainer
                              : AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? AppColors.tertiary
                                    : AppColors.statusError,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              connectionStatus.label,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                color: isOnline
                                    ? AppColors.onTertiaryContainer
                                    : AppColors.onErrorContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.laptop_mac_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          computerName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Project Selector Pill
                      InkWell(
                        onTap: () {
                          HapticUtil.selection();
                          context.go('/projects');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                projectName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 14, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Action Shortcuts
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                HapticUtil.selection();
                context.push('/pairing');
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary),
              tooltip: 'Pair Device',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                HapticUtil.selection();
                context.go('/settings');
              },
              icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.textSecondary),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
