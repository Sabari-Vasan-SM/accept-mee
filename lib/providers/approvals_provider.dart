import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/permission_request.dart';
import 'antigravity_provider.dart';

final pendingApprovalsProvider = StreamProvider<List<PermissionRequest>>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.pendingApprovalsStream;
});

final hasPendingApprovalsProvider = Provider<bool>((ref) {
  final approvalsAsync = ref.watch(pendingApprovalsProvider);
  return approvalsAsync.maybeWhen(
    data: (list) => list.isNotEmpty,
    orElse: () => false,
  );
});

final pendingApprovalsCountProvider = Provider<int>((ref) {
  final approvalsAsync = ref.watch(pendingApprovalsProvider);
  return approvalsAsync.maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});
