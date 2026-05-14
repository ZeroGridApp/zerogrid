import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_card.dart';
import '../chat/group_chat_list_screen.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _coverGradients = [
    [Color(0xFF1E2A3A), Color(0xFF0F1620)],
    [Color(0xFF2A1E3A), Color(0xFF160F20)],
    [Color(0xFF1E3A2E), Color(0xFF0F2018)],
    [Color(0xFF3A2A1E), Color(0xFF20160F)],
    [Color(0xFF2E1E3A), Color(0xFF180F20)],
    [Color(0xFF1E3A3A), Color(0xFF0F2020)],
  ];

  static const _discoverSpaces = [
    _DiscoveredSpace(
      name: 'CipherSquad',
      memberCount: 128,
      description: '密码学与隐私技术讨论组。探讨零知识证明、同态加密与后量子密码学。',
      lastActive: '3分钟前',
      gradientIndex: 0,
    ),
    _DiscoveredSpace(
      name: 'Zero Builders',
      memberCount: 47,
      description: 'Zero 生态开发者社区。一起构建下一代去中心化社交网络。',
      lastActive: '12分钟前',
      gradientIndex: 1,
    ),
    _DiscoveredSpace(
      name: 'Web3 中文圈',
      memberCount: 356,
      description: '区块链技术与去中心化讨论。NFT、DeFi、DAO — 华语区最活跃的 Web3 空间。',
      lastActive: '1分钟前',
      gradientIndex: 2,
    ),
    _DiscoveredSpace(
      name: 'DeFi Lounge',
      memberCount: 89,
      description: '去中心化金融前沿。Yield farming、流动性挖矿与协议研究。',
      lastActive: '25分钟前',
      gradientIndex: 3,
    ),
    _DiscoveredSpace(
      name: '水墨实验室',
      memberCount: 63,
      description: 'UI/UX 设计与数字艺术。探索东方美学在数字世界的当代表达。',
      lastActive: '8分钟前',
      gradientIndex: 4,
    ),
    _DiscoveredSpace(
      name: 'Node Operators',
      memberCount: 215,
      description: 'Zero 节点运营者社区。网络健康、收益优化与基础设施讨论。',
      lastActive: '5分钟前',
      gradientIndex: 5,
    ),
  ];

  final List<_MySpace> _mySpaces = [
    _MySpace(
      name: 'CipherSquad',
      memberCount: 128,
      lastActivity: '刚才',
      hasUnread: true,
      gradientIndex: 0,
    ),
    _MySpace(
      name: '水墨实验室',
      memberCount: 63,
      lastActivity: '8分钟前',
      hasUnread: false,
      gradientIndex: 4,
    ),
  ];

  final Set<String> _pendingJoinIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateSpaceModal() {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.all(ZeroSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.zTextDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.lg),
                Text(
                  l10n.spaceCreate,
                  style: ZeroTypography.headline(context),
                ),
                SizedBox(height: 4),
                Text(
                  isZh ? '创建一个新的空间，邀请朋友一起交流' : 'Create a new space and invite friends to chat',
                  style: ZeroTypography.body(context),
                ),
                SizedBox(height: ZeroSpacing.lg),
                TextField(
                  controller: nameController,
                  style: ZeroTypography.bodyBold(context),
                  decoration: InputDecoration(
                    hintText: l10n.spaceName,
                    hintStyle: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
                    ),
                    filled: true,
                    fillColor: context.zSurfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      borderSide: BorderSide.none,
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
                  maxLines: 3,
                  style: ZeroTypography.body(context),
                  decoration: InputDecoration(
                    hintText: l10n.spaceDescription,
                    hintStyle: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
                    ),
                    filled: true,
                    fillColor: context.zSurfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      setState(() {
                        _mySpaces.add(_MySpace(
                          name: name,
                          memberCount: 1,
                          lastActivity: isZh ? '刚刚创建' : 'Just created',
                          hasUnread: false,
                          gradientIndex: _mySpaces.length % _coverGradients.length,
                        ));
                      });
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.zAccent,
                      foregroundColor: context.zBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      ),
                    ),
                    child: Text(
                      l10n.spaceCreateButton,
                      style: ZeroTypography.bodyBold(context).copyWith(
                        color: context.zBg,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinDialog(_DiscoveredSpace space) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.zSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          ),
          title: Text(
            '${l10n.spaceJoinConfirm}「${space.name}」',
            style: ZeroTypography.title(context),
          ),
          content: Text(
            l10n.spaceJoinConfirmDesc,
            style: ZeroTypography.body(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.cancel,
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: context.zTextTertiary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _pendingJoinIds.add(space.name);
                });
                Navigator.of(ctx).pop();
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (!mounted) return;
                  setState(() {
                    _pendingJoinIds.remove(space.name);
                    _mySpaces.add(_MySpace(
                      name: space.name,
                      memberCount: space.memberCount + 1,
                      lastActivity: l10n.spaceJoined,
                      hasUnread: true,
                      gradientIndex: space.gradientIndex,
                    ));
                  });
                });
              },
              child: Text(
                l10n.spaceJoin,
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: context.zCeladon,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSpace(_MySpace space) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, 
        builder: (_) => _SpaceDetailScreen(space: space),
      ),
    );
  }

  void _openGroupChats() {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const GroupChatListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.spaceTitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.zCeladonGlow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BETA',
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
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.xs),
            child: IconButton(
              icon: Icon(Icons.groups_outlined, color: context.zTextSecondary, size: 24),
              tooltip: l10n.groupChatTitle,
              onPressed: _openGroupChats,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.zAccent,
              indicatorWeight: 1.5,
              labelColor: context.zTextPrimary,
              unselectedLabelColor: context.zTextTertiary,
              labelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: l10n.spaceDiscover),
                Tab(text: l10n.spaceMySpaces),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSpaceModal,
        backgroundColor: context.zAccent,
        elevation: 0,
        child: Icon(Icons.add_rounded, color: context.zBg, size: 24),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildMySpacesTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom + 80,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ZeroSpacing.md,
        crossAxisSpacing: ZeroSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: _discoverSpaces.length,
      itemBuilder: (context, index) {
        final space = _discoverSpaces[index];
        return _DiscoverSpaceCard(
          space: space,
          onJoin: () => _showJoinDialog(space),
        );
      },
    );
  }

  Widget _buildMySpacesTab() {
    final l10n = AppLocalizations.of(context);

    if (_mySpaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: context.zTextDisabled,
            ),
            SizedBox(height: ZeroSpacing.md),
            Text(
              l10n.spaceNoSpaces,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              l10n.spaceDiscoverHint,
              style: ZeroTypography.caption(context),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom + 80,
      ),
      itemCount: _mySpaces.length,
      itemBuilder: (context, index) {
        final space = _mySpaces[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: _MySpaceCard(
            space: space,
            onTap: () => _openSpace(space),
          ),
        );
      },
    );
  }
}

