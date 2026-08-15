import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

class SettingsState {
  final String serverHost;
  final int serverPort;
  final String? authToken;
  final String deviceName;
  final bool biometricsEnabled;
  final bool hapticsEnabled;

  const SettingsState({
    required this.serverHost,
    required this.serverPort,
    this.authToken,
    required this.deviceName,
    required this.biometricsEnabled,
    required this.hapticsEnabled,
  });

  bool get isPaired => (authToken ?? '').isNotEmpty;

  SettingsState copyWith({
    String? serverHost,
    int? serverPort,
    String? authToken,
    bool clearAuthToken = false,
    String? deviceName,
    bool? biometricsEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      serverHost: serverHost ?? this.serverHost,
      serverPort: serverPort ?? this.serverPort,
      authToken: clearAuthToken ? null : (authToken ?? this.authToken),
      deviceName: deviceName ?? this.deviceName,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
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
        ));

  Future<void> updateServer(String host, int port) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setServerHost(host);
    await storage.setServerPort(port);
    state = state.copyWith(serverHost: host, serverPort: port);
  }

  /// Stores the token captured from a pairing QR code.
  Future<void> setAuthToken(String token) async {
    await _ref.read(storageServiceProvider).setAuthToken(token);
    state = state.copyWith(authToken: token);
  }

  Future<void> setDeviceName(String name) async {
    await _ref.read(storageServiceProvider).setDeviceName(name);
    state = state.copyWith(deviceName: name);
  }

  Future<void> setBiometrics(bool enabled) async {
    await _ref.read(storageServiceProvider).setBiometricsEnabled(enabled);
    state = state.copyWith(biometricsEnabled: enabled);
  }

  Future<void> setHaptics(bool enabled) async {
    await _ref.read(storageServiceProvider).setHapticsEnabled(enabled);
    state = state.copyWith(hapticsEnabled: enabled);
  }

  Future<void> clearAuth() async {
    await _ref.read(storageServiceProvider).clearSession();
    state = state.copyWith(clearAuthToken: true);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
