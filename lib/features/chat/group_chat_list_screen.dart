import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/chat/group_chat_service.dart';
import '../../widgets/zero_card.dart';
import 'group_chat_screen.dart';

class GroupChatListScreen extends StatefulWidget {
  const GroupChatListScreen({super.key});

  @override
  State<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends State<GroupChatListScreen> {
  final _groupService = GroupChatService();
  String _sortBy = 'recent';

  static const _avatarColorOptions = [
    _AvatarColorOption(icon: Icons.shield, colorIndex: 0),
    _AvatarColorOption(icon: Icons.bolt, colorIndex: 1),
    _AvatarColorOption(icon: Icons.public, colorIndex: 2),
    _AvatarColorOption(icon: Icons.star, colorIndex: 3),
    _AvatarColorOption(icon: Icons.favorite, colorIndex: 4),
    _AvatarColorOption(icon: Icons.diamond, colorIndex: 5),
  ];

  @override
  void initState() {
    super.initState();
  }

  List<GroupInfo> get _sortedGroups {
    final groups = _groupService.getAllGroups();
    if (_sortBy == 'members') {
      final sorted = List<GroupInfo>.from(groups);
      sorted.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      return sorted;
    }
    return groups;
  }

  void _showCreateGroupModal() {
    final isZh = ZeroTheme.isZh(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColorIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.zSurface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(ZeroSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.zDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      isZh ? '创建群组' : 'Create Group',
                      style: ZeroTypography.headline(context),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    TextField(
                      controller: nameController,
                      style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
                      decoration: InputDecoration(
                        labelText: '${isZh ? '群组名称' : 'Group Name'} *',
                        labelStyle: ZeroTypography.caption(context),
                        hintText: 'e.g. Zero Devs',
                        hintStyle: ZeroTypography.caption(context).copyWith(color: context.zTextDisabled),
                        filled: true,
                        fillColor: context.zBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zAccent, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.md,
                          vertical: ZeroSpacing.md,
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    TextField(
                      controller: descController,
                      style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
                      decoration: InputDecoration(
                        labelText: isZh ? '群组描述' : 'Description',
                        labelStyle: ZeroTypography.caption(context),
                        hintText: isZh ? '这个群组是关于什么的？' : 'What is this group about?',
                        hintStyle: ZeroTypography.caption(context).copyWith(color: context.zTextDisabled),
                        filled: true,
                        fillColor: context.zBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide(color: context.zAccent, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.md,
                          vertical: ZeroSpacing.md,
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '群组头像' : 'Group Avatar',
                      style: ZeroTypography.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: context.zTextSecondary,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                    Wrap(
                      spacing: ZeroSpacing.sm,
                      runSpacing: ZeroSpacing.sm,
                      children: List.generate(_avatarColorOptions.length, (i) {
                        final option = _avatarColorOptions[i];
                        final isSelected = selectedColorIndex == i;
                        final colors = _avatarGradient(option.colorIndex);
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColorIndex = i),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected ? context.zTextPrimary : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              option.icon,
                              size: 22,
                              color: context.zBg,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zAccent,
                          foregroundColor: context.zBg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isZh ? '请输入群组名称' : 'Please enter a group name'),
                                backgroundColor: context.zWarning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final topic = descController.text.trim().isEmpty
                              ? 'New Group'
                              : descController.text.trim();
                          final initials = name.length > 1
                              ? name.substring(0, 2).toUpperCase()
                              : name[0].toUpperCase();
                          final group = _groupService.createGroup(
                            name,
                            topic,
                            initials,
                            selectedColorIndex,
                          );
                          Navigator.of(ctx).pop();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isZh
                                    ? '群组已创建 · 来发送第一条消息吧'
                                    : 'Group created · Be the first to say hi',
                              ),
                              backgroundColor: context.zSuccess,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          isZh ? '创建' : 'Create',
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: context.zBg,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJoinByCodeModal() {
    final isZh = ZeroTheme.isZh(context);
    final codeController = TextEditingController(text: '000000');
    final existingGroups = _groupService.getAllGroups();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.zSurface,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(ZeroSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.zDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [context.zAccent.withOpacity(0.15), context.zCeladon.withOpacity(0.15)],
                        ),
                      ),
                      child: Icon(Icons.vpn_key_rounded, color: context.zAccent, size: 22),
                    ),
                    SizedBox(width: ZeroSpacing.md),
                    Text(
                      isZh ? '邀请码加入' : 'Join by Invite Code',
                      style: ZeroTypography.headline(context),
                    ),
                  ],
                ),
                SizedBox(height: ZeroSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(
                    isZh
                        ? '输入群组成员分享的 6 位邀请码即可加入'
                        : 'Enter the 6-digit code shared by a group member to join instantly.',
                    style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                  ),
                ),
                SizedBox(height: ZeroSpacing.lg),
                TextField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    color: context.zTextPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: context.zBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      borderSide: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      borderSide: BorderSide(color: context.zAccent, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.lg,
                    ),
                  ),
                ),
                if (existingGroups.isNotEmpty) ...[
                  SizedBox(height: ZeroSpacing.sm),
                  Text(
                    isZh ? '演示邀请码：' : 'Demo invite codes:',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 10,
                      color: context.zTextTertiary,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.xs),
                  Wrap(
                    spacing: ZeroSpacing.sm,
                    runSpacing: ZeroSpacing.xs,
                    children: existingGroups.map((g) {
                      return GestureDetector(
                        onTap: () => codeController.text = g.inviteCode,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.zAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                g.inviteCode,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.zAccent,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                g.name,
                                style: ZeroTypography.caption(context).copyWith(
                                  fontSize: 10,
                                  color: context.zTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: ZeroSpacing.lg),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.zAccent,
                      foregroundColor: context.zBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      ),
                    ),
                    onPressed: () {
                      final code = codeController.text.trim();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isZh ? '请输入有效的 6 位邀请码' : 'Please enter a valid 6-digit code'),
                            backgroundColor: context.zWarning,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      final joined = _groupService.joinByInviteCode(code);
                      Navigator.of(ctx).pop();
                      if (joined != null) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isZh ? '成功加入演示群组！' : 'Joined demo group successfully!'),
                            backgroundColor: context.zSuccess,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isZh ? '邀请码无效，试试 \'000000\'' : 'Invalid invite code. Try \'000000\' for demo.',
                            ),
                            backgroundColor: context.zWarning,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Text(
                      isZh ? '加入' : 'Join',
                      style: ZeroTypography.bodyBold(context).copyWith(
                        color: context.zBg,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _leaveGroup(GroupInfo group) {
    final isZh = ZeroTheme.isZh(context);
    _groupService.leaveGroup(group.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh ? '已退出 "${group.name}"' : 'Left "${group.name}"',
        ),
        backgroundColor: context.zError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMuteGroup(GroupInfo group) {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh ? '${group.name}：已静音 8 小时' : '${group.name}: notifications muted for 8 hours',
        ),
        backgroundColor: context.zWarning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGroupInfo(GroupInfo group) {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${group.name} · ${group.memberCount} ${isZh ? '成员' : 'members'} · ${group.topic}',
        ),
        backgroundColor: context.zAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Color> _avatarGradient(int index) {
    final palettes = [
      [context.zAccent, context.zCeladon],
      [context.zCeladon, context.zSuccess],
      [context.zAccent, context.zWarning],
      [const Color(0xFF7B6FDE), const Color(0xFFC084FC)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
    ];
    final p = palettes[index % palettes.length];
    return [p[0], p[1]];
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final groups = _sortedGroups;
    final totalUnread =
        groups.fold<int>(0, (sum, g) => sum + g.unreadCount);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              isZh ? '群聊' : 'Group Chat',
              style: ZeroTypography.title(context).copyWith(
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.zCeladonGlow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'E2EE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: context.zCeladon,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (totalUnread > 0)
            Container(
              margin: EdgeInsets.only(right: 4),
              padding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.zAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalUnread',
                style: ZeroTypography.monoSmall(context).copyWith(
                  color: context.zAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.vpn_key_rounded,
              color: context.zTextSecondary,
              size: 22,
            ),
            onPressed: _showJoinByCodeModal,
            tooltip: isZh ? '邀请码加入' : 'Join by Invite Code',
          ),
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: context.zAccent,
              size: 24,
            ),
            onPressed: _showCreateGroupModal,
            tooltip: isZh ? '创建群组' : 'Create Group',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context, isZh, groups),
          const SizedBox(height: ZeroSpacing.sm),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: context.zTextDisabled,
                        ),
                        SizedBox(height: ZeroSpacing.md),
                        Text(
                          isZh ? '暂无群组' : 'No groups',
                          style: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.screenHorizontal,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final g = groups[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
                        child: _SwipeableGroupTile(
                          group: g,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(fullscreenDialog: true,
                                builder: (_) => GroupChatScreen(
                                  groupName: g.name,
                                  memberCount: g.memberCount,
                                ),
                              ),
                            );
                          },
                          onLeave: () => _leaveGroup(g),
                          onMute: () => _toggleMuteGroup(g),
                          onInfo: () => _showGroupInfo(g),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isZh, List<GroupInfo> groups) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Text(
            '${groups.length} ${isZh ? '个群组' : 'groups'}',
            style: ZeroTypography.caption(context).copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: context.zTextTertiary,
            ),
          ),
          const Spacer(),
          _sortChip(context, isZh ? '最近' : 'Recent', _sortBy == 'recent', () {
            setState(() => _sortBy = 'recent');
          }),
          const SizedBox(width: ZeroSpacing.sm),
          _sortChip(context, isZh ? '成员数' : 'Members', _sortBy == 'members', () {
            setState(() => _sortBy = 'members');
          }),
        ],
      ),
    );
  }

  Widget _sortChip(BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? context.zAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: active
                ? context.zAccent.withOpacity(0.25)
                : context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? context.zAccent : context.zTextTertiary,
          ),
        ),
      ),
    );
  }
}

