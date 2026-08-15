import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

class SettingsState {
  final String serverHost;
  final int serverPort;
  final String? authToken;
  final String deviceName;
  final bool biometricsEnabled;
  final bool hapticsEnabled;
  final bool useMockClient;

  const SettingsState({
    required this.serverHost,
    required this.serverPort,
    this.authToken,
    required this.deviceName,
    required this.biometricsEnabled,
    required this.hapticsEnabled,
    required this.useMockClient,
  });
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(SettingsState(
          serverHost: _ref.read(storageServiceProvider).serverHost,
          serverPort: _ref.read(storageServiceProvider).serverPort,
          authToken: _ref.read(storageServiceProvider).authToken,
          deviceName: _ref.read(storageServiceProvider).deviceName,
          biometricsEnabled: _ref.read(storageServiceProvider).biometricsEnabled,
          hapticsEnabled: _ref.read(storageServiceProvider).hapticsEnabled,
          useMockClient: _ref.read(storageServiceProvider).useMockClient,
        ));

  Future<void> updateServer(String host, int port) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setServerHost(host);
    await storage.setServerPort(port);
    state = SettingsState(
      serverHost: host,
      serverPort: port,
      authToken: state.authToken,
      deviceName: state.deviceName,
      biometricsEnabled: state.biometricsEnabled,
      hapticsEnabled: state.hapticsEnabled,
      useMockClient: state.useMockClient,
    );
  }

  Future<void> setBiometrics(bool enabled) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setBiometricsEnabled(enabled);
    state = SettingsState(
      serverHost: state.serverHost,
      serverPort: state.serverPort,
      authToken: state.authToken,
      deviceName: state.deviceName,
      biometricsEnabled: enabled,
      hapticsEnabled: state.hapticsEnabled,
      useMockClient: state.useMockClient,
    );
  }

  Future<void> setHaptics(bool enabled) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setHapticsEnabled(enabled);
    state = SettingsState(
      serverHost: state.serverHost,
      serverPort: state.serverPort,
      authToken: state.authToken,
      deviceName: state.deviceName,
      biometricsEnabled: state.biometricsEnabled,
      hapticsEnabled: enabled,
      useMockClient: state.useMockClient,
    );
  }

  Future<void> setUseMockClient(bool enabled) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setUseMockClient(enabled);
    state = SettingsState(
      serverHost: state.serverHost,
      serverPort: state.serverPort,
      authToken: state.authToken,
      deviceName: state.deviceName,
      biometricsEnabled: state.biometricsEnabled,
      hapticsEnabled: state.hapticsEnabled,
      useMockClient: enabled,
    );
  }

  Future<void> clearAuth() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.clearSession();
    state = SettingsState(
      serverHost: state.serverHost,
      serverPort: state.serverPort,
      authToken: null,
      deviceName: state.deviceName,
      biometricsEnabled: state.biometricsEnabled,
      hapticsEnabled: state.hapticsEnabled,
      useMockClient: state.useMockClient,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
