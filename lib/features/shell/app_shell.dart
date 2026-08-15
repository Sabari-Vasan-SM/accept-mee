import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/haptic_feedback_util.dart';
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

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          backgroundColor: AppColors.surfaceElevated,
          indicatorColor: AppColors.primary.withOpacity(0.18),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.stream_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.stream_rounded, color: AppColors.primary),
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
                child: const Icon(Icons.verified_user_outlined, color: AppColors.textMuted),
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
                child: const Icon(Icons.verified_user_rounded, color: AppColors.primary),
              ),
              label: 'Approvals',
            ),
            const NavigationDestination(
              icon: Icon(Icons.folder_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.folder_rounded, color: AppColors.primary),
              label: 'Projects',
            ),
            const NavigationDestination(
              icon: Icon(Icons.devices_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.devices_rounded, color: AppColors.primary),
              label: 'Devices',
            ),
            const NavigationDestination(
              icon: Icon(Icons.tune_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.tune_rounded, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
