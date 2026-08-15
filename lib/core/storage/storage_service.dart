import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServerHost = 'antigravity_server_host';
  static const String _keyServerPort = 'antigravity_server_port';
  static const String _keyAuthToken = 'antigravity_auth_token';
  static const String _keyDeviceName = 'antigravity_device_name';
  static const String _keyBiometricsEnabled = 'antigravity_biometrics_enabled';
  static const String _keyHapticsEnabled = 'antigravity_haptics_enabled';
  static const String _keyUseMockClient = 'antigravity_use_mock_client';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  static String get defaultHost {
    if (!kIsWeb && Platform.isAndroid) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  String get serverHost => _prefs.getString(_keyServerHost) ?? defaultHost;
  Future<void> setServerHost(String host) => _prefs.setString(_keyServerHost, host);

  int get serverPort => _prefs.getInt(_keyServerPort) ?? 8765;
  Future<void> setServerPort(int port) => _prefs.setInt(_keyServerPort, port);

  String? get authToken => _prefs.getString(_keyAuthToken);
  Future<void> setAuthToken(String token) => _prefs.setString(_keyAuthToken, token);

  String get deviceName => _prefs.getString(_keyDeviceName) ?? 'MacBook Pro';
  Future<void> setDeviceName(String name) => _prefs.setString(_keyDeviceName, name);

  bool get biometricsEnabled => _prefs.getBool(_keyBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool enabled) =>
      _prefs.setBool(_keyBiometricsEnabled, enabled);

  bool get hapticsEnabled => _prefs.getBool(_keyHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool enabled) =>
      _prefs.setBool(_keyHapticsEnabled, enabled);

  bool get useMockClient => _prefs.getBool(_keyUseMockClient) ?? false;
  Future<void> setUseMockClient(bool value) =>
      _prefs.setBool(_keyUseMockClient, value);

  Future<void> clearSession() async {
    await _prefs.remove(_keyAuthToken);
  }
}
