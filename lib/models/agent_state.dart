enum AgentStatus {
  offline,
  connecting,
  idle,
  working,
  waitingForApproval,
  paused,
  error,
  completed;

  static AgentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'idle':
        return AgentStatus.idle;
      case 'working':
        return AgentStatus.working;
      case 'waitingforapproval':
      case 'waiting_for_approval':
      case 'approval':
        return AgentStatus.waitingForApproval;
      case 'paused':
        return AgentStatus.paused;
      case 'error':
        return AgentStatus.error;
      case 'completed':
        return AgentStatus.completed;
      case 'connecting':
        return AgentStatus.connecting;
      case 'offline':
      default:
        return AgentStatus.offline;
    }
  }

  String get label {
    switch (this) {
      case AgentStatus.offline:
        return 'Offline';
      case AgentStatus.connecting:
        return 'Connecting...';
      case AgentStatus.idle:
        return 'Idle';
      case AgentStatus.working:
        return 'Working';
      case AgentStatus.waitingForApproval:
        return 'Approval Required';
      case AgentStatus.paused:
        return 'Paused';
      case AgentStatus.error:
        return 'Error';
      case AgentStatus.completed:
        return 'Task Completed';
    }
  }
}

class AgentStateModel {
  final AgentStatus status;
  final String currentTask;
  final String currentAction;
  final int progress; // 0 - 100
  final String activeProject;
  final String connectedComputer;
  final int uptimeSeconds;
  final DateTime lastUpdated;

  const AgentStateModel({
    required this.status,
    required this.currentTask,
    required this.currentAction,
    required this.progress,
    required this.activeProject,
    required this.connectedComputer,
    required this.uptimeSeconds,
    required this.lastUpdated,
  });

  factory AgentStateModel.initial() {
    return AgentStateModel(
      status: AgentStatus.idle,
      currentTask: 'Waiting for next instructions',
      currentAction: 'Ready to build, test, and refactor',
      progress: 0,
      activeProject: 'ecommerce-admin',
      connectedComputer: 'MacBook Pro',
      uptimeSeconds: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory AgentStateModel.fromJson(Map<String, dynamic> json) {
    return AgentStateModel(
      status: AgentStatus.fromString(json['status'] as String?),
      currentTask: json['currentTask'] as String? ?? 'No active task',
      currentAction: json['currentAction'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      activeProject: json['activeProject'] as String? ?? 'Default Project',
      connectedComputer: json['connectedComputer'] as String? ?? 'Desktop Computer',
      uptimeSeconds: (json['uptimeSeconds'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'currentTask': currentTask,
      'currentAction': currentAction,
      'progress': progress,
      'activeProject': activeProject,
      'connectedComputer': connectedComputer,
      'uptimeSeconds': uptimeSeconds,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  AgentStateModel copyWith({
    AgentStatus? status,
    String? currentTask,
    String? currentAction,
    int? progress,
    String? activeProject,
    String? connectedComputer,
    int? uptimeSeconds,
    DateTime? lastUpdated,
  }) {
    return AgentStateModel(
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      currentAction: currentAction ?? this.currentAction,
      progress: progress ?? this.progress,
      activeProject: activeProject ?? this.activeProject,
      connectedComputer: connectedComputer ?? this.connectedComputer,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
