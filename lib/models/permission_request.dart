enum RiskLevel {
  low,
  medium,
  high;

  static RiskLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'low':
        return RiskLevel.low;
      case 'medium':
      default:
        return RiskLevel.medium;
    }
  }
}

class PermissionDetails {
  final String? command;
  final String? workingDirectory;
  final String? impact;
  final String? targetFile;
  final String? diff;

  const PermissionDetails({
    this.command,
    this.workingDirectory,
    this.impact,
    this.targetFile,
    this.diff,
  });

  factory PermissionDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PermissionDetails();
    return PermissionDetails(
      command: json['command'] as String?,
      workingDirectory: json['workingDirectory'] as String?,
      impact: json['impact'] as String?,
      targetFile: json['targetFile'] as String?,
      diff: json['diff'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'workingDirectory': workingDirectory,
      'impact': impact,
      'targetFile': targetFile,
      'diff': diff,
    };
  }
}

class PermissionRequest {
  final String id;
  final String type; // 'terminal_command' | 'file_delete' | 'file_write' | 'api_call'
  final String title;
  final String description;
  final RiskLevel riskLevel;
  final String project;
  final String device;
  final DateTime createdAt;
  final PermissionDetails details;

  const PermissionRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.project,
    required this.device,
    required this.createdAt,
    required this.details,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'] as String? ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type'] as String? ?? 'terminal_command',
      title: json['title'] as String? ?? 'Permission Request',
      description: json['description'] as String? ?? '',
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String?),
      project: json['project'] as String? ?? 'ecommerce-admin',
      device: json['device'] as String? ?? 'MacBook Pro',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      details: PermissionDetails.fromJson(json['details'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'riskLevel': riskLevel.name,
      'project': project,
      'device': device,
      'createdAt': createdAt.toIso8601String(),
      'details': details.toJson(),
    };
  }
}
