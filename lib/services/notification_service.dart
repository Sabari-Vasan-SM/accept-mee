import 'dart:async';

class PushNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'approval' | 'task_complete' | 'error' | 'info'
  final DateTime timestamp;
  final String? payloadId;

  const PushNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.payloadId,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<PushNotificationItem>.broadcast();
  final List<PushNotificationItem> _history = [];

  Stream<PushNotificationItem> get notificationStream => _notificationController.stream;
  List<PushNotificationItem> get history => List.unmodifiable(_history);

  void showNotification({
    required String title,
    required String body,
    required String type,
    String? payloadId,
  }) {
    final item = PushNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      payloadId: payloadId,
    );

    _history.insert(0, item);
    _notificationController.add(item);
  }

  void clear() {
    _history.clear();
  }
}
