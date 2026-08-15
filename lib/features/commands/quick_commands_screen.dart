import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/quick_commands_provider.dart';
import 'edit_command_dialog.dart';

class QuickCommandsScreen extends ConsumerWidget {
  const QuickCommandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.watch(quickCommandsProvider);
    final client = ref.read(antigravityClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Commands', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Add Custom Command',
            onPressed: () {
              HapticUtil.selection();
              showDialog(
                context: context,
                builder: (ctx) => const EditCommandDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore_rounded, color: AppColors.textMuted),
            tooltip: 'Reset Defaults',
            onPressed: () {
              HapticUtil.medium();
              ref.read(quickCommandsProvider.notifier).resetDefaults();
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: commands.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cmd = commands[index];
          final color = cmd.color ?? AppColors.primary;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  HapticUtil.medium();
                  client.sendInstruction(cmd.instruction, source: 'quick_command');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text(
                        'Triggered: "${cmd.label}"',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryLight),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(cmd.icon, size: 22, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cmd.label,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cmd.instruction,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          HapticUtil.selection();
                          showDialog(
                            context: context,
                            builder: (ctx) => EditCommandDialog(initialCommand: cmd),
                          );
                        },
                      ),
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
