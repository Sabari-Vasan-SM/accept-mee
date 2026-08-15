import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'antigravity_provider.dart';

final projectsStreamProvider = StreamProvider<List<ProjectModel>>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.projectsStream;
});

final activeProjectProvider = Provider<ProjectModel?>((ref) {
  final projectsAsync = ref.watch(projectsStreamProvider);
  final agentStateAsync = ref.watch(agentStateProvider);

  final activeId = agentStateAsync.value?.activeProject ?? 'ecommerce-admin';

  return projectsAsync.maybeWhen(
    data: (projects) {
      try {
        return projects.firstWhere((p) => p.id == activeId);
      } catch (_) {
        return projects.isNotEmpty ? projects.first : null;
      }
    },
    orElse: () => null,
  );
});
