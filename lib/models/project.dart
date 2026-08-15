class ProjectModel {
  final String id;
  final String name;
  final String icon;
  final String status; // 'working' | 'idle' | 'offline'
  final String branch;
  final String path;
  final int activeTasks;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.status,
    required this.branch,
    required this.path,
    required this.activeTasks,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Project',
      icon: json['icon'] as String? ?? 'code',
      status: json['status'] as String? ?? 'idle',
      branch: json['branch'] as String? ?? 'main',
      path: json['path'] as String? ?? '',
      activeTasks: (json['activeTasks'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'status': status,
      'branch': branch,
      'path': path,
      'activeTasks': activeTasks,
    };
  }
}
