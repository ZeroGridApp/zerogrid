import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class GroupMember {
  final String name;
  final int colorIndex;
  final String role;

  const GroupMember({
    required this.name,
    required this.colorIndex,
    this.role = 'member',
  });

  String get roleLabelZh {
    switch (role) {
      case 'owner':
        return '群主';
      case 'admin':
        return '管理员';
      default:
        return '成员';
    }
  }

  String get roleLabelEn {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      default:
        return 'Member';
    }
  }

  Color badgeColor(BuildContext context) {
    switch (role) {
      case 'owner':
        return context.zWarning;
      case 'admin':
        return context.zAccent;
      default:
        return context.zTextTertiary;
    }
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class GroupInfo {
  final String id;
  final String name;
  final String topic;
  final int memberCount;
  final String initials;
  final int avatarColorIndex;
  final DateTime createdAt;
  final String lastMessage;
  final String lastMessageTime;
  final String? lastMessageSenderName;
  final int unreadCount;
  final String inviteCode;
  final bool isMuted;

  GroupInfo({
    required this.id,
    required this.name,
    required this.topic,
    required this.memberCount,
    required this.initials,
    required this.avatarColorIndex,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.lastMessageSenderName,
    this.unreadCount = 0,
    required this.inviteCode,
    this.isMuted = false,
  });

  GroupInfo copyWith({
    String? lastMessage,
    String? lastMessageTime,
    String? lastMessageSenderName,
    int? unreadCount,
    int? memberCount,
    bool? isMuted,
  }) {
    return GroupInfo(
      id: id,
      name: name,
      topic: topic,
      memberCount: memberCount ?? this.memberCount,
      initials: initials,
      avatarColorIndex: avatarColorIndex,
      createdAt: createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      inviteCode: inviteCode,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class GroupChatService {
  factory GroupChatService() => _instance;
  GroupChatService._internal();
  static final GroupChatService _instance = GroupChatService._internal();

  final _random = Random();
  final List<GroupInfo> _groups = [];
  final Map<String, List<GroupMember>> _members = {};

  

  List<GroupInfo> getAllGroups() => List.unmodifiable(_groups);

  GroupInfo? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  GroupInfo createGroup(String name, String topic, String initials, int avatarColorIndex) {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final inviteCode = (_random.nextInt(900000) + 100000).toString();

    final group = GroupInfo(
      id: id,
      name: name,
      topic: topic,
      memberCount: 1,
      initials: initials,
      avatarColorIndex: avatarColorIndex,
      createdAt: DateTime.now(),
      lastMessage: '群组已创建 · 来发送第一条消息吧',
      lastMessageTime: '现在',
      lastMessageSenderName: null,
      unreadCount: 0,
      inviteCode: inviteCode,
    );

    _groups.insert(0, group);
    _members[id] = [
      GroupMember(name: 'You', colorIndex: avatarColorIndex, role: 'owner'),
    ];

    return group;
  }

  GroupInfo? joinByInviteCode(String code) {
    try {
      final group = _groups.firstWhere((g) => g.inviteCode == code);
      final updated = group.copyWith(memberCount: group.memberCount + 1);
      final index = _groups.indexWhere((g) => g.id == group.id);
      _groups[index] = updated;
      return updated;
    } catch (_) {
      return null;
    }
  }

  void leaveGroup(String id) {
    _groups.removeWhere((g) => g.id == id);
    _members.remove(id);
  }

  List<GroupMember> getMembers(String groupId) {
    return _members[groupId] ?? [
      GroupMember(name: 'You', colorIndex: 0, role: 'owner'),
    ];
  }

  void addMember(String groupId, GroupMember member) {
    _members.putIfAbsent(groupId, () => []);
    _members[groupId]!.add(member);

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(memberCount: _groups[index].memberCount + 1);
    }
  }

  void removeMember(String groupId, String name) {
    final members = _members[groupId];
    if (members != null) {
      members.removeWhere((m) => m.name == name);
    }

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1 && _groups[index].memberCount > 0) {
      _groups[index] = _groups[index].copyWith(memberCount: _groups[index].memberCount - 1);
    }
  }

  void updateLastMessage(String groupId, String message, String senderName, String time) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(
        lastMessage: message,
        lastMessageTime: time,
        lastMessageSenderName: senderName,
      );
    }
  }

  List<GroupInfo> searchGroups(String query) {
    final lowered = query.toLowerCase();
    return _groups.where((g) {
      return g.name.toLowerCase().contains(lowered) || g.topic.toLowerCase().contains(lowered);
    }).toList();
  }

  void markRead(String groupId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(unreadCount: 0);
    }
  }

  void incrementUnread(String groupId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(unreadCount: _groups[index].unreadCount + 1);
    }
  }

  Map<String, List<GroupMember>> get allMembers => Map.unmodifiable(_members);
}