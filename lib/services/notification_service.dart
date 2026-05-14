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

  void seedDemo() {
    if (_notifications.isNotEmpty) return;

    final now = DateTime.now();

    _notifications.addAll([
      ZeroNotification(
        id: '1',
        type: NotificationType.message,
        title: 'Alice',
        body: 'Hey, are you joining the ZeroNode meetup tonight?',
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      ZeroNotification(
        id: '2',
        type: NotificationType.message,
        title: 'Bob',
        body: 'Check out the new DASN storage update, it\'s lightning fast',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ZeroNotification(
        id: '3',
        type: NotificationType.message,
        title: 'Cipher',
        body: 'Sent you an encrypted file via BLE Mesh',
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      ZeroNotification(
        id: '4',
        type: NotificationType.payment,
        title: 'Payment Received',
        body: '+100 USDT from Alice',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      ZeroNotification(
        id: '5',
        type: NotificationType.friendRequest,
        title: 'Friend Request',
        body: 'Dax wants to add you as a contact',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ZeroNotification(
        id: '6',
        type: NotificationType.friendRequest,
        title: 'Friend Request',
        body: 'Nova wants to add you as a contact',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      ZeroNotification(
        id: '7',
        type: NotificationType.system,
        title: 'System',
        body: 'ZeroNode-7F is now online',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      ZeroNotification(
        id: '8',
        type: NotificationType.mention,
        title: 'Mention',
        body: '@you in ZeroFeed: "Check out this new node discovery protocol"',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }
}