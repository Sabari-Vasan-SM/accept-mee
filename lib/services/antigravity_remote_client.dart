import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/agent_state.dart';
import '../models/permission_request.dart';
import '../models/activity_event.dart';
import '../models/project.dart';
import '../models/device.dart';
import 'antigravity_client.dart';

class AntigravityRemoteClient implements AntigravityClient {
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _agentStateController = StreamController<AgentStateModel>.broadcast();
  final _pendingApprovalsController = StreamController<List<PermissionRequest>>.broadcast();
  final _activityController = StreamController<List<ActivityEvent>>.broadcast();
  final _projectsController = StreamController<List<ProjectModel>>.broadcast();
  final _devicesController = StreamController<List<DeviceModel>>.broadcast();

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  AgentStateModel _agentState = AgentStateModel.initial();
  List<PermissionRequest> _pendingApprovals = [];
  List<ActivityEvent> _activity = [];
  List<ProjectModel> _projects = [];
  List<DeviceModel> _devices = [];

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String _host = '127.0.0.1';
  int _port = 8765;
  String? _token;
  bool _manuallyDisconnected = false;

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

  String get _baseUrl => 'http://$_host:$_port/api/v1';
  String get _wsUrl => 'ws://$_host:$_port/ws';

  void _updateConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  @override
  Future<bool> connect({required String host, required int port, String? token}) async {
    _host = host;
    _port = port;
    _token = token;
    _manuallyDisconnected = false;

    _updateConnectionStatus(ConnectionStatus.connecting);

    try {
      // 1. Test HTTP Health Endpoint
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        _updateConnectionStatus(ConnectionStatus.error);
        _scheduleReconnect();
        return false;
      }

      // 2. Fetch Initial State via REST
      await _fetchInitialRestData();

      // 3. Connect to WebSocket for Real-Time Streaming
      _connectWebSocket();

      _updateConnectionStatus(ConnectionStatus.connected);
      return true;
    } catch (e) {
      debugPrint('[AntigravityRemoteClient] Connection failed: $e');
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  Future<void> _fetchInitialRestData() async {
    try {
      final statusRes = await http.get(Uri.parse('$_baseUrl/status'));
      if (statusRes.statusCode == 200) {
        final data = jsonDecode(statusRes.body);
        if (data['agentState'] != null) {
          _agentState = AgentStateModel.fromJson(data['agentState']);
          _agentStateController.add(_agentState);
        }
        if (data['activeProjects'] != null) {
          _projects = (data['activeProjects'] as List)
              .map((p) => ProjectModel.fromJson(p))
              .toList();
          _projectsController.add(_projects);
        }
        if (data['connectedDevices'] != null) {
          _devices = (data['connectedDevices'] as List)
              .map((d) => DeviceModel.fromJson(d))
              .toList();
          _devicesController.add(_devices);
        }
      }

      final approvalsRes = await http.get(Uri.parse('$_baseUrl/approvals'));
      if (approvalsRes.statusCode == 200) {
        final list = jsonDecode(approvalsRes.body) as List;
        _pendingApprovals = list.map((a) => PermissionRequest.fromJson(a)).toList();
        _pendingApprovalsController.add(_pendingApprovals);
      }

      final historyRes = await http.get(Uri.parse('$_baseUrl/history'));
      if (historyRes.statusCode == 200) {
        final list = jsonDecode(historyRes.body) as List;
        _activity = list.map((a) => ActivityEvent.fromJson(a)).toList();
        _activityController.add(_activity);
      }
    } catch (e) {
      debugPrint('[AntigravityRemoteClient] Error fetching REST initial state: $e');
    }
  }

  void _connectWebSocket() {
    try {
      _wsChannel?.sink.close();
      _wsSubscription?.cancel();

      _wsChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _wsSubscription = _wsChannel!.stream.listen(
        _handleWsMessage,
        onDone: () {
          debugPrint('[WebSocket] Connection closed by server');
          if (!_manuallyDisconnected) {
            _updateConnectionStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
        onError: (err) {
          debugPrint('[WebSocket] Error: $err');
          if (!_manuallyDisconnected) {
            _updateConnectionStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      debugPrint('[WebSocket] Exception during connect: $e');
      _scheduleReconnect();
    }
  }

  void _handleWsMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw.toString());
      final type = json['type'] as String?;
      final payload = json['payload'];

      switch (type) {
        case 'INITIAL_STATE':
          if (payload['agentState'] != null) {
            _agentState = AgentStateModel.fromJson(payload['agentState']);
            _agentStateController.add(_agentState);
          }
          if (payload['pendingApprovals'] != null) {
            _pendingApprovals = (payload['pendingApprovals'] as List)
                .map((a) => PermissionRequest.fromJson(a))
                .toList();
            _pendingApprovalsController.add(_pendingApprovals);
          }
          if (payload['activeProjects'] != null) {
            _projects = (payload['activeProjects'] as List)
                .map((p) => ProjectModel.fromJson(p))
                .toList();
            _projectsController.add(_projects);
          }
          if (payload['connectedDevices'] != null) {
            _devices = (payload['connectedDevices'] as List)
                .map((d) => DeviceModel.fromJson(d))
                .toList();
            _devicesController.add(_devices);
          }
          if (payload['activityHistory'] != null) {
            _activity = (payload['activityHistory'] as List)
                .map((a) => ActivityEvent.fromJson(a))
                .toList();
            _activityController.add(_activity);
          }
          break;

        case 'AGENT_STATUS_UPDATED':
          _agentState = AgentStateModel.fromJson(payload);
          _agentStateController.add(_agentState);
          break;

        case 'NEW_APPROVAL_REQUEST':
          final newReq = PermissionRequest.fromJson(payload);
          _pendingApprovals.insert(0, newReq);
          _pendingApprovalsController.add(List.from(_pendingApprovals));
          break;

        case 'APPROVAL_RESOLVED':
          final id = payload['approvalId'];
          _pendingApprovals.removeWhere((req) => req.id == id);
          _pendingApprovalsController.add(List.from(_pendingApprovals));
          break;

        case 'ACTIVITY_ADDED':
          final newAct = ActivityEvent.fromJson(payload);
          _activity.insert(0, newAct);
          _activityController.add(List.from(_activity));
          break;
      }
    } catch (e) {
      debugPrint('[WebSocket] Message handle error: $e');
    }
  }

  void _sendWs(String type, Map<String, dynamic> payload) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode({'type': type, 'payload': payload}));
    }
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_manuallyDisconnected && _connectionStatus != ConnectionStatus.connected) {
        connect(host: _host, port: _port, token: _token);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _wsSubscription?.cancel();
    await _wsChannel?.sink.close();
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  @override
  Future<bool> sendInstruction(String instruction, {String source = 'mobile'}) async {
    try {
      _sendWs('SEND_INSTRUCTION', {'instruction': instruction, 'source': source});
      await http.post(
        Uri.parse('$_baseUrl/commands'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'instruction': instruction, 'source': source}),
      );
      return true;
    } catch (e) {
      debugPrint('Error sending instruction: $e');
      return false;
    }
  }

