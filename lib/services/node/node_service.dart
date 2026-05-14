import 'dart:math';

class NodeConfig {
  final String nodeType;
  final String region;
  final int port;
  final bool autoStart;
  final bool natTraversal;
  final int storageGb;
  final int stakeAmount;
  final String? externalIp;

  const NodeConfig({
    required this.nodeType,
    required this.region,
    required this.port,
    required this.autoStart,
    required this.natTraversal,
    required this.storageGb,
    required this.stakeAmount,
    this.externalIp,
  });

  NodeConfig copyWith({
    String? nodeType,
    String? region,
    int? port,
    bool? autoStart,
    bool? natTraversal,
    int? storageGb,
    int? stakeAmount,
    String? externalIp,
  }) {
    return NodeConfig(
      nodeType: nodeType ?? this.nodeType,
      region: region ?? this.region,
      port: port ?? this.port,
      autoStart: autoStart ?? this.autoStart,
      natTraversal: natTraversal ?? this.natTraversal,
      storageGb: storageGb ?? this.storageGb,
      stakeAmount: stakeAmount ?? this.stakeAmount,
      externalIp: externalIp ?? this.externalIp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeType': nodeType,
      'region': region,
      'port': port,
      'autoStart': autoStart,
      'natTraversal': natTraversal,
      'storageGb': storageGb,
      'stakeAmount': stakeAmount,
      'externalIp': externalIp,
    };
  }

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      nodeType: json['nodeType'] as String,
      region: json['region'] as String,
      port: json['port'] as int,
      autoStart: json['autoStart'] as bool,
      natTraversal: json['natTraversal'] as bool,
      storageGb: json['storageGb'] as int,
      stakeAmount: json['stakeAmount'] as int,
      externalIp: json['externalIp'] as String?,
    );
  }
}

class NodeStatus {
  final String nodeId;
  final String name;
  final String nodeType;
  final String status;
  final double uptime;
  final int peersConnected;
  final int blocksSynced;
  final int blocksTotal;
  final int latency;
  final double bandwidthUp;
  final double bandwidthDown;
  final int storageUsed;
  final int storageTotal;
  final int rewardsEarned;
  final DateTime startedAt;

  const NodeStatus({
    required this.nodeId,
    required this.name,
    required this.nodeType,
    required this.status,
    required this.uptime,
    required this.peersConnected,
    required this.blocksSynced,
    required this.blocksTotal,
    required this.latency,
    required this.bandwidthUp,
    required this.bandwidthDown,
    required this.storageUsed,
    required this.storageTotal,
    required this.rewardsEarned,
    required this.startedAt,
  });

  String getUptimeString() {
    return '${uptime.toStringAsFixed(1)}%';
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'name': name,
      'nodeType': nodeType,
      'status': status,
      'uptime': uptime,
      'peersConnected': peersConnected,
      'blocksSynced': blocksSynced,
      'blocksTotal': blocksTotal,
      'latency': latency,
      'bandwidthUp': bandwidthUp,
      'bandwidthDown': bandwidthDown,
      'storageUsed': storageUsed,
      'storageTotal': storageTotal,
      'rewardsEarned': rewardsEarned,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory NodeStatus.fromJson(Map<String, dynamic> json) {
    return NodeStatus(
      nodeId: json['nodeId'] as String,
      name: json['name'] as String,
      nodeType: json['nodeType'] as String,
      status: json['status'] as String,
      uptime: (json['uptime'] as num).toDouble(),
      peersConnected: json['peersConnected'] as int,
      blocksSynced: json['blocksSynced'] as int,
      blocksTotal: json['blocksTotal'] as int,
      latency: json['latency'] as int,
      bandwidthUp: (json['bandwidthUp'] as num).toDouble(),
      bandwidthDown: (json['bandwidthDown'] as num).toDouble(),
      storageUsed: json['storageUsed'] as int,
      storageTotal: json['storageTotal'] as int,
      rewardsEarned: json['rewardsEarned'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }
}

class PeerNode {
  final String peerId;
  final String address;
  final String region;
  final int latency;
  final String role;
  final bool isReachable;

  const PeerNode({
    required this.peerId,
    required this.address,
    required this.region,
    required this.latency,
    required this.role,
    required this.isReachable,
  });

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'address': address,
      'region': region,
      'latency': latency,
      'role': role,
      'isReachable': isReachable,
    };
  }

  factory PeerNode.fromJson(Map<String, dynamic> json) {
    return PeerNode(
      peerId: json['peerId'] as String,
      address: json['address'] as String,
      region: json['region'] as String,
      latency: json['latency'] as int,
      role: json['role'] as String,
      isReachable: json['isReachable'] as bool,
    );
  }
}

class NetworkStats {
  final int totalNodes;
  final int onlineNodes;
  final double averageLatency;
  final double totalBandwidth;
  final int totalStorage;
  final List<PeerNode> topPeers;

