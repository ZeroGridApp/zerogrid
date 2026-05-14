import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/zero_theme.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_card.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'group_chat_list_screen.dart';
import '../channel/channel_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<_ChatPreview> _chats = [
    _ChatPreview(name: '0xCat', lastMessage: '新的 NFT drop 准备好了吗？', lastType: MsgType.text, time: '2m ago', unread: 3, isOnline: true),
    _ChatPreview(name: 'VoidWalker', lastMessage: '[Voice 0:42]', lastType: MsgType.voice, time: '1h ago', unread: 0),
    _ChatPreview(name: 'Ming', lastMessage: '[Image] audit_report_final.png', lastType: MsgType.image, time: '3h ago', unread: 1, isOnline: true),
    _ChatPreview(name: 'CipherSquad', lastMessage: 'Alice: 白皮书 v2 已发布', lastType: MsgType.text, time: '5h ago', unread: 12, isGroup: true, memberCount: 42),
    _ChatPreview(name: 'SolSurfer', lastMessage: '[File] tokenomics.pdf · 3.2MB', lastType: MsgType.file, time: '1d ago', unread: 0),
    _ChatPreview(name: 'ZeroCore', lastMessage: '系统升级 v0.2.0 已推送', lastType: MsgType.system, time: '2d ago', unread: 0),
    _ChatPreview(name: 'EthAnon', lastMessage: '[Location] DeFi Summit', lastType: MsgType.location, time: '3d ago', unread: 0),
  ];

  List<_ChatPreview> get _sortedChats {
    final list = _searchQuery.isEmpty
        ? _chats.toList()
        : _chats.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteChat(_ChatPreview chat) {
    setState(() => _chats.remove(chat));
  }

  void _togglePin(_ChatPreview chat) {
    final index = _chats.indexOf(chat);
    if (index == -1) return;
    setState(() => _chats[index] = chat.copyWith(isPinned: !chat.isPinned));
  }

  void _toggleFavorite(_ChatPreview chat) {
    final index = _chats.indexOf(chat);
    if (index == -1) return;
    setState(() => _chats[index] = chat.copyWith(isFavorite: !chat.isFavorite));
  }

  void _toggleBlock(_ChatPreview chat) {
    final index = _chats.indexOf(chat);
    if (index == -1) return;
    setState(() => _chats[index] = chat.copyWith(isBlocked: !chat.isBlocked));
  }

  void _showNewChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.zAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_rounded, color: context.zAccent, size: 20),
                  ),
                  title: Text('New Chat', style: ZeroTypography.bodyBold(context)),
                  subtitle: Text('Start a private conversation', style: ZeroTypography.caption(context)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.zCeladonGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group_add_rounded, color: context.zCeladon, size: 20),
                  ),
                  title: Text('New Group', style: ZeroTypography.bodyBold(context)),
                  subtitle: Text('Create an encrypted group', style: ZeroTypography.caption(context)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const GroupChatListScreen()),
                    );
                  },
                ),
                const SizedBox(height: ZeroSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChatActions(BuildContext context, _ChatPreview chat, bool isZh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
                  child: Text(
                    chat.name,
                    style: ZeroTypography.title(context).copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.zAccent.withOpacity(chat.isPinned ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: context.zAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    chat.isPinned ? (isZh ? '取消置顶' : 'Unpin') : (isZh ? '置顶' : 'Pin to top'),
                    style: ZeroTypography.bodyBold(context),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _togglePin(chat);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: chat.isFavorite ? Colors.amber.withOpacity(0.2) : Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      chat.isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    chat.isFavorite ? (isZh ? '取消收藏' : 'Unfavorite') : (isZh ? '收藏' : 'Favorite'),
                    style: ZeroTypography.bodyBold(context),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toggleFavorite(chat);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: chat.isBlocked ? context.zTextTertiary.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      chat.isBlocked ? Icons.check_circle_outline : Icons.block,
                      color: chat.isBlocked ? context.zTextTertiary : Colors.orange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    chat.isBlocked ? (isZh ? '取消屏蔽' : 'Unblock') : (isZh ? '屏蔽' : 'Block'),
                    style: ZeroTypography.bodyBold(context),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toggleBlock(chat);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.zError.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline, color: context.zError, size: 20),
                  ),
                  title: Text(
                    isZh ? '删除' : 'Delete',
                    style: ZeroTypography.bodyBold(context).copyWith(color: context.zError),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteChat(chat);
                  },
                ),
                const SizedBox(height: ZeroSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = ZeroTheme.isZh(context);
    final chats = _sortedChats;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.appTitle, style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: context.zTextPrimary)),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: context.zAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text('E2EE', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1, color: context.zAccent)),
            ),
          ],
        ),
        actions: [
            Padding(
              padding: EdgeInsets.only(right: ZeroSpacing.xs),
              child: IconButton(
                icon: Icon(Icons.campaign_rounded, color: context.zAccent, size: 22),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ChannelScreen())),
                tooltip: 'Channels',
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: ZeroSpacing.sm),
              child: IconButton(icon: Icon(Icons.add_circle_outline, color: context.zTextSecondary), onPressed: () => _showNewChatMenu(context)),
            ),
          ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: context.zTextTertiary.withOpacity(0.3)),
                        SizedBox(height: ZeroSpacing.md),
                        Text(l10n.noConversations, style: ZeroTypography.body(context).copyWith(color: context.zTextTertiary)),
                        const SizedBox(height: 4),
                        Text(l10n.noConversationsHint, style: ZeroTypography.caption(context)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.sm),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
                        child: _SwipeableTile(
                          actions: [
                            _SwipeAction(
                              label: isZh ? '删除' : 'Delete',
                              color: context.zError,
                              icon: Icons.delete_outline,
                              onTap: () => _deleteChat(chat),
                            ),
                            _SwipeAction(
                              label: chat.isBlocked
                                  ? (isZh ? '取消屏蔽' : 'Unblock')
                                  : (isZh ? '屏蔽' : 'Block'),
                              color: chat.isBlocked ? context.zTextTertiary : Colors.orange.shade700,
                              icon: chat.isBlocked ? Icons.check_circle_outline : Icons.block,
                              onTap: () => _toggleBlock(chat),
                            ),
                            _SwipeAction(
                              label: chat.isPinned
                                  ? (isZh ? '取消置顶' : 'Unpin')
                                  : (isZh ? '置顶' : 'Pin'),
                              color: context.zAccent,
                              icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                              onTap: () => _togglePin(chat),
                            ),
                          ],
                          child: _ChatTile(
                            chat: chat,
                            isZh: isZh,
                            onTap: () {
                              if (chat.isGroup) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(fullscreenDialog: true, 
                                    builder: (_) => GroupChatScreen(
                                      groupName: chat.name,
                                      memberCount: chat.memberCount,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(fullscreenDialog: true, 
                                    builder: (_) => ChatScreen(peerName: chat.name),
                                  ),
                                );
                              }
                            },
                            onLongPress: () => _showChatActions(context, chat, isZh),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(ZeroSpacing.screenHorizontal, ZeroSpacing.sm, ZeroSpacing.screenHorizontal, ZeroSpacing.xs),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: context.zSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.zFrostWhiteStrong, width: 0.5)),
        child: TextField(
          controller: _searchController,
          style: ZeroTypography.body(context).copyWith(fontSize: 14, color: context.zTextPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchContacts,
            hintStyle: ZeroTypography.caption(context).copyWith(color: context.zTextTertiary),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.zTextTertiary),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close, size: 16, color: context.zTextTertiary),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }
}

