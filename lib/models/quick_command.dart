import 'package:flutter/material.dart';

class QuickCommand {
  final String id;
  final String label;
  final String instruction;
  final IconData icon;
  final Color? color;
  final bool isDestructive;

  const QuickCommand({
    required this.id,
    required this.label,
    required this.instruction,
    required this.icon,
    this.color,
    this.isDestructive = false,
  });

  static List<QuickCommand> defaultCommands() {
    return [
      const QuickCommand(
        id: 'cmd_continue',
        label: 'Continue',
        instruction: 'Continue with the next steps of the current task.',
        icon: Icons.play_arrow_rounded,
        color: Color(0xFF00E5FF),
      ),
      const QuickCommand(
        id: 'cmd_fix',
        label: 'Fix Issue',
        instruction: 'Investigate and fix the latest errors, failing tests, or warnings.',
        icon: Icons.bug_report_rounded,
        color: Color(0xFFF59E0B),
      ),
      const QuickCommand(
        id: 'cmd_tests',
        label: 'Run Tests',
        instruction: 'Run the complete test suite and report any failures.',
        icon: Icons.science_rounded,
        color: Color(0xFF10B981),
      ),
      const QuickCommand(
        id: 'cmd_check_errors',
        label: 'Check Errors',
        instruction: 'Check linter, compile errors, and type check status.',
        icon: Icons.search_rounded,
        color: Color(0xFF6366F1),
      ),
      const QuickCommand(
        id: 'cmd_clean',
        label: 'Clean Up Code',
        instruction: 'Format code, remove unused imports, and refactor for cleanliness.',
        icon: Icons.cleaning_services_rounded,
        color: Color(0xFFEC4899),
      ),
      const QuickCommand(
        id: 'cmd_install',
        label: 'Install Deps',
        instruction: 'Install required project dependencies and update lockfile.',
        icon: Icons.inventory_2_rounded,
        color: Color(0xFF3B82F6),
      ),
      const QuickCommand(
        id: 'cmd_commit',
        label: 'Commit Changes',
        instruction: 'Stage changes and create a clear conventional commit message.',
        icon: Icons.commit_rounded,
        color: Color(0xFF8B5CF6),
      ),
      const QuickCommand(
        id: 'cmd_stop',
        label: 'Stop Agent',
        instruction: 'Stop the active agent immediately and reset.',
        icon: Icons.stop_circle_rounded,
        color: Color(0xFFEF4444),
        isDestructive: true,
      ),
    ];
  }
}
