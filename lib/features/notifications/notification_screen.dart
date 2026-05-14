import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();

  List<ZeroNotification> get _todayNotifications {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _service.all.where((n) => n.timestamp.isAfter(cutoff)).toList();
  }

  List<ZeroNotification> get _earlierNotifications {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _service.all.where((n) => !n.timestamp.isAfter(cutoff)).toList();
  }

  String _relativeTime(DateTime timestamp, bool isZh) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return isZh ? '刚刚' : 'now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }

  String _typeEmoji(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return '💬';
      case NotificationType.payment:
        return '💰';
      case NotificationType.friendRequest:
        return '👋';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.mention:
        return '@';
    }
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return context.zAccent;
      case NotificationType.payment:
        return context.zSuccess;
      case NotificationType.friendRequest:
        return context.zCeladon;
      case NotificationType.system:
        return context.zWarning;
      case NotificationType.mention:
        return context.zAccent;
    }
  }

  Future<void> _onRefresh() async {
    setState(() {});
  }

  void _markAllRead() {
    setState(() {
      _service.markAllRead();
    });
  }

  void _onTapNotification(ZeroNotification notification) {
    setState(() {
      _service.markRead(notification.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isZh ? '通知' : 'Notifications',
          style: ZeroTypography.title(context).copyWith(
            color: context.zTextPrimary,
          ),
        ),
        actions: [
          if (_service.unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: context.zAccent,
                padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
              ),
              child: Text(
                isZh ? '全部已读' : 'Mark All Read',
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _service.all.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: context.zAccent,
              backgroundColor: context.zSurfaceRaised,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                  vertical: ZeroSpacing.md,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_todayNotifications.isNotEmpty) ...[
                    _buildSectionHeader(isZh ? '今天' : 'Today'),
                    const SizedBox(height: ZeroSpacing.sm),
                    ..._todayNotifications.map(_buildNotificationCard),
                  ],
                  if (_earlierNotifications.isNotEmpty) ...[
                    const SizedBox(height: ZeroSpacing.lg),
                    _buildSectionHeader(isZh ? '更早' : 'Earlier'),
                    const SizedBox(height: ZeroSpacing.sm),
                    ..._earlierNotifications.map(_buildNotificationCard),
                  ],
                  const SizedBox(height: ZeroSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: context.zTextTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '暂无通知' : 'No notifications',
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: ZeroSpacing.sm),
      child: Text(
        title,
        style: ZeroTypography.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: context.zTextTertiary,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(ZeroNotification notification) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final emoji = _typeEmoji(notification.type);
    final color = _typeColor(notification.type);
    final isMention = notification.type == NotificationType.mention;

    return GestureDetector(
      onTap: () => _onTapNotification(notification),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.md,
        ),
        decoration: BoxDecoration(
          color: notification.read ? Colors.transparent : context.zSurfaceOverlay.withOpacity(0.4),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notification.read)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: ZeroSpacing.sm),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.zAccent,
                  ),
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMention
                    ? color.withOpacity(0.12)
                    : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: isMention ? 18 : 18,
                  fontWeight: isMention ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: ZeroSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      Text(
                        _relativeTime(notification.timestamp, isZh),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: ZeroTypography.caption(context).copyWith(
                      color: context.zTextSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}