class _ChatPreview {
  final String name;
  final String lastMessage;
  final MsgType lastType;
  final String time;
  final int unread;
  final bool isGroup;
  final bool isOnline;
  final int memberCount;
  final bool isPinned;
  final bool isFavorite;
  final bool isBlocked;

  const _ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.lastType,
    required this.time,
    required this.unread,
    this.isGroup = false,
    this.isOnline = false,
    this.memberCount = 4,
    this.isPinned = false,
    this.isFavorite = false,
    this.isBlocked = false,
  });

  _ChatPreview copyWith({
    String? name,
    String? lastMessage,
    MsgType? lastType,
    String? time,
    int? unread,
    bool? isGroup,
    bool? isOnline,
    int? memberCount,
    bool? isPinned,
    bool? isFavorite,
    bool? isBlocked,
  }) {
    return _ChatPreview(
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastType: lastType ?? this.lastType,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isGroup: isGroup ?? this.isGroup,
      isOnline: isOnline ?? this.isOnline,
      memberCount: memberCount ?? this.memberCount,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _ChatPreview chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isZh;

  const _ChatTile({required this.chat, required this.onTap, this.onLongPress, this.isZh = false});

  IconData _lastMsgIcon() {
    switch (chat.lastType) {
      case MsgType.image: return Icons.image_outlined;
      case MsgType.voice: return Icons.mic_none_outlined;
      case MsgType.file: return Icons.insert_drive_file_outlined;
      case MsgType.location: return Icons.location_on_outlined;
      case MsgType.system: return Icons.campaign_outlined;
      default: return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: chat.isPinned
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(left: BorderSide(color: context.zAccent.withOpacity(0.3), width: 3)),
            )
          : null,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: ZeroCard(
          onTap: null,
          padding: EdgeInsets.all(ZeroSpacing.md),
          child: Row(
            children: [
              Stack(
                children: [
                  _Avatar(name: chat.name, isGroup: chat.isGroup, size: ZeroSpacing.avatarLg),
                  if (chat.isOnline)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.zSuccess, border: Border.all(color: context.zSurface, width: 2)),
                      ),
                    ),
                ],
              ),
              SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (chat.isPinned)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 12, color: context.zAccent),
                          ),
                        if (chat.isFavorite)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star, size: 14, color: Colors.amber),
                          ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(chat.name, style: ZeroTypography.title(context).copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
                              ),
                              if (chat.isBlocked)
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Text(
                                    isZh ? '[已屏蔽]' : '[Blocked]',
                                    style: ZeroTypography.caption(context).copyWith(
                                      color: context.zTextTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(chat.time, style: ZeroTypography.caption(context)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (chat.lastType != MsgType.text)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(_lastMsgIcon(), size: 12, color: context.zTextTertiary),
                          ),
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: ZeroTypography.caption(context).copyWith(color: chat.unread > 0 && !chat.isBlocked ? context.zTextSecondary : context.zTextTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unread > 0 && !chat.isBlocked)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: context.zAccent, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              chat.unread > 99 ? '99+' : '${chat.unread}',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: context.zBg),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isGroup;
  final double size;

  const _Avatar({required this.name, this.isGroup = false, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [context.zAccent.withOpacity(isGroup ? 0.5 : 0.3), context.zCeladon.withOpacity(isGroup ? 0.5 : 0.3)]),
        border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
      ),
      alignment: Alignment.center,
      child: isGroup
          ? Icon(Icons.people_alt_outlined, size: size * 0.4, color: context.zAccent)
          : Text(name[0].toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: size * 0.38, fontWeight: FontWeight.w500, color: context.zAccent)),
    );
  }
}

class _SwipeableTile extends StatefulWidget {
  final Widget child;
  final List<_SwipeAction> actions;

  const _SwipeableTile({required this.child, required this.actions});

  @override
  State<_SwipeableTile> createState() => _SwipeableTileState();
}

class _SwipeableTileState extends State<_SwipeableTile> {
  bool _open = false;

  double get _actionsWidth => widget.actions.length * 72.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          setState(() => _open = true);
        } else if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          setState(() => _open = false);
        }
      },
      onTap: () {
        if (_open) setState(() => _open = false);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: widget.actions.map((a) => GestureDetector(
                  onTap: () {
                    a.onTap();
                    setState(() => _open = false);
                  },
                  child: Container(
                    width: 72,
                    color: a.color,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, color: Colors.white, size: 20),
                        SizedBox(height: 4),
                        Text(a.label, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              transform: Matrix4.translationValues(_open ? -_actionsWidth : 0, 0, 0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeAction {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SwipeAction({required this.label, required this.color, required this.icon, required this.onTap});
}