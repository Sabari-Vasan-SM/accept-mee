import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/haptic_feedback_util.dart';
import '../../providers/antigravity_provider.dart';
import '../../providers/approvals_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/activity')) return 1;
    if (location.startsWith('/approvals')) return 2;
    if (location.startsWith('/projects')) return 3;
    if (location.startsWith('/devices')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticUtil.selection();
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/activity');
        break;
      case 2:
        context.go('/approvals');
        break;
      case 3:
        context.go('/projects');
        break;
      case 4:
        context.go('/devices');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovalsCount = ref.watch(pendingApprovalsCountProvider);
    final selectedIndex = _calculateSelectedIndex(context);

    // One place to surface real failures from the desktop — a rejected token,
    // an unconfigured agent command, a command the server refused.
    ref.listen(clientErrorProvider, (previous, next) {
      final message = next.value;
      if (message == null || message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onErrorContainer),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => _onItemTapped(idx, context),
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primaryContainer,
            elevation: 0,
            height: 66,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.grid_view_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.onPrimaryContainer),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.insights_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.insights_rounded, color: AppColors.onPrimaryContainer),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingApprovalsCount > 0,
                  label: Text(
                    '$pendingApprovalsCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  backgroundColor: AppColors.statusApproval,
                  child: const Icon(Icons.shield_outlined, color: AppColors.textMuted),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingApprovalsCount > 0,
                  label: Text(
                    '$pendingApprovalsCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  backgroundColor: AppColors.statusApproval,
                  child: const Icon(Icons.shield_rounded, color: AppColors.onPrimaryContainer),
                ),
                label: 'Approvals',
              ),
              const NavigationDestination(
                icon: Icon(Icons.folder_open_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.folder_rounded, color: AppColors.onPrimaryContainer),
                label: 'Projects',
              ),
              const NavigationDestination(
                icon: Icon(Icons.devices_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.devices_rounded, color: AppColors.onPrimaryContainer),
                label: 'Devices',
              ),
              const NavigationDestination(
                icon: Icon(Icons.tune_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.tune_rounded, color: AppColors.onPrimaryContainer),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
