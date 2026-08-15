import 'dart:async';
import 'dart:math';
import '../models/agent_state.dart';
import '../models/permission_request.dart';
import '../models/activity_event.dart';
import '../models/project.dart';
import '../models/device.dart';
import 'antigravity_client.dart';

/// Interactive standalone simulator for Antigravity AI
class AntigravityMockClient implements AntigravityClient {
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _agentStateController = StreamController<AgentStateModel>.broadcast();
  final _pendingApprovalsController = StreamController<List<PermissionRequest>>.broadcast();
  final _activityController = StreamController<List<ActivityEvent>>.broadcast();
  final _projectsController = StreamController<List<ProjectModel>>.broadcast();
  final _devicesController = StreamController<List<DeviceModel>>.broadcast();

  ConnectionStatus _connectionStatus = ConnectionStatus.connected;
  late AgentStateModel _agentState;
  final List<PermissionRequest> _pendingApprovals = [];
  final List<ActivityEvent> _activity = [];
  final List<ProjectModel> _projects = [];
  final List<DeviceModel> _devices = [];

  Timer? _progressTimer;
  Timer? _uptimeTimer;

  AntigravityMockClient() {
    _initMockData();
  }

  void _initMockData() {
    _agentState = AgentStateModel(
      status: AgentStatus.working,
      currentTask: 'Building authentication module with OAuth2 & JWT tokens',
      currentAction: 'Running test suite: npm run test:auth',
      progress: 72,
      activeProject: 'ecommerce-admin',
      connectedComputer: 'MacBook Pro (M3 Max)',
      uptimeSeconds: 1420,
      lastUpdated: DateTime.now(),
    );

    _projects.addAll([
      const ProjectModel(
        id: 'ecommerce-admin',
        name: 'Ecommerce Admin',
        icon: 'shopping_cart',
        status: 'working',
        branch: 'feat/auth-jwt',
        path: '/Users/sabarivasan/Projects/ecommerce-admin',
        activeTasks: 3,
      ),
      const ProjectModel(
        id: 'school-crm',
        name: 'School CRM',
        icon: 'school',
        status: 'idle',
        branch: 'main',
        path: '/Users/sabarivasan/Projects/school-crm',
        activeTasks: 0,
      ),
      const ProjectModel(
        id: 'billing-saas',
        name: 'Billing SaaS',
        icon: 'attach_money',
        status: 'offline',
        branch: 'release/v2.1',
        path: '/Users/sabarivasan/Projects/billing-saas',
        activeTasks: 0,
      ),
    ]);

    _devices.addAll([
      DeviceModel(
        id: 'dev_macbook_pro',
        name: 'MacBook Pro (M3 Max)',
        type: 'laptop',
        ip: '192.168.1.108',
        status: 'online',
        isCurrent: true,
        lastSeen: DateTime.now(),
      ),
      DeviceModel(
        id: 'dev_windows_pc',
        name: 'Windows Workstation',
        type: 'desktop',
        ip: '192.168.1.142',
        status: 'online',
        isCurrent: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DeviceModel(
        id: 'dev_vps_server',
        name: 'Cloud Build VPS',
        type: 'server',
        ip: '10.0.0.88',
        status: 'offline',
        isCurrent: false,
        lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    _pendingApprovals.add(
      PermissionRequest(
        id: 'req_init_101',
        type: 'terminal_command',
        title: 'Execute Terminal Command',
        description: 'npm install @supabase/supabase-js jsonwebtoken bcrypt',
        riskLevel: RiskLevel.medium,
        project: 'ecommerce-admin',
        device: 'MacBook Pro (M3 Max)',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        details: const PermissionDetails(
          command: 'npm install @supabase/supabase-js jsonwebtoken bcrypt',
          workingDirectory: '/Users/sabarivasan/Projects/ecommerce-admin',
          impact: 'Will modify package.json & lockfile and download 18 packages.',
        ),
      ),
    );

    _activity.addAll([
      ActivityEvent(
        id: 'act_101',
        type: ActivityType.fileEdit,
        title: 'Created Login.tsx component',
        description: 'Added modern OAuth2 login card with glassmorphism layout',
        project: 'ecommerce-admin',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: 'success',
        diff: '+ export const LoginCard = () => { ... }',
      ),
      ActivityEvent(
        id: 'act_102',
        type: ActivityType.terminalCommand,
        title: 'Executed npm run test:unit',
        description: 'Ran 24 unit tests for user authentication flow',
        project: 'ecommerce-admin',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'success',
        diff: 'PASS src/tests/auth.test.ts (24 tests passed in 1.4s)',
      ),
      ActivityEvent(
        id: 'act_103',
        type: ActivityType.approvalGranted,
        title: 'Permission Approved: Database Migration',
        description: 'Applied migration: 20260815_add_users_table.sql',
        project: 'ecommerce-admin',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        status: 'success',
      ),
    ]);

    _startUptimeTimer();
  }

  void _startUptimeTimer() {
    _uptimeTimer?.cancel();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_agentState.status == AgentStatus.working) {
        _agentState = _agentState.copyWith(
          uptimeSeconds: _agentState.uptimeSeconds + 1,
        );
        _agentStateController.add(_agentState);
      }
    });
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  @override
  Stream<AgentStateModel> get agentStateStream => _agentStateController.stream;
  @override
  Stream<List<PermissionRequest>> get pendingApprovalsStream => _pendingApprovalsController.stream;
  @override
  Stream<List<ActivityEvent>> get activityStream => _activityController.stream;
  @override
  Stream<List<ProjectModel>> get projectsStream => _projectsController.stream;
  @override
  Stream<List<DeviceModel>> get devicesStream => _devicesController.stream;

  @override
  ConnectionStatus get currentConnectionStatus => _connectionStatus;
  @override
  AgentStateModel get currentAgentState => _agentState;
  @override
  List<PermissionRequest> get currentPendingApprovals => List.unmodifiable(_pendingApprovals);
  @override
  List<ActivityEvent> get currentActivity => List.unmodifiable(_activity);
  @override
  List<ProjectModel> get currentProjects => List.unmodifiable(_projects);
  @override
  List<DeviceModel> get currentDevices => List.unmodifiable(_devices);

  @override
  Future<bool> connect({required String host, required int port, String? token}) async {
    _connectionStatus = ConnectionStatus.connecting;
    _connectionStatusController.add(_connectionStatus);
    await Future.delayed(const Duration(milliseconds: 600));

    _connectionStatus = ConnectionStatus.connected;
    _connectionStatusController.add(_connectionStatus);
    _emitAll();
    return true;
  }

  void _emitAll() {
    _agentStateController.add(_agentState);
    _pendingApprovalsController.add(List.from(_pendingApprovals));
    _activityController.add(List.from(_activity));
    _projectsController.add(List.from(_projects));
    _devicesController.add(List.from(_devices));
  }

  @override
  Future<void> disconnect() async {
    _connectionStatus = ConnectionStatus.disconnected;
    _connectionStatusController.add(_connectionStatus);
  }

  @override
  Future<bool> sendInstruction(String instruction, {String source = 'mobile'}) async {
    final event = ActivityEvent(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.userInstruction,
      title: 'Instruction: "$instruction"',
      description: 'Triggered via $source',
      project: _agentState.activeProject,
      timestamp: DateTime.now(),
      status: 'success',
    );
    _activity.insert(0, event);
    _activityController.add(List.from(_activity));

    _agentState = _agentState.copyWith(
      status: AgentStatus.working,
      currentTask: instruction,
      currentAction: 'Planning steps for: $instruction',
      progress: 10,
      lastUpdated: DateTime.now(),
    );
    _agentStateController.add(_agentState);

    _simulateProgression(instruction);
    return true;
  }

  void _simulateProgression(String task) {
    _progressTimer?.cancel();
    int step = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      step++;
      if (step == 1) {
        _agentState = _agentState.copyWith(
          currentAction: 'Writing code and updating components',
          progress: 40,
        );
        _activity.insert(
          0,
          ActivityEvent(
            id: 'act_${DateTime.now().millisecondsSinceEpoch}',
            type: ActivityType.fileEdit,
            title: 'Modified src/api/router.ts',
            description: 'Implemented endpoints requested in "$task"',
            project: _agentState.activeProject,
            timestamp: DateTime.now(),
            status: 'success',
          ),
        );
      } else if (step == 2) {
        _agentState = _agentState.copyWith(
          currentAction: 'Running test verification suite',
          progress: 75,
        );
        _activity.insert(
          0,
          ActivityEvent(
            id: 'act_${DateTime.now().millisecondsSinceEpoch}',
            type: ActivityType.testRun,
            title: 'Ran integration tests',
            description: '18 tests passed in 1.2s',
            project: _agentState.activeProject,
            timestamp: DateTime.now(),
            status: 'success',
          ),
        );
      } else {
        timer.cancel();
        _agentState = _agentState.copyWith(
          status: AgentStatus.completed,
          currentAction: 'Completed: $task',
          progress: 100,
        );
        _activity.insert(
          0,
          ActivityEvent(
            id: 'act_${DateTime.now().millisecondsSinceEpoch}',
            type: ActivityType.taskComplete,
            title: 'Task Finished Successfully',
            description: task,
            project: _agentState.activeProject,
            timestamp: DateTime.now(),
            status: 'success',
          ),
        );
      }
      _agentStateController.add(_agentState);
      _activityController.add(List.from(_activity));
    });
  }

