import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_state.dart';
import '../services/antigravity_client.dart';
import '../services/antigravity_remote_client.dart';
import 'storage_provider.dart';

/// The one client. There is no simulator any more — if the desktop companion
/// server isn't reachable the app says so rather than inventing state.
final antigravityClientProvider = Provider<AntigravityClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final client = AntigravityRemoteClient();

  client.connect(
    host: storage.serverHost,
    port: storage.serverPort,
    token: storage.authToken,
  );

  ref.onDispose(client.dispose);
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

/// Human-readable failures from the desktop, for snackbars.
final clientErrorProvider = StreamProvider<String>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.errorStream;
});
