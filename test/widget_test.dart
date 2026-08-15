import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_companion/models/agent_state.dart';
import 'package:antigravity_companion/models/permission_request.dart';
import 'package:antigravity_companion/models/activity_event.dart';
import 'package:antigravity_companion/models/quick_command.dart';
import 'package:antigravity_companion/models/pairing_payload.dart';
import 'package:antigravity_companion/services/antigravity_mock_client.dart';

void main() {
  group('Antigravity Data Models Tests', () {
    test('AgentStateModel serialization and state updates', () {
      final state = AgentStateModel.initial();
      expect(state.status, AgentStatus.idle);
      expect(state.progress, 0);

      final updated = state.copyWith(
        status: AgentStatus.working,
        progress: 85,
        currentTask: 'Running test suite',
      );
      expect(updated.status, AgentStatus.working);
      expect(updated.progress, 85);

      final json = updated.toJson();
      final fromJson = AgentStateModel.fromJson(json);
      expect(fromJson.status, AgentStatus.working);
      expect(fromJson.progress, 85);
      expect(fromJson.currentTask, 'Running test suite');
    });

    test('PermissionRequest serialization and risk level parsing', () {
      final req = PermissionRequest(
        id: 'req_101',
        type: 'terminal_command',
        title: 'Run build',
        description: 'npm run build',
        riskLevel: RiskLevel.high,
        project: 'ecommerce-admin',
        device: 'MacBook Pro',
        createdAt: DateTime.now(),
        details: const PermissionDetails(
          command: 'npm run build',
          impact: 'Generates production build',
        ),
      );

      final json = req.toJson();
      final fromJson = PermissionRequest.fromJson(json);
      expect(fromJson.id, 'req_101');
      expect(fromJson.riskLevel, RiskLevel.high);
      expect(fromJson.details.command, 'npm run build');
    });

    test('PairingPayload parse and tryParse', () {
      const validJson =
          '{"version":"1.0","protocol":"antigravity-bridge","host":"192.168.1.50","port":8765,"token":"abc123token","deviceName":"MacBook Pro M3","wsUrl":"ws://192.168.1.50:8765/ws","httpUrl":"http://192.168.1.50:8765/api/v1"}';

      final parsed = PairingPayload.tryParse(validJson);
      expect(parsed, isNotNull);
      expect(parsed!.host, '192.168.1.50');
      expect(parsed.port, 8765);
      expect(parsed.token, 'abc123token');

      final invalid = PairingPayload.tryParse('invalid_string');
      expect(invalid, isNull);
    });

    test('QuickCommand default presets and execution model', () {
      final defaults = QuickCommand.defaultCommands();
      expect(defaults.isNotEmpty, true);
      expect(defaults.any((c) => c.label == 'Continue'), true);
      expect(defaults.any((c) => c.label == 'Fix Issue'), true);
      expect(defaults.any((c) => c.label == 'Run Tests'), true);
    });
  });

  group('AntigravityMockClient Simulation Tests', () {
    test('Mock client initial state and approval resolution', () async {
      final client = AntigravityMockClient();
      expect(client.currentConnectionStatus.name, isNotEmpty);
      expect(client.currentPendingApprovals.isNotEmpty, true);

      final firstApproval = client.currentPendingApprovals.first;
      await client.approveRequest(firstApproval.id, alwaysAllow: true);

      // Verify approval was resolved and removed from pending
      expect(client.currentPendingApprovals.any((a) => a.id == firstApproval.id), false);

      // Verify activity added
      expect(client.currentActivity.first.type, ActivityType.approvalGranted);

      client.dispose();
    });

    test('Mock client agent pause, resume, and instruction dispatch', () async {
      final client = AntigravityMockClient();

      await client.pauseAgent();
      expect(client.currentAgentState.status, AgentStatus.paused);

      await client.resumeAgent();
      expect(client.currentAgentState.status, AgentStatus.working);

      await client.sendInstruction('Optimize query performance', source: 'voice');
      expect(client.currentAgentState.currentTask, 'Optimize query performance');

      client.dispose();
    });
  });
}
