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

/// Talks to the desktop companion server.
///
/// Actions go out over REST so failures come back as real status codes; the
/// WebSocket is inbound only, for state the server pushes. (An earlier version
/// sent every action over both and silently ignored the result of each.)
class AntigravityRemoteClient implements AntigravityClient {
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _agentStateController = StreamController<AgentStateModel>.broadcast();
  final _pendingApprovalsController = StreamController<List<PermissionRequest>>.broadcast();
  final _activityController = StreamController<List<ActivityEvent>>.broadcast();
  final _projectsController = StreamController<List<ProjectModel>>.broadcast();
  final _devicesController = StreamController<List<DeviceModel>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  AgentStateModel _agentState = AgentStateModel.initial();
  List<PermissionRequest> _pendingApprovals = [];
  List<ActivityEvent> _activity = [];
  List<ProjectModel> _projects = [];
  List<DeviceModel> _devices = [];

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;

  String _host = '127.0.0.1';
  int _port = 8765;
  String? _token;
  bool _manuallyDisconnected = false;
  int _reconnectAttempts = 0;

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
  Stream<String> get errorStream => _errorController.stream;

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
  String get _wsUrl =>
      'ws://$_host:$_port/ws?token=${Uri.encodeQueryComponent(_token ?? '')}';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  void _updateConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  void _reportError(String message) {
    debugPrint('[AntigravityRemoteClient] $message');
    if (!_errorController.isClosed) _errorController.add(message);
  }

