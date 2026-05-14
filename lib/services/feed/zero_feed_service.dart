import 'dart:math';

class ZeroFeedComment {
  final String id;
  final String postId;
  final String authorName;
  final String authorDid;
  final String content;
  final DateTime timestamp;

  const ZeroFeedComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorDid,
    required this.content,
    required this.timestamp,
  });
}

class ZeroFeedPost {
  final String id;
  final String authorName;
  final String authorId;
  final String authorDid;
  final String content;
  final String? imageUrl;
  final String? imageDesc;
  final String cid;
  final DateTime timestamp;
  int likes;
  int reposts;
  final bool isRepost;
  final String? originalPostAuthor;
  final bool isVerified;
  List<ZeroFeedComment> comments;

  ZeroFeedPost({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.authorDid,
    required this.content,
    this.imageUrl,
    this.imageDesc,
    required this.cid,
    required this.timestamp,
    required this.likes,
    required this.reposts,
    this.isRepost = false,
    this.originalPostAuthor,
    this.isVerified = false,
    List<ZeroFeedComment>? comments,
  }) : comments = comments ?? [];
}

class ZeroFeedService {
  ZeroFeedService._();
  static final ZeroFeedService _instance = ZeroFeedService._();
  factory ZeroFeedService() => _instance;

  final List<ZeroFeedPost> _posts = [];
  final Set<String> _likedPostIds = {};
  final Set<String> _bookmarkedPostIds = {};
  int _commentCounter = 100;
  bool _seeded = false;

  List<ZeroFeedPost> get allPosts {
    _ensureSeeded();
    return List.unmodifiable(_posts);
  }

  bool isLiked(String postId) => _likedPostIds.contains(postId);
  bool isBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  List<ZeroFeedPost> getFollowingPosts(String userId) {
    _ensureSeeded();
    const followingIds = {
      'alice',
      'bob',
      'charlie',
      'diana',
      'eve',
      'frank',
      'grace',
    };
    return _posts
        .where((p) => followingIds.contains(p.authorId) || p.authorId == userId)
        .toList();
  }

  List<ZeroFeedPost> getTrendingPosts() {
    _ensureSeeded();
    final sorted = List<ZeroFeedPost>.from(_posts)
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(6).toList();
  }

  List<ZeroFeedPost> getLatestPosts() {
    _ensureSeeded();
    final sorted = List<ZeroFeedPost>.from(_posts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  ZeroFeedPost createPost(String content, String authorDid) {
    _ensureSeeded();
    final now = DateTime.now();
    final id = 'post_${now.millisecondsSinceEpoch}';
    final cidRaw = _generateCid('$authorDid:$content:${now.microsecondsSinceEpoch}');
    final post = ZeroFeedPost(
      id: id,
      authorName: 'You',
      authorId: 'you',
      authorDid: authorDid,
      content: content,
      cid: cidRaw,
      timestamp: now,
      likes: 0,
      reposts: 0,
      isVerified: true,
    );
    _posts.insert(0, post);
    return post;
  }

  ZeroFeedComment addComment(String postId, String content) {
    _ensureSeeded();
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      throw ArgumentError('Post not found: $postId');
    }
    final comment = ZeroFeedComment(
      id: 'cmt_${_commentCounter++}',
      postId: postId,
      authorName: 'You',
      authorDid: 'Z8P2K5W1RT',
      content: content,
      timestamp: DateTime.now(),
    );
    _posts[postIndex].comments.add(comment);
    return comment;
  }

  void toggleLike(String postId) {
    _ensureSeeded();
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
      _posts[postIndex].likes = (_posts[postIndex].likes - 1).clamp(0, 999999);
    } else {
      _likedPostIds.add(postId);
      _posts[postIndex].likes += 1;
    }
  }

  void toggleBookmark(String postId) {
    _ensureSeeded();
    if (_bookmarkedPostIds.contains(postId)) {
      _bookmarkedPostIds.remove(postId);
    } else {
      _bookmarkedPostIds.add(postId);
    }
  }

  ZeroFeedPost repost(String postId, String authorDid) {
    _ensureSeeded();
    final originalIndex = _posts.indexWhere((p) => p.id == postId);
    if (originalIndex == -1) {
      throw ArgumentError('Post not found: $postId');
    }
    final original = _posts[originalIndex];
    original.reposts += 1;
    final now = DateTime.now();
    final repostId = 'repost_${now.millisecondsSinceEpoch}';
    final repost = ZeroFeedPost(
      id: repostId,
      authorName: 'You',
      authorId: 'you',
      authorDid: authorDid,
      content: original.content,
      cid: original.cid,
      timestamp: now,
      likes: 0,
      reposts: 0,
      isRepost: true,
      originalPostAuthor: original.authorName,
      isVerified: true,
    );
    _posts.insert(0, repost);
    return repost;
  }

