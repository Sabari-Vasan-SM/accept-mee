import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/activity_provider.dart';
import 'widgets/activity_item_tile.dart';

class LiveActivityScreen extends ConsumerWidget {
  const LiveActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEvents = ref.watch(filteredActivityProvider);
    final activeFilter = ref.watch(activityFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Agent Activity', style: AppTypography.headlineMedium),
      ),
      body: Column(
        children: [
          // M3 Expressive Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  ref,
                  label: 'All',
                  icon: Icons.all_inclusive_rounded,
                  filter: ActivityFilter.all,
                  isSelected: activeFilter == ActivityFilter.all,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'File Edits',
                  icon: Icons.edit_note_rounded,
                  filter: ActivityFilter.fileEdits,
                  isSelected: activeFilter == ActivityFilter.fileEdits,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'Terminal',
                  icon: Icons.terminal_rounded,
                  filter: ActivityFilter.commands,
                  isSelected: activeFilter == ActivityFilter.commands,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'Tests',
                  icon: Icons.science_rounded,
                  filter: ActivityFilter.tests,
                  isSelected: activeFilter == ActivityFilter.tests,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'Approvals',
                  icon: Icons.shield_rounded,
                  filter: ActivityFilter.approvals,
                  isSelected: activeFilter == ActivityFilter.approvals,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: const Icon(Icons.stream_rounded, size: 40, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events in this category',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: filteredEvents.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ActivityItemTile(event: filteredEvents[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ActivityFilter filter,
    required bool isSelected,
  }) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppColors.onPrimaryContainer : AppColors.textSecondary,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticUtil.selection();
        ref.read(activityFilterProvider.notifier).state = filter;
      },
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimaryContainer,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.onPrimaryContainer : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
    );
  }
}
