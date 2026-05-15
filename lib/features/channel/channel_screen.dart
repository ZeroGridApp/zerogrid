import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../services/channel/channel_service.dart';
import '../../widgets/zero_card.dart';

const _currentUserId = 'current_user';

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final _service = ChannelService();
  final _searchController = TextEditingController();
  bool _showMySubscriptions = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ZeroChannel> _filteredChannels() {
    var channels = _showMySubscriptions
        ? _service.getMySubscriptions(_currentUserId)
        : _service.getChannels(search: _searchQuery);
    return channels;
  }

  void _openChannel(ZeroChannel channel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChannelDetailScreen(channel: channel),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleSubscription(ZeroChannel channel) {
    setState(() {
      if (_service.isSubscribed(channel.id, _currentUserId)) {
        _service.unsubscribe(channel.id, _currentUserId);
      } else {
        _service.subscribe(channel.id, _currentUserId);
      }
    });
  }

  void _showCreateChannelModal() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedEmoji = '📢';
    bool isPublic = true;

    const emojiGrid = [
      '📢', '🔐', '💻', '🌐', '🎨', '📊', '🚀', '💡',
      '🎯', '🔥', '⭐', '💎', '🎮', '📚', '🎵', '🏆',
      '🧠', '⚡', '🌱', '🤖',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final nameValid = nameController.text.trim().isNotEmpty;
            final descValid = descController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.zSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(ZeroSpacing.lg),
                child: SingleChildScrollView(
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
                      const SizedBox(height: ZeroSpacing.lg),
                      Text(
                        isZh ? '创建频道' : 'Create Channel',
                        style: ZeroTypography.headline(context),
                      ),
                      const SizedBox(height: ZeroSpacing.xs),
                      Text(
                        isZh ? '创建一个新的广播频道' : 'Create a new broadcast channel',
                        style: ZeroTypography.body(context),
                      ),
                      const SizedBox(height: ZeroSpacing.lg),
                      Text(
                        isZh ? '频道图标' : 'Channel Icon',
                        style: ZeroTypography.bodyBold(context),
                      ),
                      const SizedBox(height: ZeroSpacing.sm),
                      Wrap(
                        spacing: ZeroSpacing.sm,
                        runSpacing: ZeroSpacing.sm,
                        children: emojiGrid.map((emoji) {
                          final isSelected = selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedEmoji = emoji),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? context.zAccent.withOpacity(0.15)
                                    : context.zSurfaceRaised,
                                border: Border.all(
                                  color: isSelected
                                      ? context.zAccent
                                      : context.zFrostWhiteStrong,
                                  width: isSelected ? 1.5 : 0.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: ZeroSpacing.lg),
                      Text(
                        isZh ? '频道名称' : 'Channel Name',
                        style: ZeroTypography.bodyBold(context),
                      ),
                      const SizedBox(height: ZeroSpacing.sm),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setModalState(() {}),
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '输入频道名称' : 'Enter channel name',
                          hintStyle: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          filled: true,
                          fillColor: context.zSurfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(ZeroSpacing.md),
                        ),
                      ),
                      const SizedBox(height: ZeroSpacing.md),
                      Text(
                        isZh ? '频道描述' : 'Description',
                        style: ZeroTypography.bodyBold(context),
                      ),
                      const SizedBox(height: ZeroSpacing.sm),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        onChanged: (_) => setModalState(() {}),
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '描述你的频道' : 'Describe your channel',
                          hintStyle: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          filled: true,
                          fillColor: context.zSurfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(ZeroSpacing.md),
                        ),
                      ),
                      const SizedBox(height: ZeroSpacing.md),
                      Text(
                        isZh ? '标签 (逗号分隔)' : 'Tags (comma-separated)',
                        style: ZeroTypography.bodyBold(context),
                      ),
                      const SizedBox(height: ZeroSpacing.sm),
                      TextField(
                        controller: tagsController,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '如: 技术, Web3, 教程' : 'e.g. tech, web3, tutorial',
                          hintStyle: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          filled: true,
                          fillColor: context.zSurfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(ZeroSpacing.md),
                        ),
                      ),
                      const SizedBox(height: ZeroSpacing.md),
                      Row(
                        children: [
                          Text(
                            isZh ? '公开频道' : 'Public Channel',
                            style: ZeroTypography.bodyBold(context),
                          ),
                          const Spacer(),
                          Switch(
                            value: isPublic,
                            onChanged: (v) => setModalState(() => isPublic = v),
                            activeColor: context.zAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: ZeroSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (nameValid && descValid)
                              ? () {
                                  final tags = tagsController.text
                                      .split(',')
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();
                                  _service.createChannel(
                                    name: nameController.text.trim(),
                                    description: descController.text.trim(),
                                    icon: selectedEmoji,
                                    ownerId: _currentUserId,
                                    ownerName: 'You',
                                    isPublic: isPublic,
                                    tags: tags,
                                  );
                                  Navigator.of(ctx).pop();
                                  setState(() {});
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (nameValid && descValid)
                                ? context.zAccent
                                : context.zSurfaceRaised,
                            foregroundColor: context.zBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                            ),
                          ),
                          child: Text(
                            isZh ? '创建频道' : 'Create Channel',
                            style: ZeroTypography.bodyBold(context).copyWith(
                              color: (nameValid && descValid)
                                  ? context.zBg
                                  : context.zTextDisabled,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ZeroSpacing.sm),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final channels = _filteredChannels();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isZh ? '频道' : 'Channels',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: context.zTextSecondary, size: 22),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ChannelSearchDelegate(
                  service: _service,
                  currentUserId: _currentUserId,
                  isZh: isZh,
                  onToggleSubscription: (channel) {
                    _toggleSubscription(channel);
                  },
                  onOpenChannel: _openChannel,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChannelModal,
        backgroundColor: context.zAccent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZeroSpacing.screenHorizontal,
              vertical: ZeroSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: isZh ? '全部频道' : 'All Channels',
                  isActive: !_showMySubscriptions,
                  onTap: () => setState(() => _showMySubscriptions = false),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                _FilterChip(
                  label: isZh ? '我的订阅' : 'My Subscriptions',
                  isActive: _showMySubscriptions,
                  onTap: () => setState(() => _showMySubscriptions = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: channels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_off_outlined,
                            size: 64, color: context.zTextDisabled),
                        const SizedBox(height: ZeroSpacing.md),
                        Text(
                          isZh ? '暂无频道' : 'No channels',
                          style: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                        ),
                        const SizedBox(height: ZeroSpacing.xs),
                        Text(
                          _showMySubscriptions
                              ? (isZh ? '你还没有订阅任何频道' : 'You haven\'t subscribed to any channels')
                              : (isZh ? '还没有任何频道' : 'No channels yet'),
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      ZeroSpacing.screenHorizontal,
                      ZeroSpacing.xs,
                      ZeroSpacing.screenHorizontal,
                      ZeroSpacing.screenBottom + 80,
                    ),
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final isSub = _service.isSubscribed(
                          channel.id, _currentUserId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
                        child: _ChannelCard(
                          channel: channel,
                          isSubscribed: isSub,
                          onTap: () => _openChannel(channel),
                          onToggleSubscription: () =>
                              _toggleSubscription(channel),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChannelSearchDelegate extends SearchDelegate<String> {
  final ChannelService service;
  final String currentUserId;
  final void Function(ZeroChannel) onToggleSubscription;
  final void Function(ZeroChannel) onOpenChannel;
  final bool isZh;

  _ChannelSearchDelegate({
    required this.service,
    required this.currentUserId,
    required this.onToggleSubscription,
    required this.onOpenChannel,
    required this.isZh,
  });

  @override
  String get searchFieldLabel => isZh ? '搜索频道...' : 'Search channels...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: context.zBg,
        iconTheme: IconThemeData(color: context.zTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: ZeroTypography.body(context).copyWith(
          color: context.zTextTertiary,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchList(context);
  }

  Widget _buildSearchList(BuildContext context) {
    final channels = service.getChannels(search: query);
    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: context.zTextDisabled),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '未找到频道' : 'No channels found',
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
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
        ZeroSpacing.screenBottom,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSub = service.isSubscribed(channel.id, currentUserId);
        return Padding(
          padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: _ChannelCard(
            channel: channel,
            isSubscribed: isSub,
            onTap: () {
              close(context, '');
              onOpenChannel(channel);
            },
            onToggleSubscription: () => onToggleSubscription(channel),
          ),
        );
      },
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ZeroChannel channel;
  final bool isSubscribed;
  final VoidCallback onTap;
  final VoidCallback onToggleSubscription;

  const _ChannelCard({
    required this.channel,
    required this.isSubscribed,
    required this.onTap,
    required this.onToggleSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ZeroSpacing.avatarMd,
                height: ZeroSpacing.avatarMd,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zSurfaceRaised,
                  border: Border.all(
                    color: context.zFrostWhiteStrong,
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(channel.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: ZeroSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: ZeroTypography.bodyBold(context).copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isZh
                          ? '${_formatCount(channel.subscriberCount)} 订阅者 · ${channel.postCount} 帖子'
                          : '${_formatCount(channel.subscriberCount)} subscribers · ${channel.postCount} posts',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleSubscription,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    border: Border.all(
                      color: isSubscribed
                          ? context.zAccent.withOpacity(0.4)
                          : context.zAccentMuted.withOpacity(0.4),
                      width: 0.5,
                    ),
                    color: isSubscribed
                        ? context.zAccent.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Text(
                    isSubscribed ? (isZh ? '已订阅' : 'Subscribed') : (isZh ? '+ 订阅' : '+ Subscribe'),
                    style: ZeroTypography.caption(context).copyWith(
                      color: isSubscribed ? context.zAccent : context.zAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (channel.tags.isNotEmpty) ...[
            const SizedBox(height: ZeroSpacing.sm),
            Wrap(
              spacing: ZeroSpacing.xs,
              runSpacing: ZeroSpacing.xs,
              children: channel.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.zAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  child: Text(
                    tag,
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 11,
                      color: context.zAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (channel.description.isNotEmpty) ...[
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              channel.description,
              style: ZeroTypography.body(context).copyWith(
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? context.zAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: isActive ? context.zAccent.withOpacity(0.3) : context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            color: isActive ? context.zAccent : context.zTextSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ChannelDetailScreen extends StatefulWidget {
  final ZeroChannel channel;

  const _ChannelDetailScreen({required this.channel});

  @override
  State<_ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<_ChannelDetailScreen> {
  final _service = ChannelService();
  final _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _likePost(String postId) {
    setState(() {
      _service.likePost(postId);
    });
  }

  void _pinPost(String postId) {
    setState(() {
      _service.pinPost(postId);
    });
  }

  void _sendPost() {
    final content = _postController.text.trim();
    if (content.isEmpty) return;
    setState(() {
      _service.createPost(
        channelId: widget.channel.id,
        channelName: widget.channel.name,
        authorId: _currentUserId,
        authorName: 'You',
        content: content,
      );
    });
    _postController.clear();
  }

  Future<void> _onRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final channel = widget.channel;
    final posts = _service.getPosts(channel.id);
    final isSub = _service.isSubscribed(channel.id, _currentUserId);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.zAccent,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              backgroundColor: context.zBg,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.zTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isSub ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    color: isSub ? context.zAccent : context.zTextSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isSub) {
                        _service.unsubscribe(channel.id, _currentUserId);
                      } else {
                        _service.subscribe(channel.id, _currentUserId);
                      }
                    });
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          channel.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: ZeroSpacing.sm),
                        Expanded(
                          child: Text(
                            channel.name,
                            style: ZeroTypography.title(context).copyWith(
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isZh
                          ? '${_formatCount(channel.subscriberCount)} 订阅者'
                          : '${_formatCount(channel.subscriberCount)} subscribers',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(
                  left: ZeroSpacing.lg + 28,
                  bottom: ZeroSpacing.md,
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.zAccent.withOpacity(0.08),
                        context.zBg,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: context.zDivider.withOpacity(0.3),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZeroSpacing.screenHorizontal,
                  ZeroSpacing.md,
                  ZeroSpacing.screenHorizontal,
                  ZeroSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.description,
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextPrimary.withOpacity(0.8),
                      ),
                    ),
                    if (channel.tags.isNotEmpty) ...[
                      const SizedBox(height: ZeroSpacing.sm),
                      Wrap(
                        spacing: ZeroSpacing.xs,
                        runSpacing: ZeroSpacing.xs,
                        children: channel.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.zAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                            ),
                            child: Text(
                              tag,
                              style: ZeroTypography.caption(context).copyWith(
                                fontSize: 11,
                                color: context.zAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                ),
                child: Row(
                  children: [
                    Text(
                      isZh ? '帖子' : 'Posts',
                      style: ZeroTypography.bodyBold(context).copyWith(
                        fontSize: 14,
                        color: context.zTextSecondary,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.xs),
                    Text(
                      '${posts.length}',
                      style: ZeroTypography.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: ZeroSpacing.xxl),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48, color: context.zTextDisabled),
                        const SizedBox(height: ZeroSpacing.md),
                        Text(
                          isZh ? '暂无帖子' : 'No posts yet',
                          style: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ZeroSpacing.screenHorizontal,
                        ZeroSpacing.sm,
                        ZeroSpacing.screenHorizontal,
                        0,
                      ),
                      child: _PostCard(
                        post: post,
                        onLike: () => _likePost(post.id),
                        onPin: () => _pinPost(post.id),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: ZeroSpacing.lg + 64),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: context.zBg,
          border: Border(
            top: BorderSide(
              color: context.zDivider.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.sm,
          ZeroSpacing.screenHorizontal,
          MediaQuery.of(context).padding.bottom + ZeroSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _postController,
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: isZh ? '发布帖子...' : 'Write a post...',
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
                    vertical: ZeroSpacing.sm + 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ZeroSpacing.sm),
            GestureDetector(
              onTap: _sendPost,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [context.zAccent, context.zCeladon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ChannelPost post;
  final VoidCallback onLike;
  final VoidCallback onPin;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned)
            Container(
              margin: const EdgeInsets.only(bottom: ZeroSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.zAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded,
                      size: 12, color: context.zAccent),
                  const SizedBox(width: 4),
                  Text(
                    isZh ? '已置顶' : 'Pinned',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 10,
                      color: context.zAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                width: ZeroSpacing.avatarSm,
                height: ZeroSpacing.avatarSm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zAccent.withOpacity(0.1),
                ),
                alignment: Alignment.center,
                child: Text(
                  post.authorName[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.zAccent,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Text(
                  '${post.authorName} · ${post.channelName}',
                  style: ZeroTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onPin,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    post.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 16,
                    color: post.isPinned
                        ? context.zAccent
                        : context.zTextTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            post.content,
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextPrimary.withOpacity(0.88),
              height: 1.6,
            ),
          ),
          if (post.attachmentUrl != null && post.attachmentUrl!.isNotEmpty) ...[
            const SizedBox(height: ZeroSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                border: Border.all(
                  color: context.zFrostWhiteStrong,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          context.zAccent.withOpacity(0.2),
                          context.zAccent.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _attachmentIcon(post.type),
                  ),
                  const SizedBox(width: ZeroSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.attachmentUrl!,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: context.zTextTertiary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: ZeroSpacing.sm + 4),
          Row(
            children: [
              _PostAction(
                icon: Icons.favorite_outline_rounded,
                label: '${post.likes}',
                onTap: onLike,
              ),
              const SizedBox(width: ZeroSpacing.lg),
              _PostAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments}',
                onTap: () {},
              ),
              const SizedBox(width: ZeroSpacing.lg),
              _PostAction(
                icon: Icons.repeat_rounded,
                label: '${post.reposts}',
                onTap: () {},
              ),
              const Spacer(),
              Text(
                _relativeTime(post.createdAt, isZh),
                style: ZeroTypography.caption(context).copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attachmentIcon(String type) {
    switch (type) {
      case 'image':
        return const Icon(Icons.image_outlined, size: 20, color: Colors.white70);
      case 'video':
        return const Icon(Icons.videocam_outlined, size: 20, color: Colors.white70);
      case 'file':
        return const Icon(Icons.insert_drive_file_outlined, size: 20, color: Colors.white70);
      case 'link':
        return const Icon(Icons.link_rounded, size: 20, color: Colors.white70);
      case 'poll':
        return const Icon(Icons.poll_outlined, size: 20, color: Colors.white70);
      default:
        return const Icon(Icons.text_fields_rounded, size: 20, color: Colors.white70);
    }
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: context.zTextTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(
                fontSize: 11,
                color: context.zTextTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 10000) {
    return '${(count / 1000).toStringAsFixed(1)}k';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}k';
  }
  return count.toString();
}

String _relativeTime(DateTime time, bool isZh) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
  if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
  if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
  return isZh ? '${diff.inDays ~/ 7}周前' : '${diff.inDays ~/ 7}w ago';
}