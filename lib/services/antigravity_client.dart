import '../models/agent_state.dart';
import '../models/permission_request.dart';
import '../models/activity_event.dart';
import '../models/project.dart';
import '../models/device.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error;

  String get label {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Offline';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Online';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}

/// Abstract contract for Antigravity Desktop Client
abstract class AntigravityClient {
  Stream<ConnectionStatus> get connectionStatusStream;
  Stream<AgentStateModel> get agentStateStream;
  Stream<List<PermissionRequest>> get pendingApprovalsStream;
  Stream<List<ActivityEvent>> get activityStream;
  Stream<List<ProjectModel>> get projectsStream;
  Stream<List<DeviceModel>> get devicesStream;

  ConnectionStatus get currentConnectionStatus;
  AgentStateModel get currentAgentState;
  List<PermissionRequest> get currentPendingApprovals;
  List<ActivityEvent> get currentActivity;
  List<ProjectModel> get currentProjects;
  List<DeviceModel> get currentDevices;

  Future<bool> connect({required String host, required int port, String? token});
  Future<void> disconnect();

  Future<bool> sendInstruction(String instruction, {String source = 'mobile'});
  Future<bool> approveRequest(String requestId, {bool alwaysAllow = false});
  Future<bool> denyRequest(String requestId, {String? reason});

  Future<bool> pauseAgent();
  Future<bool> resumeAgent();
  Future<bool> stopAgent();
  Future<bool> retryTask();

  Future<bool> selectProject(String projectId);
  Future<void> triggerDemoScenario(String scenarioType);

  void dispose();
}
