import 'dart:convert';

class PairingPayload {
  final String version;
  final String protocol;
  final String host;
  final int port;
  final String token;
  final String deviceName;
  final String wsUrl;
  final String httpUrl;

  const PairingPayload({
    required this.version,
    required this.protocol,
    required this.host,
    required this.port,
    required this.token,
    required this.deviceName,
    required this.wsUrl,
    required this.httpUrl,
  });

  factory PairingPayload.fromJson(Map<String, dynamic> json) {
    return PairingPayload(
      version: json['version'] as String? ?? '1.0',
      protocol: json['protocol'] as String? ?? 'antigravity-bridge',
      host: json['host'] as String? ?? '127.0.0.1',
      port: (json['port'] as num?)?.toInt() ?? 8765,
      token: json['token'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Antigravity Desktop',
      wsUrl: json['wsUrl'] as String? ?? 'ws://127.0.0.1:8765/ws',
      httpUrl: json['httpUrl'] as String? ?? 'http://127.0.0.1:8765/api/v1',
    );
  }

  static PairingPayload? tryParse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic> && json.containsKey('token')) {
        return PairingPayload.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'protocol': protocol,
      'host': host,
      'port': port,
      'token': token,
      'deviceName': deviceName,
      'wsUrl': wsUrl,
      'httpUrl': httpUrl,
    };
  }
}