  @override
  Future<bool> connect({required String host, required int port, String? token}) async {
    _host = host;
    _port = port;
    _token = token;
    _manuallyDisconnected = false;

    _updateConnectionStatus(ConnectionStatus.connecting);

    if (token == null || token.isEmpty) {
      _reportError('Not paired yet — scan the QR code shown by the companion server.');
      _updateConnectionStatus(ConnectionStatus.error);
      return false;
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        _updateConnectionStatus(ConnectionStatus.error);
        _scheduleReconnect();
        return false;
      }

      // Health needs no token, so prove the token separately before claiming
      // we're connected — otherwise a stale token looks like a healthy link.
      final status = await http
          .get(Uri.parse('$_baseUrl/status'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (status.statusCode == 401) {
        _reportError('Pairing token rejected. Re-scan the QR code to pair again.');
        _updateConnectionStatus(ConnectionStatus.error);
        return false; // deliberately no retry: reconnecting can't fix a bad token
      }
      if (status.statusCode != 200) {
        _updateConnectionStatus(ConnectionStatus.error);
        _scheduleReconnect();
        return false;
      }

      _applySnapshot(jsonDecode(status.body) as Map<String, dynamic>);
      _connectWebSocket();

      _reconnectAttempts = 0;
      _updateConnectionStatus(ConnectionStatus.connected);
      return true;
    } on TimeoutException {
      _reportError('Companion server at $_host:$_port did not respond.');
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
      return false;
    } catch (e) {
      _reportError('Could not reach $_host:$_port — $e');
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  void _applySnapshot(Map<String, dynamic> data) {
    if (data['agentState'] != null) {
      _agentState = AgentStateModel.fromJson(data['agentState']);
      _agentStateController.add(_agentState);
    }
    if (data['pendingApprovals'] != null) {
      _pendingApprovals = (data['pendingApprovals'] as List)
          .map((a) => PermissionRequest.fromJson(a))
          .toList();
      _pendingApprovalsController.add(List.from(_pendingApprovals));
    }
    if (data['activeProjects'] != null) {
      _projects =
          (data['activeProjects'] as List).map((p) => ProjectModel.fromJson(p)).toList();
      _projectsController.add(List.from(_projects));
    }
    if (data['connectedDevices'] != null) {
      _devices =
          (data['connectedDevices'] as List).map((d) => DeviceModel.fromJson(d)).toList();
      _devicesController.add(List.from(_devices));
    }
    if (data['activityHistory'] != null) {
      _activity =
          (data['activityHistory'] as List).map((a) => ActivityEvent.fromJson(a)).toList();
      _activityController.add(List.from(_activity));
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
          if (!_manuallyDisconnected) {
            _updateConnectionStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
        onError: (err) {
          if (!_manuallyDisconnected) {
            _updateConnectionStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      _reportError('WebSocket connect failed: $e');
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
          _applySnapshot(payload as Map<String, dynamic>);
          break;

        case 'AGENT_STATUS_UPDATED':
          _agentState = AgentStateModel.fromJson(payload);
          _agentStateController.add(_agentState);
          break;

        case 'NEW_APPROVAL_REQUEST':
          _pendingApprovals.insert(0, PermissionRequest.fromJson(payload));
          _pendingApprovalsController.add(List.from(_pendingApprovals));
          break;

        case 'APPROVAL_RESOLVED':
          _pendingApprovals.removeWhere((req) => req.id == payload['approvalId']);
          _pendingApprovalsController.add(List.from(_pendingApprovals));
          break;

        case 'ACTIVITY_ADDED':
          _activity.insert(0, ActivityEvent.fromJson(payload));
          _activityController.add(List.from(_activity));
          break;

        case 'PROJECTS_UPDATED':
          _projects = (payload as List).map((p) => ProjectModel.fromJson(p)).toList();
          _projectsController.add(List.from(_projects));
          break;

        case 'DEVICES_UPDATED':
          _devices = (payload as List).map((d) => DeviceModel.fromJson(d)).toList();
          _devicesController.add(List.from(_devices));
          break;

        case 'COMMAND_FAILED':
          _reportError(payload['message'] as String? ?? 'The desktop rejected that command.');
          break;
      }
    } catch (e) {
      debugPrint('[WebSocket] Message handle error: $e');
    }
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected) return;
    _reconnectTimer?.cancel();

    // Back off so a phone in a pocket isn't hammering a dead host all day.
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(1, 6);
    final delay = Duration(seconds: [2, 3, 5, 10, 20, 30][_reconnectAttempts - 1]);

    _reconnectTimer = Timer(delay, () {
      if (!_manuallyDisconnected && _connectionStatus != ConnectionStatus.connected) {
        connect(host: _host, port: _port, token: _token);
      }
    });
  }

  /// POST helper that turns a non-2xx into a reported error and a `false`.
  Future<bool> _post(String path, {Map<String, dynamic>? body, String? action}) async {
    try {
      final res = await http
          .post(Uri.parse('$_baseUrl$path'),
              headers: _headers, body: body == null ? null : jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) return true;

      String message;
      try {
        message = (jsonDecode(res.body)['message'] as String?) ?? res.body;
      } catch (_) {
        message = 'HTTP ${res.statusCode}';
      }
      _reportError(action == null ? message : '$action failed: $message');
      return false;
    } catch (e) {
      _reportError(action == null ? '$e' : '$action failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    await _wsSubscription?.cancel();
    await _wsChannel?.sink.close();
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  @override
  Future<bool> sendInstruction(String instruction, {String source = 'mobile'}) =>
      _post('/commands',
          body: {'instruction': instruction, 'source': source}, action: 'Sending instruction');

  @override
  Future<bool> approveRequest(String requestId, {bool alwaysAllow = false}) => _post(
        '/approvals/$requestId/decide',
        body: {'decision': alwaysAllow ? 'ALWAYS_ALLOW' : 'ALLOW_ONCE'},
        action: 'Approving',
      );

  @override
  Future<bool> denyRequest(String requestId, {String? reason}) => _post(
        '/approvals/$requestId/decide',
        body: {'decision': 'DENY', 'reason': ?reason},
        action: 'Denying',
      );

  @override
  Future<bool> pauseAgent() => _post('/agent/pause', action: 'Pause');

  @override
  Future<bool> resumeAgent() => _post('/agent/resume', action: 'Resume');

  @override
  Future<bool> stopAgent() => _post('/agent/stop', action: 'Stop');

  @override
  Future<bool> retryTask() => _post('/agent/retry', action: 'Retry');

  @override
  Future<bool> selectProject(String projectId) =>
      _post('/projects/$projectId/select', action: 'Switching project');

  @override
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _agentStateController.close();
    _pendingApprovalsController.close();
    _activityController.close();
    _projectsController.close();
    _devicesController.close();
    _errorController.close();
  }
}
