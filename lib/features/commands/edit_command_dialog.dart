import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/quick_command.dart';
import '../../../providers/quick_commands_provider.dart';

class EditCommandDialog extends ConsumerStatefulWidget {
  final QuickCommand? initialCommand;

  const EditCommandDialog({super.key, this.initialCommand});

  @override
  ConsumerState<EditCommandDialog> createState() => _EditCommandDialogState();
}

class _EditCommandDialogState extends ConsumerState<EditCommandDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _instructionController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<IconData> _availableIcons = [
    Icons.play_arrow_rounded,
    Icons.bug_report_rounded,
    Icons.science_rounded,
    Icons.search_rounded,
    Icons.cleaning_services_rounded,
    Icons.inventory_2_rounded,
    Icons.commit_rounded,
    Icons.build_rounded,
    Icons.terminal_rounded,
    Icons.refresh_rounded,
    Icons.flash_on_rounded,
    Icons.stop_circle_rounded,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF00E5FF),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialCommand?.label ?? '');
    _instructionController =
        TextEditingController(text: widget.initialCommand?.instruction ?? '');
    _selectedIcon = widget.initialCommand?.icon ?? Icons.flash_on_rounded;
    _selectedColor = widget.initialCommand?.color ?? AppColors.primary;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialCommand == null;

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isNew ? 'New Quick Command' : 'Edit Quick Command',
        style: AppTypography.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Button Label', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _labelController,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Run Linter',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text('Agent Instruction', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _instructionController,
              maxLines: 3,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Check for typescript errors and lint warnings...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Select Icon', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () {
                    HapticUtil.selection();
                    setState(() => _selectedIcon = icon);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withOpacity(0.25) : AppColors.surfaceCard,
                      border: Border.all(
                        color: isSelected ? _selectedColor : AppColors.surfaceBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: isSelected ? _selectedColor : AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            Text('Accent Color', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () {
                    HapticUtil.selection();
                    setState(() => _selectedColor = color);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final instruction = _instructionController.text.trim();
            if (label.isEmpty || instruction.isEmpty) return;

            HapticUtil.success();
            final notifier = ref.read(quickCommandsProvider.notifier);

            if (isNew) {
              notifier.addCommand(
                QuickCommand(
                  id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
                  label: label,
                  instruction: instruction,
                  icon: _selectedIcon,
                  color: _selectedColor,
                ),
              );
            } else {
              notifier.updateCommand(
                QuickCommand(
                  id: widget.initialCommand!.id,
                  label: label,
                  instruction: instruction,
                  icon: _selectedIcon,
                  color: _selectedColor,
                ),
              );
            }

            Navigator.pop(context);
          },
          child: Text(isNew ? 'Create' : 'Save Changes'),
        ),
      ],
    );
  }
}
