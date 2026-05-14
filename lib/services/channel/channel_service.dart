import 'dart:math';

class ZeroChannel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String ownerId;
  final String ownerName;
  int subscriberCount;
  int postCount;
  final bool isPublic;
  final DateTime createdAt;
  final List<String> tags;

  ZeroChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.ownerId,
    required this.ownerName,
    this.subscriberCount = 0,
    this.postCount = 0,
    this.isPublic = true,
    required this.createdAt,
    this.tags = const [],
  });
}

class ChannelPost {
  final String id;
  final String channelId;
  final String channelName;
  final String authorId;
  final String authorName;
  final String content;
  final String type;
  final String? attachmentUrl;
  int likes;
  int comments;
  int reposts;
  bool isPinned;
  final DateTime createdAt;

  ChannelPost({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.type = 'text',
    this.attachmentUrl,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isPinned = false,
    required this.createdAt,
  });
}

class ChannelService {
  ChannelService._();
  static final ChannelService _instance = ChannelService._();
  factory ChannelService() => _instance;

  final List<ZeroChannel> _channels = [];
  final List<ChannelPost> _posts = [];
  final Map<String, Set<String>> _subscriptions = {};
  bool _seeded = false;

  ZeroChannel createChannel({
    required String name,
    required String description,
    required String icon,
    required String ownerId,
    required String ownerName,
    bool isPublic = true,
    List<String> tags = const [],
  }) {
    final id = 'ch_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix(4)}';
    final channel = ZeroChannel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      ownerId: ownerId,
      ownerName: ownerName,
      isPublic: isPublic,
      tags: tags,
      createdAt: DateTime.now(),
    );
    _channels.add(channel);
    return channel;
  }

  List<ZeroChannel> getChannels({String? search}) {
    var result = List<ZeroChannel>.from(_channels);
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }
    return result;
  }

  ZeroChannel? getChannel(String channelId) {
    try {
      return _channels.firstWhere((c) => c.id == channelId);
    } catch (_) {
      return null;
    }
  }

  void subscribe(String channelId, String userId) {
    final channel = getChannel(channelId);
    if (channel == null) return;
    _subscriptions.putIfAbsent(userId, () => <String>{});
    if (_subscriptions[userId]!.add(channelId)) {
      channel.subscriberCount++;
    }
  }

  void unsubscribe(String channelId, String userId) {
    final channel = getChannel(channelId);
    if (channel == null) return;
    if (_subscriptions[userId]?.remove(channelId) == true) {
      channel.subscriberCount = (channel.subscriberCount - 1).clamp(0, 999999);
    }
  }

  bool isSubscribed(String channelId, String userId) {
    return _subscriptions[userId]?.contains(channelId) ?? false;
  }

  List<ZeroChannel> getMySubscriptions(String userId) {
    final subscribedIds = _subscriptions[userId] ?? <String>{};
    return _channels.where((c) => subscribedIds.contains(c.id)).toList();
  }

  ChannelPost createPost({
    required String channelId,
    required String channelName,
    required String authorId,
    required String authorName,
    required String content,
    String type = 'text',
    String? attachmentUrl,
  }) {
    final channel = getChannel(channelId);
    if (channel == null) throw ArgumentError('Channel not found: $channelId');
    final id = 'post_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix(4)}';
    final post = ChannelPost(
      id: id,
      channelId: channelId,
      channelName: channelName,
      authorId: authorId,
      authorName: authorName,
      content: content,
      type: type,
      attachmentUrl: attachmentUrl,
      createdAt: DateTime.now(),
    );
    _posts.add(post);
    channel.postCount++;
    return post;
  }

  List<ChannelPost> getPosts(String channelId, {bool includePinned = true}) {
    var posts = _posts.where((p) => p.channelId == channelId).toList();
    if (includePinned) {
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return posts;
  }

  void likePost(String postId) {
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.likes++;
    } catch (_) {}
  }

  void pinPost(String postId) {
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.isPinned = !post.isPinned;
    } catch (_) {}
  }

  void seedDemoData() {
    if (_seeded) return;
    _seeded = true;
    seedDemoChannels();
    seedDemoPosts();
  }

  void seedDemoChannels() {
    final now = DateTime.now();
    final channels = [
      ZeroChannel(
        id: 'ch_demo_official',
        name: 'Zero 官方公告',
        description: 'Zero 项目的官方公告频道，获取最新的版本更新、安全公告和生态动态。',
        icon: '📢',
        ownerId: 'zero_team',
        ownerName: 'Zero Team',
        subscriberCount: 12580,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 365)),
        tags: ['官方', '公告', '更新'],
      ),
      ZeroChannel(
        id: 'ch_demo_crypto',
        name: '加密前沿',
        description: '关注加密技术前沿进展，包括零知识证明、同态加密、后量子密码学等。',
        icon: '🔐',
        ownerId: 'crypto_insider',
        ownerName: 'CryptoInsider',
        subscriberCount: 8920,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 280)),
        tags: ['加密', '隐私', 'ZKP', 'PQC'],
      ),
      ZeroChannel(
        id: 'ch_demo_dev',
        name: '零界开发者社区',
        description: 'Zero 生态开发者交流社区，分享技术实践、SDK 使用经验和去中心化应用开发技巧。',
        icon: '💻',
        ownerId: 'dev_lead',
        ownerName: 'DevLead',
        subscriberCount: 5640,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 200)),
        tags: ['开发者', 'SDK', 'DApp', '教程'],
      ),
      ZeroChannel(
        id: 'ch_demo_web3',
        name: 'Web3 每日精选',
        description: '每日精选 Web3 行业深度文章、项目分析和市场洞察，帮你保持行业敏感度。',
        icon: '🌐',
        ownerId: 'web3_curator',
        ownerName: 'Web3Curator',
        subscriberCount: 15300,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 450)),
        tags: ['Web3', '精选', '深度', '分析'],
      ),
      ZeroChannel(
        id: 'ch_demo_nft',
        name: 'NFT 收藏家',
        description: 'NFT 艺术鉴赏、收藏策略与市场趋势分析，探索数字艺术的无限可能。',
        icon: '🎨',
        ownerId: 'nft_whale',
        ownerName: 'NFTWhale',
        subscriberCount: 7200,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 180)),
        tags: ['NFT', '艺术', '收藏', '市场'],
      ),
      ZeroChannel(
        id: 'ch_demo_defi',
        name: 'DeFi 观察',
        description: '去中心化金融深度观察，涵盖流动性挖矿、收益聚合、跨链桥等 DeFi 前沿话题。',
        icon: '📊',
        ownerId: 'defi_analyst',
        ownerName: 'DeFiAnalyst',
        subscriberCount: 9800,
        postCount: 0,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 300)),
        tags: ['DeFi', '流动性', '收益', '跨链'],
      ),
    ];
    for (final ch in channels) {
      _channels.add(ch);
    }
  }

  void seedDemoPosts() {
    final now = DateTime.now();
    final channelPosts = <String, List<_PostSeed>>{
      'ch_demo_official': [
        _PostSeed(
          authorName: 'Zero Team',
          authorId: 'zero_team',
          content: '🎉 Zero v0.3.0 正式发布！本次更新带来了全新的 Channel 广播系统，支持一对多消息分发。同时优化了 Onion 路由延迟，平均降低 40%。',
          type: 'text',
          hoursAgo: 2,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'Zero Team',
          authorId: 'zero_team',
          content: '关于近期 P2P 网络稳定性的公告：我们已完成亚洲区域的 Relay 节点扩容，新增 12 个节点，网络连通率提升至 99.7%。',
          type: 'text',
          hoursAgo: 24,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'Zero Team',
          authorId: 'zero_team',
          content: '安全提醒：请所有用户升级至 v0.2.8 以上版本，该版本修复了一个潜在的 DID 签名验证漏洞。感谢社区安全研究员 @whitehat 的提交。',
          type: 'text',
          hoursAgo: 48,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'Zero Team',
          authorId: 'zero_team',
          content: 'Zero DID 注册量突破 100 万！感谢每一位信任 Zero 的用户，我们将继续推进去中心化身份的伟大使命。',
          type: 'image',
          attachmentUrl: '🎆',
          hoursAgo: 72,
          isPinned: false,
        ),
      ],
      'ch_demo_crypto': [
        _PostSeed(
          authorName: 'CryptoInsider',
          authorId: 'crypto_insider',
          content: 'NIST 后量子密码学标准正式发布！Kyber 被选为 KEM 标准，Dilithium 为签名标准。Zero 团队已开始 PQC 迁移评估。这对去中心化安全意味着什么？',
          type: 'text',
          hoursAgo: 6,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'CryptoInsider',
          authorId: 'crypto_insider',
          content: '零知识证明的最新进展：ZK-Rollup 吞吐量突破 10K TPS。Polygon zkEVM 和 StarkNet 的技术路线对比分析。',
          type: 'link',
          attachmentUrl: '🔗',
          hoursAgo: 18,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'CryptoInsider',
          authorId: 'crypto_insider',
          content: '同态加密在隐私计算中的应用场景越来越多，FHE 编译器性能在近一年内提升了 100 倍。我们在 Zero 的 DASN 存储中已经在探索 FHE 检索方案。',
          type: 'text',
          hoursAgo: 36,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'CryptoInsider',
          authorId: 'crypto_insider',
          content: '分享一篇深度好文：Signal 协议的双棘轮机制详解。这是 Zero E2EE 通信的核心理论基础，推荐所有开发者阅读。',
          type: 'link',
          attachmentUrl: '📄',
          hoursAgo: 60,
          isPinned: false,
        ),
      ],
      'ch_demo_dev': [
        _PostSeed(
          authorName: 'DevLead',
          authorId: 'dev_lead',
          content: 'Zero SDK v0.2.0 开发指南已更新！新增 Channel API 文档、BLE Mesh 调试技巧和 Rust FFI 调用示例。开发者们请查阅 docs.zero.app。',
          type: 'link',
          attachmentUrl: '📖',
          hoursAgo: 4,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'DevLead',
          authorId: 'dev_lead',
          content: '社区贡献者 @ZeroBuilder 提交了一个非常棒的 PR：基于 Flutter 的 Zero 组件库，包含 30+ 开箱即用的 UI 组件，完美适配 Zero 设计语言。',
          type: 'text',
          hoursAgo: 12,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'DevLead',
          authorId: 'dev_lead',
          content: '本周五晚 20:00 UTC+8 举办线上开发者 Meetup，主题：\"在 Zero 上构建你的第一个 DApp\"。将手把手演示从 DID 创建到智能合约部署的全流程。',
          type: 'text',
          hoursAgo: 30,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'DevLead',
          authorId: 'dev_lead',
          content: 'Rust FFI 踩坑笔记：在跨语言调用中如何优雅地管理内存生命周期。分享我们在一年的实践中总结的最佳实践和常见陷阱。',
          type: 'file',
          attachmentUrl: '📁',
          hoursAgo: 54,
          isPinned: false,
        ),
      ],
      'ch_demo_web3': [
        _PostSeed(
          authorName: 'Web3Curator',
          authorId: 'web3_curator',
          content: '今日精选：去中心化社交协议对比——Farcaster vs Lens vs Zero。从技术架构、治理模型和用户增长三个维度深度分析。',
          type: 'link',
          attachmentUrl: '📰',
          hoursAgo: 3,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'Web3Curator',
          authorId: 'web3_curator',
          content: 'Solana 生态爆发式增长，日活跃地址突破 200 万。分析其 Memecoin 热潮与 DePIN 叙事的底层逻辑。',
          type: 'text',
          hoursAgo: 10,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'Web3Curator',
          authorId: 'web3_curator',
          content: '以太坊 L2 总锁仓量突破 400 亿美元。Arbitrum、Optimism 和 Base 三国争霸，谁将成为最终的赢家？',
          type: 'image',
          attachmentUrl: '📈',
          hoursAgo: 22,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'Web3Curator',
          authorId: 'web3_curator',
          content: '深度长文：去中心化物理基础设施网络（DePIN）的兴起。从 Helium 到 Render Network，物理世界正在被 token 化。',
          type: 'link',
          attachmentUrl: '🔗',
          hoursAgo: 45,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'Web3Curator',
          authorId: 'web3_curator',
          content: '每周精选：5 篇必读的 Web3 研报。覆盖 BTC ETF 资金流向、稳定币监管趋势和 RWA 代币化进展。',
          type: 'file',
          attachmentUrl: '📊',
          hoursAgo: 70,
          isPinned: false,
        ),
      ],
      'ch_demo_nft': [
        _PostSeed(
          authorName: 'NFTWhale',
          authorId: 'nft_whale',
          content: '生成艺术赛道迎来新玩家：Tyler Hobbs 的新系列 \"QQL\" 以算法之美重新定义 NFT 艺术的边界。探讨生成艺术的审美范式。',
          type: 'image',
          attachmentUrl: '🖼️',
          hoursAgo: 8,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'NFTWhale',
          authorId: 'nft_whale',
          content: 'NFT 流动性解决方案大盘点：Blur 借贷、NFTX 碎片化和 Sudoswap AMM，哪种方案更适合你的收藏策略？',
          type: 'text',
          hoursAgo: 20,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'NFTWhale',
          authorId: 'nft_whale',
          content: '音乐 NFT 赛道悄然崛起。Sound.xyz 和 Catalog 的总交易额在过去三个月增长 300%。数字音乐的所有权革命开始了。',
          type: 'link',
          attachmentUrl: '🎵',
          hoursAgo: 40,
          isPinned: false,
        ),
      ],
      'ch_demo_defi': [
        _PostSeed(
          authorName: 'DeFiAnalyst',
          authorId: 'defi_analyst',
          content: 'DeFi 收益率周报：ETH 质押收益稳定在 3.5%，AAVE USDC 存款利率升至 8.2%。市场对杠杆需求明显回暖。',
          type: 'text',
          hoursAgo: 5,
          isPinned: true,
        ),
        _PostSeed(
          authorName: 'DeFiAnalyst',
          authorId: 'defi_analyst',
          content: '跨链互操作性协议竞争加剧。LayerZero、Wormhole 和 Chainlink CCIP，三大跨链方案的技术架构对比与安全性评估。',
          type: 'link',
          attachmentUrl: '🔗',
          hoursAgo: 16,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'DeFiAnalyst',
          authorId: 'defi_analyst',
          content: 'Restaking 叙事持续升温。EigenLayer TVL 突破 150 亿美元，LRT 赛道迎来爆发。分析 restaking 对以太坊安全模型的深远影响。',
          type: 'text',
          hoursAgo: 32,
          isPinned: false,
        ),
        _PostSeed(
          authorName: 'DeFiAnalyst',
          authorId: 'defi_analyst',
          content: 'RWA 代币化协议全景图：Ondo、Centrifuge 和 Maple 的差异化竞争策略。传统金融与 DeFi 的融合正在加速。',
          type: 'file',
          attachmentUrl: '📑',
          hoursAgo: 56,
          isPinned: false,
        ),
      ],
    };

    final channelNames = {
      'ch_demo_official': 'Zero 官方公告',
      'ch_demo_crypto': '加密前沿',
      'ch_demo_dev': '零界开发者社区',
      'ch_demo_web3': 'Web3 每日精选',
      'ch_demo_nft': 'NFT 收藏家',
      'ch_demo_defi': 'DeFi 观察',
    };

    for (final entry in channelPosts.entries) {
      final channelId = entry.key;
      final channelName = channelNames[channelId] ?? '';
      for (final seed in entry.value) {
        final post = ChannelPost(
          id: 'post_${channelId}_${seed.hoursAgo}_${_randomSuffix(4)}',
          channelId: channelId,
          channelName: channelName,
          authorId: seed.authorId,
          authorName: seed.authorName,
          content: seed.content,
          type: seed.type,
          attachmentUrl: seed.attachmentUrl,
          likes: _randomCount(5, 200),
          comments: _randomCount(1, 50),
          reposts: _randomCount(0, 30),
          isPinned: seed.isPinned,
          createdAt: now.subtract(Duration(hours: seed.hoursAgo)),
        );
        _posts.add(post);
      }
    }
  }

  int _randomCount(int min, int max) => min + Random().nextInt(max - min + 1);

  String _randomSuffix(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}

class _PostSeed {
  final String authorName;
  final String authorId;
  final String content;
  final String type;
  final String? attachmentUrl;
  final int hoursAgo;
  final bool isPinned;

  const _PostSeed({
    required this.authorName,
    required this.authorId,
    required this.content,
    required this.type,
    this.attachmentUrl,
    required this.hoursAgo,
    required this.isPinned,
  });
}