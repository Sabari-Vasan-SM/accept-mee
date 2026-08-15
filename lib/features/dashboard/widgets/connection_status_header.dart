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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Computer and project info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'ANTIGRAVITY',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Live Pulsing Dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.statusSuccess : AppColors.statusError,
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline ? AppColors.statusSuccess : AppColors.statusError)
                                  .withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connectionStatus.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isOnline ? AppColors.statusSuccess : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.laptop_mac_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
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
                      Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                      // Project Chip
                      InkWell(
                        onTap: () {
                          HapticUtil.selection();
                          context.go('/projects');
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_outlined, size: 12, color: AppColors.primaryLight),
                              const SizedBox(width: 4),
                              Text(
                                projectName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
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

            // Pairing / Settings Shortcuts
            IconButton(
              onPressed: () {
                HapticUtil.selection();
                context.push('/pairing');
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryLight),
              tooltip: 'Pair Device',
            ),
            IconButton(
              onPressed: () {
                HapticUtil.selection();
                context.go('/settings');
              },
              icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