class _DiscoveredSpace {
  final String name;
  final int memberCount;
  final String description;
  final String lastActive;
  final int gradientIndex;

  const _DiscoveredSpace({
    required this.name,
    required this.memberCount,
    required this.description,
    required this.lastActive,
    required this.gradientIndex,
  });
}

class _MySpace {
  final String name;
  final int memberCount;
  final String lastActivity;
  final bool hasUnread;
  final int gradientIndex;

  _MySpace({
    required this.name,
    required this.memberCount,
    required this.lastActivity,
    required this.hasUnread,
    required this.gradientIndex,
  });
}

class _DiscoverSpaceCard extends StatelessWidget {
  final _DiscoveredSpace space;
  final VoidCallback onJoin;

  const _DiscoverSpaceCard({
    required this.space,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradients = _SpaceScreenState._coverGradients;
    final coverGradient = LinearGradient(
      colors: gradients[space.gradientIndex % gradients.length],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ZeroCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: coverGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(ZeroSpacing.cardRadius - 1),
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: ZeroSpacing.avatarLg,
              height: ZeroSpacing.avatarLg,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.4),
                    context.zCeladon.withOpacity(0.4),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                space.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.zAccent,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(ZeroSpacing.md, ZeroSpacing.sm, ZeroSpacing.md, 0),
            child: Text(
              space.name,
              style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 13, color: context.zTextTertiary),
                SizedBox(width: 4),
                Text(
                  '${space.memberCount}',
                  style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                ),
                Spacer(),
                Text(
                  space.lastActive,
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 10,
                    color: context.zTextDisabled,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(ZeroSpacing.md, ZeroSpacing.xs, ZeroSpacing.md, 0),
            child: Text(
              space.description,
              style: ZeroTypography.caption(context).copyWith(
                color: context.zTextSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(ZeroSpacing.md, 0, ZeroSpacing.md, ZeroSpacing.md),
            child: SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.zAccent,
                  side: BorderSide(color: context.zAccentMuted, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  l10n.spaceJoin,
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

class _MySpaceCard extends StatelessWidget {
  final _MySpace space;
  final VoidCallback onTap;

  const _MySpaceCard({
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradients = _SpaceScreenState._coverGradients;

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: ZeroSpacing.avatarLg,
                height: ZeroSpacing.avatarLg,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      context.zAccent.withOpacity(0.25),
                      context.zCeladon.withOpacity(0.25),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  space.name[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: context.zAccent,
                  ),
                ),
              ),
              if (space.hasUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.zCeladon,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.name,
                  style: ZeroTypography.title(context).copyWith(fontSize: 16),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 13, color: context.zTextTertiary),
                    SizedBox(width: 4),
                    Text(
                      '${space.memberCount} ${l10n.spaceMembers}',
                      style: ZeroTypography.caption(context),
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
                    Text(
                      space.lastActivity,
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextDisabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.zTextDisabled, size: 22),
        ],
      ),
    );
  }
}

class _SpaceDetailScreen extends StatelessWidget {
  final _MySpace space;

  const _SpaceDetailScreen({required this.space});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          space.name,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.groups_outlined, color: context.zTextSecondary, size: 24),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(fullscreenDialog: true, builder: (_) => const GroupChatListScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ZeroSpacing.avatarXl,
              height: ZeroSpacing.avatarXl,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.3),
                    context.zCeladon.withOpacity(0.3),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                space.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  color: context.zAccent,
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              space.name,
              style: ZeroTypography.headline(context),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              '${space.memberCount} ${l10n.spaceMembers}',
              style: ZeroTypography.body(context),
            ),
            const SizedBox(height: ZeroSpacing.xxl),
            _Post(
              author: 'VoidWalker',
              content: isZh
                  ? '欢迎来到 ${space.name}！这是我们的第一帖，让我们开始交流吧。'
                  : 'Welcome to ${space.name}! This is our first post, let\'s start chatting.',
              time: isZh ? '刚刚' : 'just now',
              likes: 0,
            ).build(context),
          ],
        ),
      ),
    );
  }
}

class _Post {
  final String author;
  final String content;
  final String time;
  final int likes;

  const _Post({
    required this.author,
    required this.content,
    required this.time,
    required this.likes,
  });

  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
      child: ZeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: ZeroSpacing.avatarSm,
                  height: ZeroSpacing.avatarSm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.zAccent.withOpacity(0.3),
                        context.zCeladon.withOpacity(0.3),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    author[0].toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.zAccent,
                    ),
                  ),
                ),
                SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.sm),
            Text(
              content,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary.withOpacity(0.85),
              ),
            ),
            SizedBox(height: ZeroSpacing.md),
            Divider(height: 0.5),
            Padding(
              padding: EdgeInsets.only(top: ZeroSpacing.md - 4),
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 18, color: context.zTextTertiary),
                  SizedBox(width: 4),
                  Text(
                    '$likes',
                    style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                  ),
                  SizedBox(width: ZeroSpacing.lg),
                  Icon(Icons.comment_outlined, size: 18, color: context.zTextTertiary),
                  SizedBox(width: 4),
                  Text(
                    isZh ? '回复' : 'Reply',
                    style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                  ),
                  Spacer(),
                  Icon(Icons.share_outlined, size: 18, color: context.zTextTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}