class _AvatarColorOption {
  final IconData icon;
  final int colorIndex;

  const _AvatarColorOption({required this.icon, required this.colorIndex});
}

class _SwipeableGroupTile extends StatelessWidget {
  final GroupInfo group;
  final VoidCallback onTap;
  final VoidCallback onLeave;
  final VoidCallback onMute;
  final VoidCallback onInfo;

  const _SwipeableGroupTile({
    required this.group,
    required this.onTap,
    required this.onLeave,
    required this.onMute,
    required this.onInfo,
  });

  List<Color> _avatarGradient(int index, BuildContext context) {
    final palettes = [
      [context.zAccent, context.zCeladon],
      [context.zCeladon, context.zSuccess],
      [context.zAccent, context.zWarning],
      [const Color(0xFF7B6FDE), const Color(0xFFC084FC)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
    ];
    final p = palettes[index % palettes.length];
    return [p[0], p[1]];
  }

  IconData _avatarIcon(int index) {
    const icons = [
      Icons.shield,
      Icons.bolt,
      Icons.public,
      Icons.star,
      Icons.favorite,
      Icons.diamond,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final colors = _avatarGradient(group.avatarColorIndex, context);
    final iconData = _avatarIcon(group.avatarColorIndex);

    final cardWidget = ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      onTap: onTap,
      child: Row(
        children: [
          _GroupAvatar(
            colors: colors,
            iconData: iconData,
            initials: group.initials,
            isOnline: group.unreadCount > 0,
          ),
          SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: ZeroTypography.title(context).copyWith(
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      group.lastMessageTime.isEmpty ? (isZh ? '现在' : 'Now') : group.lastMessageTime,
                      style: ZeroTypography.monoSmall(context).copyWith(
                        fontSize: 10,
                        color: group.unreadCount > 0
                            ? context.zAccent
                            : context.zTextTertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.lastMessage,
                        style: ZeroTypography.body(context).copyWith(
                          fontSize: 13,
                          color: group.unreadCount > 0
                              ? context.zTextSecondary
                              : context.zTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 12,
                      color: context.zTextDisabled,
                    ),
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.zFrostWhite,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${group.memberCount} ${isZh ? '成员' : 'members'}',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.zTextTertiary,
                        ),
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.sm),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.zTextDisabled,
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.sm),
                    Flexible(
                      child: Text(
                        group.topic,
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                          color: context.zTextDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (group.unreadCount > 0) ...[
            SizedBox(width: ZeroSpacing.sm),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.zAccent, context.zCeladon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                group.unreadCount > 99
                    ? '99+'
                    : '${group.unreadCount}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.zBg,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Dismissible(
      key: Key('group_${group.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onInfo();
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          final result = await showModalBottomSheet<_SwipeAction>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _SwipeActionSheet(
              onLeave: onLeave,
              onMute: onMute,
            ),
          );
          if (result == _SwipeAction.leave) {
            onLeave();
            return true;
          }
          return false;
        }
        return false;
      },
      background: Container(
        margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
        decoration: BoxDecoration(
          color: context.zAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: ZeroSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: context.zAccent, size: 22),
            SizedBox(width: ZeroSpacing.sm),
            Text(
              ZeroTheme.isZh(context) ? '信息' : 'Info',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.zAccent,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
        decoration: BoxDecoration(
          color: context.zError.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: ZeroSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ZeroTheme.isZh(context) ? '退出' : 'Leave',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.zError,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Icon(Icons.exit_to_app, color: context.zError, size: 22),
          ],
        ),
      ),
      child: cardWidget,
    );
  }
}

enum _SwipeAction { leave, mute }

class _SwipeActionSheet extends StatelessWidget {
  final VoidCallback onLeave;
  final VoidCallback onMute;

  const _SwipeActionSheet({
    required this.onLeave,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.zDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: ZeroSpacing.lg),
          _ActionRow(
            icon: Icons.volume_off_rounded,
            label: isZh ? '静音 8 小时' : 'Mute for 8 hours',
            color: context.zWarning,
            onTap: () {
              Navigator.of(context).pop();
              onMute();
            },
          ),
          SizedBox(height: ZeroSpacing.sm),
          _ActionRow(
            icon: Icons.exit_to_app_rounded,
            label: isZh ? '退出群组' : 'Leave Group',
            color: context.zError,
            onTap: () {
              Navigator.of(context).pop(_SwipeAction.leave);
            },
          ),
          SizedBox(height: ZeroSpacing.md),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: ZeroSpacing.md),
            Text(
              label,
              style: ZeroTypography.bodyBold(context).copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final List<Color> colors;
  final IconData iconData;
  final String initials;
  final bool isOnline;

  const _GroupAvatar({
    required this.colors,
    required this.iconData,
    required this.initials,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final size = ZeroSpacing.avatarLg.toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors[0].withOpacity(0.25), colors[1].withOpacity(0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials.length > 2
                  ? initials.substring(0, 2)
                  : initials,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: initials.length > 2 ? 12 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: colors[0],
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.zBg,
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? context.zSuccess : context.zTextDisabled,
                    border: Border.all(
                      color: context.zBg,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}