  @override
  Future<bool> approveRequest(String requestId, {bool alwaysAllow = false}) async {
    final idx = _pendingApprovals.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _pendingApprovals.removeAt(idx);
      _pendingApprovalsController.add(List.from(_pendingApprovals));

      _activity.insert(
        0,
        ActivityEvent(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityType.approvalGranted,
          title: 'Permission Approved ${alwaysAllow ? "(Always)" : ""}',
          description: req.description,
          project: req.project,
          timestamp: DateTime.now(),
          status: 'success',
        ),
      );
      _activityController.add(List.from(_activity));

      _agentState = _agentState.copyWith(
        status: AgentStatus.working,
        currentAction: 'Executing approved action: ${req.description}',
        progress: min(100, _agentState.progress + 15),
      );
      _agentStateController.add(_agentState);
    }
    return true;
  }

  @override
  Future<bool> denyRequest(String requestId, {String? reason}) async {
    final idx = _pendingApprovals.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _pendingApprovals.removeAt(idx);
      _pendingApprovalsController.add(List.from(_pendingApprovals));

      _activity.insert(
        0,
        ActivityEvent(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityType.approvalDenied,
          title: 'Permission Denied',
          description: '${req.description}${reason != null ? " (Reason: $reason)" : ""}',
          project: req.project,
          timestamp: DateTime.now(),
          status: 'cancelled',
        ),
      );
      _activityController.add(List.from(_activity));

      _agentState = _agentState.copyWith(
        status: AgentStatus.idle,
        currentAction: 'Action cancelled by user',
      );
      _agentStateController.add(_agentState);
    }
    return true;
  }

  @override
  Future<bool> pauseAgent() async {
    _progressTimer?.cancel();
    _agentState = _agentState.copyWith(
      status: AgentStatus.paused,
      currentAction: 'Paused by user',
    );
    _agentStateController.add(_agentState);
    return true;
  }

  @override
  Future<bool> resumeAgent() async {
    _agentState = _agentState.copyWith(
      status: AgentStatus.working,
      currentAction: 'Resumed execution',
    );
    _agentStateController.add(_agentState);
    _simulateProgression(_agentState.currentTask);
    return true;
  }

  @override
  Future<bool> stopAgent() async {
    _progressTimer?.cancel();
    _agentState = _agentState.copyWith(
      status: AgentStatus.idle,
      currentTask: 'Waiting for next instructions',
      currentAction: 'Agent stopped',
      progress: 0,
    );
    _agentStateController.add(_agentState);
    return true;
  }

  @override
  Future<bool> retryTask() async {
    _agentState = _agentState.copyWith(
      status: AgentStatus.working,
      progress: 10,
      currentAction: 'Retrying task: ${_agentState.currentTask}',
    );
    _agentStateController.add(_agentState);
    _simulateProgression(_agentState.currentTask);
    return true;
  }

  @override
  Future<bool> selectProject(String projectId) async {
    _agentState = _agentState.copyWith(activeProject: projectId);
    _agentStateController.add(_agentState);
    return true;
  }

  @override
  Future<void> triggerDemoScenario(String scenarioType) async {
    final req = PermissionRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      type: 'terminal_command',
      title: 'Execute Terminal Command',
      description: scenarioType == 'db_migration'
          ? 'npx prisma migrate dev --name init'
          : 'npm run build:production',
      riskLevel: RiskLevel.high,
      project: _agentState.activeProject,
      device: 'MacBook Pro (M3 Max)',
      createdAt: DateTime.now(),
      details: PermissionDetails(
        command: scenarioType == 'db_migration'
            ? 'npx prisma migrate dev --name init'
            : 'npm run build:production',
        workingDirectory: '/Users/sabarivasan/Projects/ecommerce-admin',
        impact: 'Will execute privileged build/database alter command.',
      ),
    );
    _pendingApprovals.insert(0, req);
    _pendingApprovalsController.add(List.from(_pendingApprovals));

    _agentState = _agentState.copyWith(
      status: AgentStatus.waitingForApproval,
      currentAction: 'Awaiting permission approval for: ${req.description}',
    );
    _agentStateController.add(_agentState);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _uptimeTimer?.cancel();
    _connectionStatusController.close();
    _agentStateController.close();
    _pendingApprovalsController.close();
    _activityController.close();
    _projectsController.close();
    _devicesController.close();
  }
}
