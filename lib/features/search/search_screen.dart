import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/chat/group_chat_service.dart';
import '../../services/wallet/transaction_history_service.dart';
import '../../widgets/zero_card.dart';
import '../chat/chat_screen.dart';
import '../chat/group_chat_screen.dart';

enum _SearchTab { all, contacts, groups, transactions }

class _SearchContact {
  final String name;
  final String zeroId;

  const _SearchContact({required this.name, required this.zeroId});
}

class _DemoGroup {
  final String id;
  final String name;
  final String topic;
  final int memberCount;
  final String initials;
  final int avatarColorIndex;
  final String lastMessageTime;

  const _DemoGroup({
    required this.id,
    required this.name,
    required this.topic,
    required this.memberCount,
    required this.initials,
    required this.avatarColorIndex,
    required this.lastMessageTime,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  _SearchTab _currentTab = _SearchTab.all;
  String _query = '';
  Timer? _debounce;
  late final TabController _tabController;

  final List<_SearchContact> _contacts = const [
    _SearchContact(name: '0xCat', zeroId: '0xCat.zero'),
    _SearchContact(name: 'VoidWalker', zeroId: 'VoidWalker.zero'),
    _SearchContact(name: 'Ming', zeroId: 'Ming.zero'),
    _SearchContact(name: 'SolSurfer', zeroId: 'SolSurfer.zero'),
    _SearchContact(name: 'EthAnon', zeroId: 'EthAnon.zero'),
    _SearchContact(name: 'Alice', zeroId: 'Alice.zero'),
    _SearchContact(name: 'Bob', zeroId: 'Bob.zero'),
    _SearchContact(name: 'Charlie', zeroId: 'Charlie.zero'),
    _SearchContact(name: '王伟', zeroId: 'WangWei.zero'),
    _SearchContact(name: '张明', zeroId: 'ZhangMing.zero'),
    _SearchContact(name: '李华', zeroId: 'LiHua.zero'),
  ];

  final List<_DemoGroup> _groups = const [
    _DemoGroup(
      id: 'group_001',
      name: 'CipherSquad',
      topic: 'Cryptography & Privacy Tech',
      memberCount: 128,
      initials: 'CS',
      avatarColorIndex: 0,
      lastMessageTime: '14:32',
    ),
    _DemoGroup(
      id: 'group_002',
      name: 'Zero Builders',
      topic: 'Zero Ecosystem Development',
      memberCount: 47,
      initials: 'ZB',
      avatarColorIndex: 1,
      lastMessageTime: '11:15',
    ),
    _DemoGroup(
      id: 'group_003',
      name: 'Web3 中文圈',
      topic: '区块链技术与去中心化讨论',
      memberCount: 356,
      initials: 'W3',
      avatarColorIndex: 2,
      lastMessageTime: '09:48',
    ),
    _DemoGroup(
      id: 'group_004',
      name: 'DeFi Lounge',
      topic: 'Decentralized Finance Alpha',
      memberCount: 89,
      initials: 'DL',
      avatarColorIndex: 3,
      lastMessageTime: '昨天',
    ),
    _DemoGroup(
      id: 'group_005',
      name: 'Node Operators',
      topic: 'Infrastructure & Node Management',
      memberCount: 34,
      initials: 'NO',
      avatarColorIndex: 4,
      lastMessageTime: '昨天',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _SearchTab.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
    });
  }

  List<_SearchContact> _filteredContacts() {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _contacts.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.zeroId.toLowerCase().contains(q);
    }).toList();
  }

  List<_DemoGroup> _filteredGroups() {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _groups.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.topic.toLowerCase().contains(q);
    }).toList();
  }

  List<TransactionRecord> _filteredTransactions() {
    if (_query.isEmpty) return [];
    return ZeroTransactionHistoryService().searchTransactions(_query);
  }

  bool get _hasResults {
    if (_currentTab == _SearchTab.all) {
      return _filteredContacts().isNotEmpty ||
          _filteredGroups().isNotEmpty ||
          _filteredTransactions().isNotEmpty;
    }
    if (_currentTab == _SearchTab.contacts) return _filteredContacts().isNotEmpty;
    if (_currentTab == _SearchTab.groups) return _filteredGroups().isNotEmpty;
    if (_currentTab == _SearchTab.transactions) return _filteredTransactions().isNotEmpty;
    return false;
  }

  bool get _isEmptyQuery => _query.isEmpty;

  List<Color> _groupAvatarColors(int index) {
    final palettes = [
      [context.zAccent, context.zCeladon],
      [context.zCeladon, context.zSuccess],
      [context.zAccent, context.zWarning],
      [context.zCeladon, const Color(0xFF6BAF7B)],
      [const Color(0xFFC2A050), context.zAccent],
    ];
    final p = palettes[index % palettes.length];
    return [p[0], p[1]];
  }

  Color _contactAvatarColor(String name) {
    final colors = [
      context.zAccent,
      context.zCeladon,
      context.zSuccess,
      context.zWarning,
      const Color(0xFF7B6BAA),
      const Color(0xFFC26B8A),
      const Color(0xFF6B9AC2),
      const Color(0xFFC28A6B),
    ];
    final hash = name.codeUnits.fold<int>(0, (prev, e) => prev + e);
    return colors[hash % colors.length].withOpacity(0.3);
  }

  Color _contactAccentColor(String name) {
    final colors = [
      context.zAccent,
      context.zCeladon,
      context.zSuccess,
      context.zWarning,
      const Color(0xFF7B6BAA),
      const Color(0xFFC26B8A),
      const Color(0xFF6B9AC2),
      const Color(0xFFC28A6B),
    ];
    final hash = name.codeUnits.fold<int>(0, (prev, e) => prev + e);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: context.zSurface,
            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
            border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            style: ZeroTypography.body(context).copyWith(
              fontSize: 14,
              color: context.zTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: isZh ? '搜索联系人、群组、交易...' : 'Search contacts, groups, transactions...',
              hintStyle: ZeroTypography.caption(context).copyWith(
                color: context.zTextTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: context.zTextTertiary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: context.zTextTertiary,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: BoxDecoration(
              color: context.zBg,
              border: Border(
                bottom: BorderSide(
                  color: context.zDivider,
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal - 8),
              labelColor: context.zAccent,
              unselectedLabelColor: context.zTextTertiary,
              indicatorColor: context.zAccent,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: ZeroTypography.body(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: ZeroTypography.body(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: isZh ? '全部' : 'All'),
                Tab(text: isZh ? '联系人' : 'Contacts'),
                Tab(text: isZh ? '群组' : 'Groups'),
                Tab(text: isZh ? '交易' : 'Transactions'),
              ],
            ),
          ),
        ),
      ),
      body: _isEmptyQuery ? _buildEmptyState(context, isZh) : _buildResults(isZh),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isZh) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zFrostWhite,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 36,
              color: context.zTextTertiary.withOpacity(0.4),
            ),
          ),
          SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '搜索全部' : 'Search all',
            style: ZeroTypography.headline(context).copyWith(
              color: context.zTextPrimary,
            ),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '输入关键词开始搜索' : 'Start typing to search',
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isZh) {
    if (!_hasResults) {
      return _buildNoResults(context, isZh);
    }

    final contacts = _currentTab == _SearchTab.all || _currentTab == _SearchTab.contacts
        ? _filteredContacts()
        : <_SearchContact>[];
    final groups = _currentTab == _SearchTab.all || _currentTab == _SearchTab.groups
        ? _filteredGroups()
        : <_DemoGroup>[];
    final transactions = _currentTab == _SearchTab.all || _currentTab == _SearchTab.transactions
        ? _filteredTransactions()
        : <TransactionRecord>[];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
      ),
      children: [
        if (contacts.isNotEmpty) ...[
          _buildSectionHeader(context, isZh, isZh ? '联系人' : 'Contacts', contacts.length),
          ...contacts.map((c) => _buildContactCard(context, isZh, c)),
        ],
        if (groups.isNotEmpty) ...[
          _buildSectionHeader(context, isZh, isZh ? '群组' : 'Groups', groups.length),
          ...groups.map((g) => _buildGroupCard(context, isZh, g)),
        ],
        if (transactions.isNotEmpty) ...[
          _buildSectionHeader(context, isZh, isZh ? '交易' : 'Transactions', transactions.length),
          ...transactions.map((t) => _buildTransactionCard(context, isZh, t)),
        ],
        SizedBox(height: ZeroSpacing.lg),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isZh, String title, int count) {
    return Padding(
      padding: EdgeInsets.only(top: ZeroSpacing.md, bottom: ZeroSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: ZeroTypography.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: context.zTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: ZeroSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: context.zAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: ZeroTypography.caption(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.zAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, bool isZh, _SearchContact contact) {
    final avatarColor = _contactAvatarColor(contact.name);
    final accentColor = _contactAccentColor(contact.name);

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(peerName: contact.name),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: ZeroSpacing.avatarMd,
              height: ZeroSpacing.avatarMd,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              alignment: Alignment.center,
              child: Text(
                contact.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: ZeroTypography.title(context).copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    contact.zeroId,
                    style: ZeroTypography.monoSmall(context),
                  ),
                ],
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.zAccent, context.zCeladon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
              ),
              child: Text(
                isZh ? '打开聊天' : 'Open Chat',
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zBg,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, bool isZh, _DemoGroup group) {
    final avatarColors = _groupAvatarColors(group.avatarColorIndex);

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(
                groupName: group.name,
                memberCount: group.memberCount,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: ZeroSpacing.avatarMd,
              height: ZeroSpacing.avatarMd,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [avatarColors[0], avatarColors[1]],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                group.initials,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.zBg,
                ),
              ),
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
                          style: ZeroTypography.title(context).copyWith(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        group.lastMessageTime,
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    group.topic,
                    style: ZeroTypography.caption(context).copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: context.zTextTertiary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${group.memberCount} ${isZh ? '成员' : 'members'}',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                          color: context.zTextTertiary,
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
    );
  }

  Widget _buildTransactionCard(BuildContext context, bool isZh, TransactionRecord tx) {
    final isSent = tx.type == 'sent';
    final isPending = tx.status == 'pending';
    final isFailed = tx.status == 'failed';

    Color statusColor() {
      if (isFailed) return context.zError;
      if (isPending) return context.zWarning;
      return context.zSuccess;
    }

    String statusLabel() {
      if (isFailed) return isZh ? '失败' : 'Failed';
      if (isPending) return isZh ? '待确认' : 'Pending';
      return isZh ? '已确认' : 'Confirmed';
    }

    String timeAgo() {
      final diff = DateTime.now().difference(tx.timestamp);
      if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
      if (diff.inDays < 30) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
      return isZh
          ? '${tx.timestamp.month}/${tx.timestamp.day}'
          : '${tx.timestamp.month}/${tx.timestamp.day}';
    }

    final address = ZeroTransactionHistoryService().formatAddress(
      isSent ? tx.toAddress : tx.fromAddress,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isZh ? '查看交易详情: ${tx.txHash}' : 'View transaction details: ${tx.txHash}',
              ),
              backgroundColor: context.zSurface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSent
                    ? context.zError.withOpacity(0.08)
                    : context.zSuccess.withOpacity(0.08),
              ),
              alignment: Alignment.center,
              child: Icon(
                isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 18,
                color: isSent ? context.zError : context.zSuccess,
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isSent ? '-' : '+',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSent ? context.zError : context.zSuccess,
                        ),
                      ),
                      Text(
                        '${tx.amount.toStringAsFixed(tx.amount == tx.amount.truncateToDouble() ? 0 : 4)} ${tx.token}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.zTextPrimary,
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.xs),
                      Text(
                        '\$${tx.usdValue.toStringAsFixed(2)}',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                          color: context.zTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 10,
                        color: context.zTextTertiary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        address,
                        style: ZeroTypography.monoSmall(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Text(
                        timeAgo(),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor().withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: statusColor().withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                statusLabel(),
                style: ZeroTypography.caption(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, bool isZh) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zFrostWhite,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: context.zTextTertiary.withOpacity(0.4),
            ),
          ),
          SizedBox(height: ZeroSpacing.lg),
          Text(
            '${isZh ? '未找到' : 'No results for'} "$_query"',
            style: ZeroTypography.headline(context).copyWith(
              color: context.zTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '试试其他关键词' : 'Try a different keyword',
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}