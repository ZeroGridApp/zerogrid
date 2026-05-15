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

  int _randomCount(int min, int max) => min + Random().nextInt(max - min + 1);

  String _randomSuffix(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}