  void _ensureSeeded() {
    if (!_seeded) {
      _seedPosts();
      _seeded = true;
    }
  }

  String _generateCid(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final hex = hash.toRadixString(16).padLeft(8, '0');
    final random = Random(hash);
    final extra = List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'z0$hex$extra';
  }

  void _seedPosts() {
    final now = DateTime.now();

    final p1 = ZeroFeedPost(
      id: 'post_1',
      authorName: 'Alice',
      authorId: 'alice',
      authorDid: 'Z4A7F2K9NM',
      content: 'Just deployed a new ZeroNode relay in Singapore 📡 Latency down to 12ms. The mesh is getting faster every day. BLE mesh routing through 18 hops in under 2 seconds.',
      imageDesc: '新加坡节点部署',
      cid: _generateCid('alice:singapore-node:1'),
      timestamp: now.subtract(const Duration(hours: 2)),
      likes: 42,
      reposts: 12,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_1',
          postId: 'post_1',
          authorName: 'NodeWhisperer',
          authorDid: 'Z5N3O7D1EW',
          content: 'Amazing latency numbers! Are you using the new QUIC transport layer?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
        ZeroFeedComment(
          id: 'cmt_2',
          postId: 'post_1',
          authorName: 'Alice',
          authorDid: 'Z4A7F2K9NM',
          content: 'Yes, QUIC + custom congestion control. The results are incredible.',
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );

    final p2 = ZeroFeedPost(
      id: 'post_2',
      authorName: 'Bob',
      authorId: 'bob',
      authorDid: 'Z1B3N6M2KP',
      content: 'GM ☕️ Building the future of decentralized communication. Every line of code brings us closer to true digital sovereignty. ZeroDNS resolution now under 50ms!',
      cid: _generateCid('bob:gm-decentralized:2'),
      timestamp: now.subtract(const Duration(hours: 5)),
      likes: 28,
      reposts: 3,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_3',
          postId: 'post_2',
          authorName: 'CryptoMing',
          authorDid: 'Z8C5R2P9VK',
          content: 'ZeroDNS is a game changer. No more ICANN dependency.',
          timestamp: now.subtract(const Duration(hours: 4)),
        ),
      ],
    );

