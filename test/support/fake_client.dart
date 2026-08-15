import 'dart:async';

import 'package:antigravity_companion/models/activity_event.dart';
import 'package:antigravity_companion/models/agent_state.dart';
import 'package:antigravity_companion/models/device.dart';
import 'package:antigravity_companion/models/permission_request.dart';
import 'package:antigravity_companion/models/project.dart';
import 'package:antigravity_companion/services/antigravity_client.dart';

/// A test double for widget tests — it records calls so a test can assert that
/// tapping ALLOW actually reaches the client.
///
/// This is not a simulator: it ships only in `test/`, serves no fabricated
/// data, and nothing in `lib/` can reach it.
class FakeAntigravityClient implements AntigravityClient {
  FakeAntigravityClient({List<PermissionRequest> approvals = const []})
      : _approvals = List.of(approvals);

  final List<PermissionRequest> _approvals;

  final List<String> approvedIds = [];
  final List<String> alwaysAllowedIds = [];
  final List<String> deniedIds = [];
  final List<String> instructions = [];

  final _approvalsController = StreamController<List<PermissionRequest>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  Stream<ConnectionStatus> get connectionStatusStream => Stream.value(ConnectionStatus.connected);
  @override
  Stream<AgentStateModel> get agentStateStream => Stream.value(AgentStateModel.initial());
  @override
  Stream<List<PermissionRequest>> get pendingApprovalsStream async* {
    yield _approvals;
    yield* _approvalsController.stream;
  }

  @override
  Stream<List<ActivityEvent>> get activityStream => Stream.value(const []);
  @override
  Stream<List<ProjectModel>> get projectsStream => Stream.value(const []);
  @override
  Stream<List<DeviceModel>> get devicesStream => Stream.value(const []);
  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  ConnectionStatus get currentConnectionStatus => ConnectionStatus.connected;
  @override
  AgentStateModel get currentAgentState => AgentStateModel.initial();
  @override
  List<PermissionRequest> get currentPendingApprovals => List.unmodifiable(_approvals);
  @override
  List<ActivityEvent> get currentActivity => const [];
  @override
  List<ProjectModel> get currentProjects => const [];
  @override
  List<DeviceModel> get currentDevices => const [];

  @override
  Future<bool> connect({required String host, required int port, String? token}) async => true;
  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> sendInstruction(String instruction, {String source = 'mobile'}) async {
    instructions.add(instruction);
    return true;
  }

  @override
  Future<bool> approveRequest(String requestId, {bool alwaysAllow = false}) async {
    (alwaysAllow ? alwaysAllowedIds : approvedIds).add(requestId);
    _approvals.removeWhere((r) => r.id == requestId);
    _approvalsController.add(List.of(_approvals));
    return true;
  }

  @override
  Future<bool> denyRequest(String requestId, {String? reason}) async {
    deniedIds.add(requestId);
    _approvals.removeWhere((r) => r.id == requestId);
    _approvalsController.add(List.of(_approvals));
    return true;
  }

  @override
  Future<bool> pauseAgent() async => true;
  @override
  Future<bool> resumeAgent() async => true;
  @override
  Future<bool> stopAgent() async => true;
  @override
  Future<bool> retryTask() async => true;
  @override
  Future<bool> selectProject(String projectId) async => true;

  @override
  void dispose() {
    _approvalsController.close();
    _errorController.close();
  }
}

PermissionRequest buildRequest({
  String id = 'req_1',
  String title = 'rm -rf ./dist',
  RiskLevel risk = RiskLevel.high,
}) {
  return PermissionRequest(
    id: id,
    type: 'terminal_command',
    title: title,
    description: title,
    riskLevel: risk,
    project: 'demo',
    device: 'Test Desktop',
    createdAt: DateTime(2026, 8, 15, 12),
    details: PermissionDetails(
      command: title,
      workingDirectory: '/tmp/demo',
      impact: 'Recursive or forced file deletion',
    ),
  );
}
