import 'dart:math';

class BootstrapNode {
  final String id;
  final String address;
  final String region;
  final String status;
  final int latency;
  final int peersConnected;
  final double uptime;
  final DateTime lastSeen;

  const BootstrapNode({
    required this.id,
    required this.address,
    required this.region,
    required this.status,
    required this.latency,
    required this.peersConnected,
    required this.uptime,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'region': region,
      'status': status,
      'latency': latency,
      'peersConnected': peersConnected,
      'uptime': uptime,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}

class DiscoveredPeer {
  final String peerId;
  final String multiaddr;
  final List<String> protocols;
  final String agentVersion;
  final Map<String, int> latencies;
  final DateTime? connectedSince;
  final bool isReachable;

  const DiscoveredPeer({
    required this.peerId,
    required this.multiaddr,
    required this.protocols,
    required this.agentVersion,
    required this.latencies,
    this.connectedSince,
    required this.isReachable,
  });

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'multiaddr': multiaddr,
      'protocols': protocols,
      'agentVersion': agentVersion,
      'latencies': latencies,
      'connectedSince': connectedSince?.toIso8601String(),
      'isReachable': isReachable,
    };
  }

  int get averageLatency {
    if (latencies.isEmpty) return 0;
    return latencies.values.reduce((a, b) => a + b) ~/ latencies.length;
  }
}

class NetworkDiscoveryStats {
  final int totalKnownPeers;
  final int activePeers;
  final double avgLatency;
  final int kadBuckets;
  final Map<String, int> protocolCounts;

  const NetworkDiscoveryStats({
    required this.totalKnownPeers,
    required this.activePeers,
    required this.avgLatency,
    required this.kadBuckets,
    required this.protocolCounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalKnownPeers': totalKnownPeers,
      'activePeers': activePeers,
      'avgLatency': avgLatency,
      'kadBuckets': kadBuckets,
      'protocolCounts': protocolCounts,
    };
  }
}

class NodeDiscoveryService {
  static final NodeDiscoveryService _instance = NodeDiscoveryService._internal();
  factory NodeDiscoveryService() => _instance;
  NodeDiscoveryService._internal();

  final List<BootstrapNode> _bootstrapNodes = [];
  final List<DiscoveredPeer> _discoveredPeers = [];
  final Random _random = Random();

  final List<String> _availableProtocols = const [
    '/zero/kad/1.0.0',
    '/zero/msg/1.0.0',
    '/zero/relay/1.0.0',
    '/zero/pubsub/1.0.0',
    '/zero/stream/1.0.0',
    '/p2p/circuit/relay/0.2.1',
    '/ipfs/ping/1.0.0',
    '/ipfs/identify/1.0.0',
  ];

  final List<String> _agentVersions = const [
    'zero/1.0.0',
    'zero/1.1.0-beta',
    'zero/0.9.2',
    'go-zero/1.0.0',
    'rust-zero/0.8.5',
  ];

  List<DiscoveredPeer> discoverPeers({String? targetPeerId}) {
    final peerCount = 8 + _random.nextInt(8);
    final newPeers = <DiscoveredPeer>[];

    for (int i = 0; i < peerCount; i++) {
      final peer = _generateRandomPeer();
      newPeers.add(peer);
      if (!_discoveredPeers.any((p) => p.peerId == peer.peerId)) {
        _discoveredPeers.add(peer);
      }
    }

    return newPeers;
  }

  List<DiscoveredPeer> getClosestPeers(String targetId, [int k = 20]) {
    if (_discoveredPeers.isEmpty) {
      discoverPeers();
    }

    final sorted = List<DiscoveredPeer>.from(_discoveredPeers)
      ..sort((a, b) {
        final distanceA = _calculateXorDistance(a.peerId, targetId);
        final distanceB = _calculateXorDistance(b.peerId, targetId);
        return distanceA.compareTo(distanceB);
      });

    return sorted.take(k).toList();
  }

  List<BootstrapNode> getBootstrapStatus() {
    return List.unmodifiable(_bootstrapNodes);
  }

  NetworkDiscoveryStats getNetworkStats() {
    final activePeers = _discoveredPeers.where((p) => p.connectedSince != null).length;
    final totalLatency = _discoveredPeers.fold<int>(
      0,
      (sum, peer) => sum + peer.averageLatency,
    );
    final avgLatency = _discoveredPeers.isEmpty
        ? 0.0
        : totalLatency / _discoveredPeers.length;

    final protocolCounts = <String, int>{};
    for (final peer in _discoveredPeers) {
      for (final protocol in peer.protocols) {
        protocolCounts[protocol] = (protocolCounts[protocol] ?? 0) + 1;
      }
    }

    return NetworkDiscoveryStats(
      totalKnownPeers: _discoveredPeers.length,
      activePeers: activePeers,
      avgLatency: avgLatency,
      kadBuckets: 16,
      protocolCounts: protocolCounts,
    );
  }

  DiscoveredPeer? findPeer(String peerId) {
    try {
      return _discoveredPeers.firstWhere((p) => p.peerId == peerId);
    } catch (e) {
      return null;
    }
  }

  List<DiscoveredPeer> getRoutingTable() {
    return List.unmodifiable(_discoveredPeers);
  }

  void clearDiscoveredPeers() {
    _discoveredPeers.clear();
  }

  int get totalPeers => _discoveredPeers.length;

  DiscoveredPeer _generateRandomPeer() {
    final peerId = _generateBase58Id();
    final ipOctet1 = _random.nextInt(256);
    final ipOctet2 = _random.nextInt(256);
    final ipOctet3 = _random.nextInt(256);
    final ipOctet4 = _random.nextInt(256);
    final port = 10000 + _random.nextInt(50000);

    final multiaddr = '/ip4/$ipOctet1.$ipOctet2.$ipOctet3.$ipOctet4/tcp/$port/p2p/$peerId';

    final protocolCount = 3 + _random.nextInt(5);
    final protocols = <String>[];
    final available = List<String>.from(_availableProtocols);
    for (int i = 0; i < protocolCount && available.isNotEmpty; i++) {
      final index = _random.nextInt(available.length);
      protocols.add(available.removeAt(index));
    }

    final latencies = <String, int>{};
    for (final bootstrap in _bootstrapNodes) {
      final baseLatency = bootstrap.latency;
      final jitter = _random.nextInt(40) - 20;
      latencies[bootstrap.id] = (baseLatency + jitter).clamp(1, 500);
    }

    final agentVersion = _agentVersions[_random.nextInt(_agentVersions.length)];
    final isReachable = _random.nextDouble() > 0.3;
    final connectedRecently = _random.nextDouble() > 0.6;
    final connectedSince = connectedRecently
        ? DateTime.now().subtract(Duration(minutes: _random.nextInt(60 * 24 * 7)))
        : null;

    return DiscoveredPeer(
      peerId: peerId,
      multiaddr: multiaddr,
      protocols: protocols,
      agentVersion: agentVersion,
      latencies: latencies,
      connectedSince: connectedSince,
      isReachable: isReachable,
    );
  }

  String _generateBase58Id() {
    const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final buffer = StringBuffer();
    for (int i = 0; i < 46; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  int _calculateXorDistance(String a, String b) {
    int distance = 0;
    final minLength = min(a.length, b.length);
    for (int i = 0; i < minLength; i++) {
      distance += (a.codeUnitAt(i) ^ b.codeUnitAt(i));
    }
    return distance + (a.length - b.length).abs();
  }
}