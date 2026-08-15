import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_event.dart';
import 'antigravity_provider.dart';

final activityStreamProvider = StreamProvider<List<ActivityEvent>>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.activityStream;
});

enum ActivityFilter { all, fileEdits, commands, tests, approvals }

final activityFilterProvider = StateProvider<ActivityFilter>((ref) => ActivityFilter.all);

final filteredActivityProvider = Provider<List<ActivityEvent>>((ref) {
  final activityAsync = ref.watch(activityStreamProvider);
  final filter = ref.watch(activityFilterProvider);

  return activityAsync.maybeWhen(
    data: (events) {
      switch (filter) {
        case ActivityFilter.fileEdits:
          return events.where((e) => e.type == ActivityType.fileEdit).toList();
        case ActivityFilter.commands:
          return events.where((e) => e.type == ActivityType.terminalCommand).toList();
        case ActivityFilter.tests:
          return events.where((e) => e.type == ActivityType.testRun).toList();
        case ActivityFilter.approvals:
          return events.where((e) =>
              e.type == ActivityType.approvalGranted ||
              e.type == ActivityType.approvalDenied).toList();
        case ActivityFilter.all:
          return events;
      }
    },
    orElse: () => [],
  );
});
