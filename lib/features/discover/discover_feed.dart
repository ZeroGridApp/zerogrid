import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../services/feed/zero_feed_service.dart';
import '../../widgets/zero_card.dart';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ZeroFeedService _feedService = ZeroFeedService();

  late List<ZeroFeedPost> _followingPosts;
  late List<ZeroFeedPost> _trendingPosts;
  late List<ZeroFeedPost> _latestPosts;

  final Set<String> _expandedCommentPostIds = {};

  static const _avatarColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFFDCB6E),
    Color(0xFFE84393),
    Color(0xFF00CEC9),
    Color(0xFFD63031),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
    Color(0xFF74B9FF),
    Color(0xFFFF7675),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAllFeeds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAllFeeds() {
    _followingPosts = _feedService.getFollowingPosts('you');
    _trendingPosts = _feedService.getTrendingPosts();
    _latestPosts = _feedService.getLatestPosts();
  }

  Color _avatarColorFor(String id) {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return _avatarColors[hash % _avatarColors.length];
  }

  String _timeAgo(DateTime timestamp, bool isZh) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    return isZh
        ? '${timestamp.month}月${timestamp.day}日'
        : '${timestamp.month}/${timestamp.day}';
  }

  void _toggleLike(ZeroFeedPost post) {
    setState(() {
      _feedService.toggleLike(post.id);
    });
  }

  void _toggleBookmark(String postId) {
    setState(() {
      _feedService.toggleBookmark(postId);
    });
  }

  void _toggleComments(String postId) {
    setState(() {
      if (_expandedCommentPostIds.contains(postId)) {
        _expandedCommentPostIds.remove(postId);
      } else {
        _expandedCommentPostIds.add(postId);
      }
    });
  }

  void _addComment(String postId, String content) {
    if (content.trim().isEmpty) return;
    setState(() {
      _feedService.addComment(postId, content.trim());
    });
  }

  void _repost(ZeroFeedPost post) {
    setState(() {
      _feedService.repost(post.id, 'Z8P2K5W1RT');
      _refreshAllFeeds();
    });
  }

  void _copyCid(String cid) {
    Clipboard.setData(ClipboardData(text: cid));
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh ? 'CID 已复制' : 'CID copied',
          style: TextStyle(color: context.zTextPrimary),
        ),
        backgroundColor: context.zSurfaceRaised,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _refreshAllFeeds();
    });
  }

  void _showComposeModal() {
    final controller = TextEditingController();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final remaining = 280 - controller.text.length;
            final isValid = controller.text.trim().isNotEmpty && remaining >= 0;

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
                      isZh ? '发布到零界信息流' : 'Post to ZeroFeed',
                      style: ZeroTypography.headline(context),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh ? '分享你的想法给去中心化世界' : 'Share your thoughts with the decentralized world',
                      style: ZeroTypography.body(context),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      maxLength: 280,
                      autofocus: true,
                      onChanged: (_) => setModalState(() {}),
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextPrimary,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: isZh ? '你在想什么？' : "What's on your mind?",
                        hintStyle: ZeroTypography.body(context).copyWith(
                          color: context.zTextTertiary,
                        ),
                        filled: true,
                        fillColor: context.zSurfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(ZeroSpacing.md),
                        counterStyle: ZeroTypography.monoSmall(context).copyWith(
                          color: remaining < 20 ? context.zError : context.zTextTertiary,
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () {
                                _feedService.createPost(
                                  controller.text.trim(),
                                  'Z8P2K5W1RT',
                                );
                                Navigator.of(ctx).pop();
                                setState(() {
                                  _refreshAllFeeds();
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isValid ? context.zAccent : context.zSurfaceRaised,
                          foregroundColor: context.zBg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                        ),
                        child: Text(
                          isZh ? '发布到 ZeroFeed' : 'Post to ZeroFeed',
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: isValid ? context.zBg : context.zTextDisabled,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                  ],
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              isZh ? '零界信息流' : 'ZeroFeed',
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
                'LIVE',
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
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: context.zTextSecondary, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.xs),
            child: IconButton(
              icon: Icon(Icons.edit_note_rounded,
                  color: context.zAccent, size: 22),
              tooltip: isZh ? '发布' : 'Compose',
              onPressed: _showComposeModal,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
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
                Tab(text: isZh ? '关注' : 'Following'),
                Tab(text: isZh ? '热门' : 'Trending'),
                Tab(text: isZh ? '最新' : 'Latest'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showComposeModal,
        backgroundColor: context.zAccent,
        elevation: 0,
        child: Icon(Icons.add_rounded, color: context.zBg, size: 24),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(_followingPosts),
          _buildFeedTab(_trendingPosts),
          _buildFeedTab(_latestPosts),
        ],
      ),
    );
  }

  Widget _buildFeedTab(List<ZeroFeedPost> posts) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.zAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rss_feed_outlined,
                      size: 64, color: context.zTextDisabled),
                  SizedBox(height: ZeroSpacing.md),
                  Text(
                    isZh ? '暂无内容' : 'No posts yet',
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.xs),
                  Text(
                    isZh ? '关注更多人来充实你的信息流' : 'Follow more people to fill your feed',
                    style: ZeroTypography.caption(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.zAccent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.md,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom + 80,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final isCommentsExpanded = _expandedCommentPostIds.contains(post.id);

          return Padding(
            padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostCard(
                  post: post,
                  avatarColor: _avatarColorFor(post.authorId),
                  timeAgo: _timeAgo(post.timestamp, isZh),
                  isLiked: _feedService.isLiked(post.id),
                  isBookmarked: _feedService.isBookmarked(post.id),
                  isCommentsExpanded: isCommentsExpanded,
                  onLike: () => _toggleLike(post),
                  onBookmark: () => _toggleBookmark(post.id),
                  onComment: () => _toggleComments(post.id),
                  onRepost: () => _repost(post),
                  onCopyCid: () => _copyCid(post.cid),
                ),
                if (isCommentsExpanded) _CommentThread(post: post, onAddComment: (c) => _addComment(post.id, c)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ZeroFeedPost post;
  final Color avatarColor;
  final String timeAgo;
  final bool isLiked;
  final bool isBookmarked;
  final bool isCommentsExpanded;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onComment;
  final VoidCallback onRepost;
  final VoidCallback onCopyCid;

  const _PostCard({
    required this.post,
    required this.avatarColor,
    required this.timeAgo,
    required this.isLiked,
    required this.isBookmarked,
    required this.isCommentsExpanded,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onRepost,
    required this.onCopyCid,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isRepost)
            _RepostHeader(
              originalAuthor: post.originalPostAuthor ?? '',
              isZh: isZh,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradientAvatar(
                initial: post.authorName[0].toUpperCase(),
                color: avatarColor,
                size: ZeroSpacing.avatarMd,
              ),
              SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: ZeroTypography.bodyBold(context)
                                .copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isVerified) ...[
                          SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: context.zAccent,
                          ),
                        ],
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            post.authorDid,
                            style: ZeroTypography.monoSmall(context).copyWith(
                              fontSize: 10,
                              color: context.zTextTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm + 4),
          Text(
            post.content,
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextPrimary.withOpacity(0.88),
              height: 1.6,
            ),
          ),
          if (post.imageDesc != null) ...[
            SizedBox(height: ZeroSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ZeroSpacing.md),
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
                          avatarColor.withOpacity(0.4),
                          avatarColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: avatarColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.sm + 4),
                  Expanded(
                    child: Text(
                      post.imageDesc!,
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
          SizedBox(height: ZeroSpacing.md),
          Divider(height: 0.5, color: context.zDivider.withOpacity(0.5)),
          SizedBox(height: ZeroSpacing.sm + 4),
          Row(
            children: [
              _ActionButton(
                icon: isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                label: '${post.likes}',
                color: isLiked ? context.zError : context.zTextTertiary,
                onTap: onLike,
                filledColor: isLiked ? context.zError.withOpacity(0.1) : null,
              ),
              SizedBox(width: ZeroSpacing.lg),
              _ActionButton(
                icon: isCommentsExpanded
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                label: '${post.comments.length}',
                color: isCommentsExpanded ? context.zAccent : context.zTextTertiary,
                onTap: onComment,
              ),
              SizedBox(width: ZeroSpacing.lg),
              _ActionButton(
                icon: Icons.repeat_rounded,
                label: '${post.reposts}',
                color: context.zTextTertiary,
                onTap: onRepost,
              ),
              Spacer(),
              GestureDetector(
                onTap: onBookmark,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 20,
                    color: isBookmarked ? context.zAccent : context.zTextTertiary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          _CidBadge(cid: post.cid, onTap: onCopyCid),
        ],
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;

  const _GradientAvatar({
    required this.initial,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final color2 = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RepostHeader extends StatelessWidget {
  final String originalAuthor;
  final bool isZh;

  const _RepostHeader({
    required this.originalAuthor,
    required this.isZh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, size: 14, color: context.zTextTertiary),
          SizedBox(width: 6),
          Text(
            isZh ? '转发了 @$originalAuthor' : 'reposted from @$originalAuthor',
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 11,
              color: context.zTextTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CidBadge extends StatelessWidget {
  final String cid;
  final VoidCallback onTap;

  const _CidBadge({required this.cid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final display = cid.length > 22 ? '${cid.substring(0, 14)}...${cid.substring(cid.length - 8)}' : cid;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.zFrostWhite,
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 12, color: context.zTextDisabled),
            SizedBox(width: 4),
            Text(
              display,
              style: ZeroTypography.monoSmall(context).copyWith(
                fontSize: 9,
                color: context.zTextDisabled,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 10, color: context.zTextDisabled),
          ],
        ),
      ),
    );
  }
}

class _CommentThread extends StatefulWidget {
  final ZeroFeedPost post;
  final void Function(String content) onAddComment;

  const _CommentThread({required this.post, required this.onAddComment});

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _avatarColorFor(String id) {
    const colors = [
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
      Color(0xFFE17055),
      Color(0xFF0984E3),
      Color(0xFFFDCB6E),
      Color(0xFFE84393),
      Color(0xFF00CEC9),
      Color(0xFFD63031),
    ];
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return colors[hash % colors.length];
  }

  String _commentTimeAgo(DateTime timestamp, bool isZh) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h';
    if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d';
    return isZh ? '${timestamp.month}月${timestamp.day}日' : '${timestamp.month}/${timestamp.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final comments = widget.post.comments;

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comments.isNotEmpty) ...[
            ...comments.map((comment) => Padding(
              padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColorFor(comment.authorDid),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      comment.authorName[0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.authorName,
                              style: ZeroTypography.caption(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.zTextPrimary,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              _commentTimeAgo(comment.timestamp, isZh),
                              style: ZeroTypography.monoSmall(context).copyWith(
                                fontSize: 9,
                                color: context.zTextDisabled,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          comment.content,
                          style: ZeroTypography.body(context).copyWith(
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            Divider(height: 0.5, color: context.zDivider.withOpacity(0.3)),
            SizedBox(height: ZeroSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: ZeroTypography.body(context).copyWith(
                    fontSize: 13,
                    color: context.zTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: isZh ? '添加评论...' : 'Add a comment...',
                    hintStyle: ZeroTypography.caption(context).copyWith(
                      color: context.zTextDisabled,
                    ),
                    filled: true,
                    fillColor: context.zSurfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.sm + 4,
                      vertical: ZeroSpacing.sm,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onAddComment(value);
                      _controller.clear();
                    }
                  },
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              GestureDetector(
                onTap: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onAddComment(_controller.text);
                    _controller.clear();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.zAccent,
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: context.zBg,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? filledColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filledColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: filledColor,
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}