  const NetworkStats({
    required this.totalNodes,
    required this.onlineNodes,
    required this.averageLatency,
    required this.totalBandwidth,
    required this.totalStorage,
    required this.topPeers,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalNodes': totalNodes,
      'onlineNodes': onlineNodes,
      'averageLatency': averageLatency,
      'totalBandwidth': totalBandwidth,
      'totalStorage': totalStorage,
      'topPeers': topPeers.map((p) => p.toJson()).toList(),
    };
  }

  factory NetworkStats.fromJson(Map<String, dynamic> json) {
    return NetworkStats(
      totalNodes: json['totalNodes'] as int,
      onlineNodes: json['onlineNodes'] as int,
      averageLatency: (json['averageLatency'] as num).toDouble(),
      totalBandwidth: (json['totalBandwidth'] as num).toDouble(),
      totalStorage: json['totalStorage'] as int,
      topPeers: (json['topPeers'] as List<dynamic>)
          .map((p) => PeerNode.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ZeroNodeService {
  static final ZeroNodeService _instance = ZeroNodeService._();
  factory ZeroNodeService() => _instance;
  ZeroNodeService._();

  final _random = Random();
  bool _seeded = false;

  NodeConfig _config = const NodeConfig(
    nodeType: 'relay',
    region: 'asia-east',
    port: 9744,
    autoStart: true,
    natTraversal: true,
    storageGb: 50,
    stakeAmount: 1000,
  );

  late NodeStatus _status;
  List<PeerNode> _peers = [];
  late NetworkStats _networkStats;
  bool _isNodeRunning = false;

  NodeConfig getConfig() {
    return _config;
  }

  void updateConfig(NodeConfig config) {
    _config = config;
  }

  NodeStatus getStatus() {
    _seedIfNeeded();
    return _status;
  }

  NetworkStats getNetworkStats() {
    _seedIfNeeded();
    return _networkStats;
  }

  List<PeerNode> getPeerNodes() {
    _seedIfNeeded();
    return List.unmodifiable(_peers);
  }

  bool get isNodeRunning => _isNodeRunning;

  void deployNode(NodeConfig config) {
    _config = config;
    _isNodeRunning = true;

    final now = DateTime.now();
    final nodeId = 'ZN${_random.nextInt(900000) + 100000}';

    final typeNames = {
      'relay': 'Relay',
      'storage': 'Storage',
      'validator': 'Validator',
      'full': 'Full',
    };

    _status = NodeStatus(
      nodeId: nodeId,
      name: '${typeNames[config.nodeType] ?? 'Node'}-${_random.nextInt(900) + 100}',
      nodeType: config.nodeType,
      status: 'online',
      uptime: 100.0,
      peersConnected: _random.nextInt(30) + 15,
      blocksSynced: _random.nextInt(50000) + 8500000,
      blocksTotal: _random.nextInt(50000) + 8500000,
      latency: _random.nextInt(20) + 12,
      bandwidthUp: (_random.nextDouble() * 15 + 8),
      bandwidthDown: (_random.nextDouble() * 30 + 15),
      storageUsed: _random.nextInt(config.storageGb * 1024 ~/ 4),
      storageTotal: config.storageGb * 1024,
      rewardsEarned: _random.nextInt(500) + 100,
      startedAt: now,
    );

    _peers = _generatePeers(config.region);
    _networkStats = _generateNetworkStats(config.region);
  }

  void startNode() {
    _isNodeRunning = true;
    _seedIfNeeded();

    _status = NodeStatus(
      nodeId: _status.nodeId,
      name: _status.name,
      nodeType: _status.nodeType,
      status: 'online',
      uptime: _status.uptime,
      peersConnected: _status.peersConnected,
      blocksSynced: _status.blocksSynced,
      blocksTotal: _status.blocksTotal,
      latency: _status.latency,
      bandwidthUp: _status.bandwidthUp,
      bandwidthDown: _status.bandwidthDown,
      storageUsed: _status.storageUsed,
      storageTotal: _status.storageTotal,
      rewardsEarned: _status.rewardsEarned,
      startedAt: _status.startedAt,
    );
  }

  void stopNode() {
    _isNodeRunning = false;

    _status = NodeStatus(
      nodeId: _status.nodeId,
      name: _status.name,
      nodeType: _status.nodeType,
      status: 'offline',
      uptime: _status.uptime,
      peersConnected: 0,
      blocksSynced: _status.blocksSynced,
      blocksTotal: _status.blocksTotal,
      latency: 0,
      bandwidthUp: 0,
      bandwidthDown: 0,
      storageUsed: _status.storageUsed,
      storageTotal: _status.storageTotal,
      rewardsEarned: _status.rewardsEarned,
      startedAt: _status.startedAt,
    );
  }

  void restartNode() {
    _isNodeRunning = true;

    _status = NodeStatus(
      nodeId: _status.nodeId,
      name: _status.name,
      nodeType: _status.nodeType,
      status: 'online',
      uptime: _status.uptime,
      peersConnected: _random.nextInt(30) + 15,
      blocksSynced: _status.blocksTotal,
      blocksTotal: _status.blocksTotal,
      latency: _random.nextInt(20) + 12,
      bandwidthUp: (_random.nextDouble() * 15 + 8),
      bandwidthDown: (_random.nextDouble() * 30 + 15),
      storageUsed: _status.storageUsed,
      storageTotal: _status.storageTotal,
      rewardsEarned: _status.rewardsEarned,
      startedAt: _status.startedAt,
    );
  }

  void seedDemoData() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();
    _status = NodeStatus(
      nodeId: 'ZN728491',
      name: 'Relay-314',
      nodeType: 'relay',
      status: 'online',
      uptime: 99.7,
      peersConnected: 28,
      blocksSynced: 8523147,
      blocksTotal: 8523147,
      latency: 18,
      bandwidthUp: 12.4,
      bandwidthDown: 28.7,
      storageUsed: 12288,
      storageTotal: 51200,
      rewardsEarned: 342,
      startedAt: now.subtract(const Duration(days: 47)),
    );

    _isNodeRunning = true;

    _peers = _generatePeers('asia-east');

    _networkStats = NetworkStats(
      totalNodes: 1247,
      onlineNodes: 1189,
      averageLatency: 28.3,
      totalBandwidth: 18420.5,
      totalStorage: 2560000,
      topPeers: _peers.take(5).toList(),
    );
  }

  List<PeerNode> _generatePeers(String region) {
    final allPeers = <PeerNode>[
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '103.45.67.${_random.nextInt(200) + 10}',
        region: 'asia-east',
        latency: _random.nextInt(15) + 8,
        role: 'relay',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '185.22.34.${_random.nextInt(200) + 10}',
        region: 'eu-west',
        latency: _random.nextInt(25) + 30,
        role: 'storage',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '54.12.89.${_random.nextInt(200) + 10}',
        region: 'us-east',
        latency: _random.nextInt(20) + 40,
        role: 'validator',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '177.33.21.${_random.nextInt(200) + 10}',
        region: 'asia-east',
        latency: _random.nextInt(10) + 5,
        role: 'full',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '12.55.78.${_random.nextInt(200) + 10}',
        region: 'us-west',
        latency: _random.nextInt(30) + 55,
        role: 'relay',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '91.44.56.${_random.nextInt(200) + 10}',
        region: 'eu-west',
        latency: _random.nextInt(20) + 25,
        role: 'storage',
        isReachable: false,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '156.33.45.${_random.nextInt(200) + 10}',
        region: 'asia-south',
        latency: _random.nextInt(20) + 45,
        role: 'validator',
        isReachable: true,
      ),
      PeerNode(
        peerId: 'ZN${_random.nextInt(900000) + 100000}',
        address: '203.11.22.${_random.nextInt(200) + 10}',
        region: 'asia-east',
        latency: _random.nextInt(10) + 10,
        role: 'relay',
        isReachable: true,
      ),
    ];

    final regionPrio = [region, 'asia-east', 'us-east', 'eu-west'];
    allPeers.sort((a, b) {
      final aIdx = regionPrio.indexOf(a.region);
      final bIdx = regionPrio.indexOf(b.region);
      final aP = aIdx == -1 ? 99 : aIdx;
      final bP = bIdx == -1 ? 99 : bIdx;
      final cmp = aP.compareTo(bP);
      if (cmp != 0) return cmp;
      return a.latency.compareTo(b.latency);
    });

    return allPeers;
  }

  NetworkStats _generateNetworkStats(String region) {
    return NetworkStats(
      totalNodes: 1200 + _random.nextInt(200),
      onlineNodes: 1100 + _random.nextInt(150),
      averageLatency: (_random.nextDouble() * 20 + 20),
      totalBandwidth: (_random.nextDouble() * 5000 + 15000),
      totalStorage: (_random.nextInt(1000000) + 2000000),
      topPeers: _peers.take(5).toList(),
    );
  }

  void _seedIfNeeded() {
    if (!_seeded) {
      seedDemoData();
    }
  }
}