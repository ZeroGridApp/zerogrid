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

  void seedDemoData() {
    if (_groups.isNotEmpty) return;

    final now = DateTime.now();

    _groups.addAll([
      GroupInfo(
        id: 'group_001',
        name: 'CipherSquad',
        topic: 'Cryptography & Privacy Tech',
        memberCount: 128,
        initials: 'CS',
        avatarColorIndex: 0,
        createdAt: now.subtract(const Duration(days: 90)),
        lastMessage: 'Alice: 新的加密方案已经通过审计',
        lastMessageTime: '14:32',
        lastMessageSenderName: 'Alice',
        unreadCount: 5,
        inviteCode: '482917',
      ),
      GroupInfo(
        id: 'group_002',
        name: 'Zero Builders',
        topic: 'Zero Ecosystem Development',
        memberCount: 47,
        initials: 'ZB',
        avatarColorIndex: 1,
        createdAt: now.subtract(const Duration(days: 60)),
        lastMessage: 'Bob: 发布了 v0.9.2，修复了 mesh 路由问题',
        lastMessageTime: '11:15',
        lastMessageSenderName: 'Bob',
        unreadCount: 0,
        inviteCode: '735104',
      ),
      GroupInfo(
        id: 'group_003',
        name: 'Web3 中文圈',
        topic: '区块链技术与去中心化讨论',
        memberCount: 356,
        initials: 'W3',
        avatarColorIndex: 2,
        createdAt: now.subtract(const Duration(days: 120)),
        lastMessage: '王伟: 以太坊 L2 的最新进展讨论',
        lastMessageTime: '09:48',
        lastMessageSenderName: '王伟',
        unreadCount: 23,
        inviteCode: '201846',
      ),
      GroupInfo(
        id: 'group_004',
        name: 'DeFi Lounge',
        topic: 'Decentralized Finance Alpha',
        memberCount: 89,
        initials: 'DL',
        avatarColorIndex: 3,
        createdAt: now.subtract(const Duration(days: 45)),
        lastMessage: 'CryptoWhale: GM frens, any alpha today?',
        lastMessageTime: '昨天',
        lastMessageSenderName: 'CryptoWhale',
        unreadCount: 2,
        inviteCode: '963520',
      ),
      GroupInfo(
        id: 'group_005',
        name: 'Node Operators',
        topic: 'Infrastructure & Node Management',
        memberCount: 34,
        initials: 'NO',
        avatarColorIndex: 4,
        createdAt: now.subtract(const Duration(days: 30)),
        lastMessage: 'NodeMaster: 服务器维护通知',
        lastMessageTime: '昨天',
        lastMessageSenderName: 'NodeMaster',
        unreadCount: 0,
        inviteCode: '518293',
      ),
    ]);

    _members['group_001'] = [
      const GroupMember(name: 'Alice', colorIndex: 0, role: 'owner'),
      const GroupMember(name: 'Bob', colorIndex: 1, role: 'admin'),
      const GroupMember(name: 'Charlie', colorIndex: 2, role: 'member'),
      const GroupMember(name: 'Diana', colorIndex: 3, role: 'member'),
      const GroupMember(name: '张明', colorIndex: 4, role: 'member'),
    ];

    _members['group_002'] = [
      const GroupMember(name: 'Bob', colorIndex: 1, role: 'owner'),
      const GroupMember(name: 'Alice', colorIndex: 0, role: 'admin'),
      const GroupMember(name: 'Eve', colorIndex: 3, role: 'member'),
      const GroupMember(name: '李华', colorIndex: 5, role: 'member'),
    ];

    _members['group_003'] = [
      const GroupMember(name: '王伟', colorIndex: 2, role: 'owner'),
      const GroupMember(name: '张明', colorIndex: 4, role: 'admin'),
      const GroupMember(name: 'Alice', colorIndex: 0, role: 'member'),
      const GroupMember(name: 'Bob', colorIndex: 1, role: 'member'),
    ];

    _members['group_004'] = [
      const GroupMember(name: 'CryptoWhale', colorIndex: 3, role: 'owner'),
      const GroupMember(name: 'DeFiKing', colorIndex: 4, role: 'admin'),
      const GroupMember(name: 'YieldFarmer', colorIndex: 5, role: 'member'),
    ];

    _members['group_005'] = [
      const GroupMember(name: 'NodeMaster', colorIndex: 4, role: 'owner'),
      const GroupMember(name: 'ServerGuru', colorIndex: 0, role: 'admin'),
      const GroupMember(name: 'Bob', colorIndex: 1, role: 'member'),
      const GroupMember(name: 'Eve', colorIndex: 3, role: 'member'),
    ];
  }

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