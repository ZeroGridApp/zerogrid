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

  List<ZeroFeedPost> get allPosts => List.unmodifiable(_posts);

  bool isLiked(String postId) => _likedPostIds.contains(postId);
  bool isBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  List<ZeroFeedPost> getFollowingPosts(String userId) {
    return _posts
        .where((p) => p.authorId == userId)
        .toList();
  }

  List<ZeroFeedPost> getTrendingPosts() {
    final sorted = List<ZeroFeedPost>.from(_posts)
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(6).toList();
  }

  List<ZeroFeedPost> getLatestPosts() {
    final sorted = List<ZeroFeedPost>.from(_posts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  ZeroFeedPost createPost(String content, String authorDid) {
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
    if (_bookmarkedPostIds.contains(postId)) {
      _bookmarkedPostIds.remove(postId);
    } else {
      _bookmarkedPostIds.add(postId);
    }
  }

  ZeroFeedPost repost(String postId, String authorDid) {
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
}