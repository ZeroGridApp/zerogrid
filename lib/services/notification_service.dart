enum NotificationType { message, payment, friendRequest, system, mention }

class ZeroNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;
  final Map<String, dynamic>? metadata;

  ZeroNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
    this.metadata,
  });
}

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final List<ZeroNotification> _notifications = [];

  int get unreadCount => _notifications.where((n) => !n.read).length;
  List<ZeroNotification> get all => List.unmodifiable(_notifications);

  void add(ZeroNotification notification) {
    _notifications.insert(0, notification);
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.read = true;
    }
  }

  void markRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].read = true;
    }
  }

  void clear() {
    _notifications.clear();
  }
}