    final p3 = ZeroFeedPost(
      id: 'post_3',
      authorName: 'Charlie',
      authorId: 'charlie',
      authorDid: 'Z5C9R2T7LW',
      content: 'My ZeroPay just processed 50 USDT in under 3 seconds. This is insane 🔥 Peer-to-peer value transfer without intermediaries — the way it should be. Gasless too!',
      cid: _generateCid('charlie:zeropay-50usdt:3'),
      timestamp: now.subtract(const Duration(hours: 8)),
      likes: 67,
      reposts: 22,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_4',
          postId: 'post_3',
          authorName: 'Grace',
          authorDid: 'Z3G7M9P4BT',
          content: 'The BIP44 integration with ZeroPay is seamless. Love it.',
          timestamp: now.subtract(const Duration(hours: 7)),
        ),
        ZeroFeedComment(
          id: 'cmt_5',
          postId: 'post_3',
          authorName: 'ZeroBuilder',
          authorDid: 'Z0B4U7I2LD',
          content: 'Wait till you see the Lightning Network bridge in v0.3.0 ⚡',
          timestamp: now.subtract(const Duration(hours: 6, minutes: 30)),
        ),
        ZeroFeedComment(
          id: 'cmt_6',
          postId: 'post_3',
          authorName: 'Charlie',
          authorDid: 'Z5C9R2T7LW',
          content: 'Can\'t wait! The future of money is permissionless.',
          timestamp: now.subtract(const Duration(hours: 6)),
        ),
      ],
    );

    final p4 = ZeroFeedPost(
      id: 'post_4',
      authorName: 'Diana',
      authorId: 'diana',
      authorDid: 'Z7D2W5X9QP',
      content: 'ZeroFeed is the web3 Twitter we needed. No algorithm, no censorship, no shadow-banning. Just people and their ideas. Content-addressed, immutable, unstoppable.',
      cid: _generateCid('diana:zerofeed-web3-twitter:4'),
      timestamp: now.subtract(const Duration(hours: 12)),
      likes: 89,
      reposts: 45,
      isVerified: false,
      comments: [
        ZeroFeedComment(
          id: 'cmt_7',
          postId: 'post_4',
          authorName: 'VoidWalker',
          authorDid: 'Z6V1N8T3HJ',
          content: 'This is the vision. Decentralized social is the final frontier.',
          timestamp: now.subtract(const Duration(hours: 11)),
        ),
      ],
    );

    final p5 = ZeroFeedPost(
      id: 'post_5',
      authorName: 'Eve',
      authorId: 'eve',
      authorDid: 'Z2E8V4H1RM',
      content: 'Testing BLE mesh in the mountains. Offline chat is working perfectly 🏔️ Three nodes, zero internet, messages delivered in under 800ms. The mesh finds its own path.',
      imageDesc: '🏔️ 山区BLE测试',
      cid: _generateCid('eve:ble-mesh-mountains:5'),
      timestamp: now.subtract(const Duration(hours: 24)),
      likes: 53,
      reposts: 7,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_8',
          postId: 'post_5',
          authorName: 'PixelNomad',
          authorDid: 'Z4P1X2E7LM',
          content: 'Offline comms in the wild. This is what freedom looks like.',
          timestamp: now.subtract(const Duration(hours: 22)),
        ),
      ],
    );

    final p6 = ZeroFeedPost(
      id: 'post_6',
      authorName: 'Frank',
      authorId: 'frank',
      authorDid: 'Z9F4K1S6YD',
      content: 'New Zero theme "Frost" is gorgeous. The silver-blue with subtle glassmorphism effects is mesmerizing. Dark mode finally done right ❄️ Contributions welcome on the repo.',
      imageDesc: 'Frost 主题预览',
      cid: _generateCid('frank:frost-theme:6'),
      timestamp: now.subtract(const Duration(hours: 26)),
      likes: 71,
      reposts: 15,
      isVerified: false,
      comments: [
        ZeroFeedComment(
          id: 'cmt_9',
          postId: 'post_6',
          authorName: 'Sunny',
          authorDid: 'Z2S5U7N9NY',
          content: 'The glassmorphism cards are absolutely stunning. PR sent!',
          timestamp: now.subtract(const Duration(hours: 24)),
        ),
      ],
    );

    final p7 = ZeroFeedPost(
      id: 'post_7',
      authorName: 'Grace',
      authorId: 'grace',
      authorDid: 'Z3G7M9P4BT',
      content: 'Just minted my ZeroID as a DID document on-chain. Self-sovereign identity feels good. No more begging platforms for verification. My keys, my identity, my rules.',
      cid: _generateCid('grace:did-mint:7'),
      timestamp: now.subtract(const Duration(hours: 48)),
      likes: 94,
      reposts: 33,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_10',
          postId: 'post_7',
          authorName: 'QuantumLeap',
          authorDid: 'Z7Q5U2A1NT',
          content: 'DID + ZeroID = the holy grail of decentralized identity. Congrats!',
          timestamp: now.subtract(const Duration(hours: 46)),
        ),
        ZeroFeedComment(
          id: 'cmt_11',
          postId: 'post_7',
          authorName: 'InkMaster',
          authorDid: 'Z9I1N4K7MA',
          content: 'Self-sovereign identity is a human right. Beautiful work.',
          timestamp: now.subtract(const Duration(hours: 44)),
        ),
      ],
    );

    final p8 = ZeroFeedPost(
      id: 'post_8',
      authorName: 'VoidWalker',
      authorId: 'voidwalker',
      authorDid: 'Z6V1N8T3HJ',
      content: 'Zero privacy features are underrated. Onion routing + Double Ratchet + disappearing messages = the holy trinity of secure comms 🔐 Each layer adds exponential security.',
      cid: _generateCid('voidwalker:privacy-trinity:8'),
      timestamp: now.subtract(const Duration(hours: 3)),
      likes: 156,
      reposts: 67,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_12',
          postId: 'post_8',
          authorName: 'Alice',
          authorDid: 'Z4A7F2K9NM',
          content: 'The Double Ratchet implementation is particularly elegant. Forward secrecy on every message.',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
        ),
        ZeroFeedComment(
          id: 'cmt_13',
          postId: 'post_8',
          authorName: 'Eve',
          authorDid: 'Z2E8V4H1RM',
          content: 'Onion routing with 3 hops? Any plans for 5-hop circuits?',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ZeroFeedComment(
          id: 'cmt_14',
          postId: 'post_8',
          authorName: 'VoidWalker',
          authorDid: 'Z6V1N8T3HJ',
          content: 'Configurable hop count coming in the next release. 3-7 hops, your choice.',
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );

    final p9 = ZeroFeedPost(
      id: 'post_9',
      authorName: 'CryptoMing',
      authorId: 'cryptoming',
      authorDid: 'Z8C5R2P9VK',
      content: 'BTC halving analysis: historical patterns suggest Q3-Q4 will be explosive. ZeroPay integration with Lightning Network would be a game changer ⚡ P2P value transfer on layer 2.',
      cid: _generateCid('cryptoming:btc-halving:9'),
      timestamp: now.subtract(const Duration(hours: 6)),
      likes: 132,
      reposts: 51,
      isVerified: false,
      comments: [
        ZeroFeedComment(
          id: 'cmt_15',
          postId: 'post_9',
          authorName: 'Charlie',
          authorDid: 'Z5C9R2T7LW',
          content: 'If ZeroPay gets Lightning, it\'s over for traditional payment rails.',
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
      ],
    );

    final p10 = ZeroFeedPost(
      id: 'post_10',
      authorName: 'ZeroBuilder',
      authorId: 'zerobuilder',
      authorDid: 'Z0B4U7I2LD',
      content: 'Zero SDK v0.2.0 is coming. New features: content-addressed storage layer, improved relay discovery, WebRTC signaling overhaul, and a pluggable crypto backend. Ship it! 🚀',
      cid: _generateCid('zerobuilder:sdk-v020:10'),
      timestamp: now.subtract(const Duration(hours: 10)),
      likes: 118,
      reposts: 40,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_16',
          postId: 'post_10',
          authorName: 'Bob',
          authorDid: 'Z1B3N6M2KP',
          content: 'Pluggable crypto backend is huge. Post-quantum ready!',
          timestamp: now.subtract(const Duration(hours: 9)),
        ),
        ZeroFeedComment(
          id: 'cmt_17',
          postId: 'post_10',
          authorName: 'Diana',
          authorDid: 'Z7D2W5X9QP',
          content: 'The WebRTC overhaul will make browser-based nodes so much better.',
          timestamp: now.subtract(const Duration(hours: 8)),
        ),
      ],
    );

    final p11 = ZeroFeedPost(
      id: 'post_11',
      authorName: 'NodeWhisperer',
      authorId: 'nodewhisperer',
      authorDid: 'Z5N3O7D1EW',
      content: 'Running a ZeroNode on a Raspberry Pi 5 for 30 days straight. Zero downtime, 8W power consumption. Decentralization doesn\'t need a data center. Your home is the data center.',
      imageDesc: 'Raspberry Pi ZeroNode',
      cid: _generateCid('nodewhisperer:rpi5-node:11'),
      timestamp: now.subtract(const Duration(hours: 18)),
      likes: 147,
      reposts: 55,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_18',
          postId: 'post_11',
          authorName: 'Frank',
          authorDid: 'Z9F4K1S6YD',
          content: '8W is incredible! What OS are you running?',
          timestamp: now.subtract(const Duration(hours: 17)),
        ),
        ZeroFeedComment(
          id: 'cmt_19',
          postId: 'post_11',
          authorName: 'NodeWhisperer',
          authorDid: 'Z5N3O7D1EW',
          content: 'Custom Alpine Linux build with the Zero runtime. Super lightweight.',
          timestamp: now.subtract(const Duration(hours: 16)),
        ),
      ],
    );

    final p12 = ZeroFeedPost(
      id: 'post_12',
      authorName: 'QuantumLeap',
      authorId: 'quantumleap',
      authorDid: 'Z7Q5U2A1NT',
      content: 'Post-quantum cryptography roadmap for Zero: NIST PQC candidates under evaluation. Kyber-1024 for KEM, Dilithium-5 for signatures. Future-proofing starts now. The quantum threat is real.',
      cid: _generateCid('quantumleap:pqc-roadmap:12'),
      timestamp: now.subtract(const Duration(hours: 30)),
      likes: 128,
      reposts: 60,
      isVerified: true,
      comments: [
        ZeroFeedComment(
          id: 'cmt_20',
          postId: 'post_12',
          authorName: 'VoidWalker',
          authorDid: 'Z6V1N8T3HJ',
          content: 'Kyber-1024 is the right call. NIST approved and battle-tested.',
          timestamp: now.subtract(const Duration(hours: 28)),
        ),
        ZeroFeedComment(
          id: 'cmt_21',
          postId: 'post_12',
          authorName: 'CryptoMing',
          authorDid: 'Z8C5R2P9VK',
          content: 'What about SPHINCS+ for stateless hash-based signatures?',
          timestamp: now.subtract(const Duration(hours: 27)),
        ),
        ZeroFeedComment(
          id: 'cmt_22',
          postId: 'post_12',
          authorName: 'QuantumLeap',
          authorDid: 'Z7Q5U2A1NT',
          content: 'SPHINCS+ is in the roadmap for v0.4.0. Larger signatures but no state management needed.',
          timestamp: now.subtract(const Duration(hours: 26)),
        ),
      ],
    );

    _posts.addAll([p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12]);
  }
}