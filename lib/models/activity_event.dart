enum ActivityType {
  fileEdit,
  terminalCommand,
  testRun,
  approvalGranted,
  approvalDenied,
  userInstruction,
  taskComplete,
  errorWarning;

  static ActivityType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'file_edit':
      case 'fileedit':
        return ActivityType.fileEdit;
      case 'terminal_command':
      case 'terminal':
        return ActivityType.terminalCommand;
      case 'test_run':
      case 'test':
        return ActivityType.testRun;
      case 'approval_granted':
      case 'approvalgranted':
        return ActivityType.approvalGranted;
      case 'approval_denied':
      case 'approvaldenied':
        return ActivityType.approvalDenied;
      case 'user_instruction':
      case 'userinstruction':
        return ActivityType.userInstruction;
      case 'task_complete':
      case 'taskcomplete':
        return ActivityType.taskComplete;
      case 'error':
      case 'warning':
      case 'error_warning':
      default:
        return ActivityType.errorWarning;
    }
  }
}

class ActivityEvent {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String project;
  final DateTime timestamp;
  final String status; // 'success' | 'failed' | 'warning' | 'cancelled'
  final String? diff;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.project,
    required this.timestamp,
    required this.status,
    this.diff,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String? ?? 'act_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? 'Activity',
      description: json['description'] as String? ?? '',
      project: json['project'] as String? ?? 'ecommerce-admin',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'success',
      diff: json['diff'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'project': project,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'diff': diff,
    };
  }
}
