import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_state.dart';
import '../services/antigravity_client.dart';
import '../services/antigravity_remote_client.dart';
import '../services/antigravity_mock_client.dart';
import 'storage_provider.dart';

/// Active AntigravityClient provider (switches between remote & mock based on settings/mode)
final antigravityClientProvider = Provider<AntigravityClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final useMock = storage.useMockClient;

  final client = useMock ? AntigravityMockClient() : AntigravityRemoteClient();

  // Automatically attempt initial connection
  client.connect(
    host: storage.serverHost,
    port: storage.serverPort,
    token: storage.authToken,
  );

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// Real-time Connection Status Provider
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.connectionStatusStream;
});

/// Real-time Agent State Provider
final agentStateProvider = StreamProvider<AgentStateModel>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.agentStateStream;
});
