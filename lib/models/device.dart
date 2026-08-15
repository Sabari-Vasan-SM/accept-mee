class DeviceModel {
  final String id;
  final String name;
  final String type; // 'laptop' | 'desktop' | 'server'
  final String ip;
  final String status; // 'online' | 'offline' | 'reconnecting'
  final bool isCurrent;
  final DateTime lastSeen;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ip,
    required this.status,
    required this.isCurrent,
    required this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workstation',
      type: json['type'] as String? ?? 'laptop',
      ip: json['ip'] as String? ?? '127.0.0.1',
      status: json['status'] as String? ?? 'offline',
      isCurrent: json['isCurrent'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ip': ip,
      'status': status,
      'isCurrent': isCurrent,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