  @override
  Future<bool> approveRequest(String requestId, {bool alwaysAllow = false}) async {
    try {
      final decision = alwaysAllow ? 'ALWAYS_ALLOW' : 'ALLOW_ONCE';
      _sendWs('DECIDE_APPROVAL', {'approvalId': requestId, 'decision': decision});
      await http.post(
        Uri.parse('$_baseUrl/approvals/$requestId/decide'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'decision': decision}),
      );
      return true;
    } catch (e) {
      debugPrint('Error approving request: $e');
      return false;
    }
  }

  @override
  Future<bool> denyRequest(String requestId, {String? reason}) async {
    try {
      _sendWs('DECIDE_APPROVAL', {'approvalId': requestId, 'decision': 'DENY', 'reason': reason});
      await http.post(
        Uri.parse('$_baseUrl/approvals/$requestId/decide'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'decision': 'DENY', 'reason': reason}),
      );
      return true;
    } catch (e) {
      debugPrint('Error denying request: $e');
      return false;
    }
  }

  @override
  Future<bool> pauseAgent() async {
    _sendWs('AGENT_CONTROL', {'action': 'pause'});
    try {
      await http.post(Uri.parse('$_baseUrl/agent/pause'));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resumeAgent() async {
    _sendWs('AGENT_CONTROL', {'action': 'resume'});
    try {
      await http.post(Uri.parse('$_baseUrl/agent/resume'));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> stopAgent() async {
    _sendWs('AGENT_CONTROL', {'action': 'stop'});
    try {
      await http.post(Uri.parse('$_baseUrl/agent/stop'));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> retryTask() async {
    _sendWs('AGENT_CONTROL', {'action': 'retry'});
    try {
      await http.post(Uri.parse('$_baseUrl/agent/retry'));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> selectProject(String projectId) async {
    _sendWs('SELECT_PROJECT', {'projectId': projectId});
    return true;
  }

  @override
  Future<void> triggerDemoScenario(String scenarioType) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/simulate/permission-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': scenarioType}),
      );
    } catch (e) {
      debugPrint('Error triggering demo scenario: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _agentStateController.close();
    _pendingApprovalsController.close();
    _activityController.close();
    _projectsController.close();
    _devicesController.close();
  }
}
