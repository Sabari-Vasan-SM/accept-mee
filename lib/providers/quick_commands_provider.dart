import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_command.dart';

class QuickCommandsNotifier extends StateNotifier<List<QuickCommand>> {
  QuickCommandsNotifier() : super(QuickCommand.defaultCommands());

  void addCommand(QuickCommand cmd) {
    state = [...state, cmd];
  }

  void updateCommand(QuickCommand cmd) {
    state = state.map((c) => c.id == cmd.id ? cmd : c).toList();
  }

  void removeCommand(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void resetDefaults() {
    state = QuickCommand.defaultCommands();
  }
}

final quickCommandsProvider =
    StateNotifierProvider<QuickCommandsNotifier, List<QuickCommand>>((ref) {
  return QuickCommandsNotifier();
});
