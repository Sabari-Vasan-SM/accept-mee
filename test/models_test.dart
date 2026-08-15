import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_companion/models/agent_state.dart';
import 'package:antigravity_companion/models/permission_request.dart';
import 'package:antigravity_companion/models/quick_command.dart';
import 'package:antigravity_companion/models/pairing_payload.dart';

void main() {
  group('Model serialization', () {
    test('AgentStateModel round-trips through JSON', () {
      final updated = AgentStateModel.initial().copyWith(
        status: AgentStatus.working,
        progress: 85,
        currentTask: 'Running test suite',
      );

      final fromJson = AgentStateModel.fromJson(updated.toJson());
      expect(fromJson.status, AgentStatus.working);
      expect(fromJson.progress, 85);
      expect(fromJson.currentTask, 'Running test suite');
    });

    test('AgentStateModel accepts the shapes the server actually sends', () {
      // The broker reports waitingForApproval and never invents a percentage.
      final state = AgentStateModel.fromJson({
        'status': 'waitingForApproval',
        'currentTask': 'No agent activity yet',
        'progress': 0,
        'connectedComputer': 'mac.local',
      });

      expect(state.status, AgentStatus.waitingForApproval);
      expect(state.progress, 0);
      expect(state.connectedComputer, 'mac.local');
    });

    test('PermissionRequest parses a broker payload', () {
      // This is the exact shape lib/toolmap.js emits for a run_command call.
      final request = PermissionRequest.fromJson({
        'id': 'req_mf3k2_1',
        'type': 'terminal_command',
        'title': 'rm -rf ./dist',
        'description': 'rm -rf ./dist',
        'riskLevel': 'high',
        'project': 'demo',
        'device': 'mac.local',
        'createdAt': '2026-08-15T12:00:00.000Z',
        'details': {
          'command': 'rm -rf ./dist',
          'workingDirectory': '/tmp/demo',
          'impact': 'Recursive or forced file deletion',
          'targetFile': null,
          'diff': null,
        },
      });

      expect(request.id, 'req_mf3k2_1');
      expect(request.riskLevel, RiskLevel.high);
      expect(request.details.command, 'rm -rf ./dist');
      expect(request.details.impact, 'Recursive or forced file deletion');
    });

    test('PermissionRequest survives missing fields', () {
      final request = PermissionRequest.fromJson({'title': 'something new'});
      expect(request.title, 'something new');
      expect(request.riskLevel, RiskLevel.medium);
      expect(request.details.command, isNull);
    });

    test('PairingPayload parses a v2 QR code and rejects junk', () {
      const qr =
          '{"version":"2.0","protocol":"antigravity-bridge","host":"192.168.1.50","port":8765,'
          '"token":"abc123token","deviceName":"MacBook Pro","wsUrl":"ws://192.168.1.50:8765/ws",'
          '"httpUrl":"http://192.168.1.50:8765/api/v1"}';

      final parsed = PairingPayload.tryParse(qr);
      expect(parsed, isNotNull);
      expect(parsed!.host, '192.168.1.50');
      expect(parsed.port, 8765);
      expect(parsed.token, 'abc123token');

      expect(PairingPayload.tryParse('invalid_string'), isNull);
    });

    test('QuickCommand ships the documented presets', () {
      final defaults = QuickCommand.defaultCommands();
      expect(defaults, isNotEmpty);
      expect(defaults.any((c) => c.label == 'Continue'), isTrue);
      expect(defaults.any((c) => c.label == 'Run Tests'), isTrue);
    });
  });
}
