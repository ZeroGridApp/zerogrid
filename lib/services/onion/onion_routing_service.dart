import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import '../crypto/zero_crypto.dart';

class OnionNode {
  final String id;
  final String name;
  final String region;
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;
  final String publicKeyHex;
  final DateTime registeredAt;
  bool isOnline;
  int latencyMs;
  double uptime;

  OnionNode({
    required this.id,
    required this.name,
    required this.region,
    required this.privateKey,
    required this.publicKey,
    required this.publicKeyHex,
    DateTime? registeredAt,
    this.isOnline = true,
    this.latencyMs = 50,
    this.uptime = 0.99,
  }) : registeredAt = registeredAt ?? DateTime.now();
}

class OnionHop {
  final OnionNode node;
  final Uint8List sharedSecret;
  final Uint8List forwardKey;
  final Uint8List backwardKey;
  final int hopIndex;

  const OnionHop({
    required this.node,
    required this.sharedSecret,
    required this.forwardKey,
    required this.backwardKey,
    required this.hopIndex,
  });
}

class OnionCircuit {
  final String circuitId;
  final List<OnionHop> hops;
  final DateTime createdAt;
  DateTime expiresAt;
  bool isAlive;
  int bytesForwarded;
  int bytesReceived;
  DateTime? lastActivityAt;
  String? statusMessage;

  OnionCircuit({
    required this.circuitId,
    required this.hops,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.isAlive = true,
    this.bytesForwarded = 0,
    this.bytesReceived = 0,
    this.lastActivityAt,
    this.statusMessage,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 10));

  List<String> get nodePath => hops.map((h) => h.node.name).toList();
  int get hopCount => hops.length;
}

class LayeredOnion {
  final Uint8List packet;
  final int totalLayers;
  final List<String> hopIds;

  const LayeredOnion({
    required this.packet,
    required this.totalLayers,
    required this.hopIds,
  });
}

class CircuitBuildResult {
  final bool success;
  final OnionCircuit? circuit;
  final String? error;
  final Duration buildTime;

  const CircuitBuildResult({
    required this.success,
    this.circuit,
    this.error,
    required this.buildTime,
  });
}

class RoutedMessageResult {
  final bool success;
  final String? error;
  final List<RoutingTraceStep> trace;

  const RoutedMessageResult({
    required this.success,
    this.error,
    required this.trace,
  });
}

class RoutingTraceStep {
  final String nodeName;
  final int hopIndex;
  final String action;
  final int latencyMs;
  final String? detail;

  const RoutingTraceStep({
    required this.nodeName,
    required this.hopIndex,
    required this.action,
    required this.latencyMs,
    this.detail,
  });
}

class OnionRoutingService {
  factory OnionRoutingService() => _instance;
  OnionRoutingService._internal() {
    _seedNodes();
  }
  static final OnionRoutingService _instance = OnionRoutingService._internal();

  final _crypto = ZeroCrypto();
  final _random = Random.secure();

  final Map<String, OnionNode> _nodes = {};
  final List<OnionCircuit> _circuits = [];
  final List<RoutingTraceStep> _latestTrace = [];

  List<OnionNode> get availableNodes =>
      _nodes.values.where((n) => n.isOnline).toList();

  List<OnionCircuit> get activeCircuits =>
      _circuits.where((c) => c.isAlive).toList();

  List<RoutingTraceStep> get latestTrace => List.unmodifiable(_latestTrace);

  int get nodeCount => _nodes.length;
  int get circuitCount => _circuits.length;
  int get activeCircuitCount => activeCircuits.length;

  void _seedNodes() {
    final domain = ECCurve_secp256r1();
    final seedNodes = [
      _NodeSeed('ZN-ALPHA-7F', 'Alpha', 'Singapore'),
      _NodeSeed('ZN-BETA-3K', 'Beta', 'Tokyo'),
      _NodeSeed('ZN-GAMMA-9M', 'Gamma', 'Frankfurt'),
      _NodeSeed('ZN-DELTA-2P', 'Delta', 'San Francisco'),
      _NodeSeed('ZN-EPSILON-5R', 'Epsilon', 'London'),
      _NodeSeed('ZN-ZETA-8W', 'Zeta', 'Sydney'),
      _NodeSeed('ZN-ETA-1X', 'Eta', 'Seoul'),
      _NodeSeed('ZN-THETA-4N', 'Theta', 'Mumbai'),
      _NodeSeed('ZN-IOTA-6V', 'Iota', 'Amsterdam'),
      _NodeSeed('ZN-KAPPA-0U', 'Kappa', 'Toronto'),
    ];

    for (final seed in seedNodes) {
      final d = _bytesToBigInt(_crypto.randomBytes(32)) % domain.n!;
      final privKey = ECPrivateKey(d, domain);
      final Q = domain.G! * d;
      final pubKey = ECPublicKey(Q!, domain);
      final pubHex = _pointToHex(Q);

      _nodes[seed.id] = OnionNode(
        id: seed.id,
        name: seed.name,
        region: seed.region,
        privateKey: privKey,
        publicKey: pubKey,
        publicKeyHex: pubHex,
        latencyMs: 15 + _random.nextInt(85),
        uptime: 0.95 + _random.nextDouble() * 0.05,
      );
    }
  }

  OnionNode addCustomNode(String name, String region) {
    final domain = ECCurve_secp256r1();
    final id = 'ZN-CUSTOM-${_nodes.length.toString().padLeft(4, '0')}';
    final d = _bytesToBigInt(_crypto.randomBytes(32)) % domain.n!;
    final privKey = ECPrivateKey(d, domain);
    final Q = domain.G! * d;
    final pubKey = ECPublicKey(Q!, domain);
    final pubHex = _pointToHex(Q);

    final node = OnionNode(
      id: id,
      name: name,
      region: region,
      privateKey: privKey,
      publicKey: pubKey,
      publicKeyHex: pubHex,
    );
    _nodes[id] = node;
    return node;
  }

  CircuitBuildResult buildCircuit({int hopCount = 3, OnionNode? source}) {
    final sw = Stopwatch()..start();
    _latestTrace.clear();

    final candidates = _nodes.values.where((n) => n.isOnline).toList();
    if (candidates.length < hopCount) {
      return CircuitBuildResult(
        success: false,
        error: 'Not enough nodes: need $hopCount, have ${candidates.length}',
        buildTime: sw.elapsed,
      );
    }

    candidates.sort((a, b) {
      if (source != null) {
        if (a.id == source.id) return 1;
        if (b.id == source.id) return -1;
      }
      return a.latencyMs.compareTo(b.latencyMs);
    });

    final selected = <OnionNode>[];
    final usedRegions = <String>{};
    final myKeyPair = _generateMyKeyPair();
    final domain = ECCurve_secp256r1();
    final myPubHex = _pointToHex(myKeyPair['pub'] as ECPoint);
    final myPrivKey = myKeyPair['priv'] as ECPrivateKey;

    for (final candidate in candidates) {
      if (selected.length >= hopCount) break;
      if (source != null && candidate.id == source.id) continue;
      if (usedRegions.contains(candidate.region)) continue;
      selected.add(candidate);
      usedRegions.add(candidate.region);
    }

    if (selected.length < hopCount) {
      return CircuitBuildResult(
        success: false,
        error: 'Not enough diverse regions for $hopCount hops',
        buildTime: sw.elapsed,
      );
    }

    final hops = <OnionHop>[];
    for (var i = 0; i < selected.length; i++) {
      final sharedSecret = _crypto.computeSharedSecret(
        myPrivKey,
        selected[i].publicKey,
      );

      final forwardKey = _crypto.hkdf(
        sharedSecret,
        utf8.encode('onion-forward-$i'),
        utf8.encode('zero-onion-routing-v1'),
        32,
      );

      final backwardKey = _crypto.hkdf(
        sharedSecret,
        utf8.encode('onion-backward-$i'),
        utf8.encode('zero-onion-routing-v1'),
        32,
      );

      hops.add(OnionHop(
        node: selected[i],
        sharedSecret: sharedSecret,
        forwardKey: forwardKey,
        backwardKey: backwardKey,
        hopIndex: i,
      ));
    }

    final circuitId = _generateCircuitId();
    final circuit = OnionCircuit(
      circuitId: circuitId,
      hops: hops,
      statusMessage: 'Circuit established',
    );
    _circuits.add(circuit);

    for (var i = 0; i < hops.length; i++) {
      _latestTrace.add(RoutingTraceStep(
        nodeName: hops[i].node.name,
        hopIndex: i,
        action: i == 0 ? 'ENTRY_EXTEND' : (i == hops.length - 1 ? 'EXIT_EXTEND' : 'MIDDLE_EXTEND'),
        latencyMs: hops[i].node.latencyMs,
        detail: 'ECDH established · ${hops[i].node.region}',
      ));
    }

    return CircuitBuildResult(
      success: true,
      circuit: circuit,
      buildTime: sw.elapsed,
    );
  }

  LayeredOnion buildOnionLayers(OnionCircuit circuit, String destination, String payload) {
    final nonceSize = 12;
    Uint8List currentPayload = Uint8List.fromList(utf8.encode(payload));

    final hopsReversed = List<OnionHop>.from(circuit.hops.reversed);

    for (var i = 0; i < hopsReversed.length; i++) {
      final hop = hopsReversed[i];
      final isLastHop = i == 0;

      String relayInstruction;
      if (isLastHop) {
        relayInstruction = 'EXIT:$destination';
      } else {
        final nextHop = hopsReversed[i + 1];
        relayInstruction = 'RELAY:${nextHop.node.id}';
      }

      final instructionBytes = utf8.encode(relayInstruction);
      final combinedPayload = Uint8List(4 + instructionBytes.length + currentPayload.length);
      combinedPayload.buffer.asByteData().setUint32(0, instructionBytes.length, Endian.big);
      combinedPayload.setAll(4, instructionBytes);
      combinedPayload.setAll(4 + instructionBytes.length, currentPayload);

      final nonce = _crypto.randomBytes(nonceSize);
      final result = _crypto.encryptAEAD(hop.forwardKey, nonce, combinedPayload);

      final noncePlusCiphertext = Uint8List(nonceSize + result.ciphertext.length + 16);
      noncePlusCiphertext.setAll(0, nonce);
      noncePlusCiphertext.setAll(nonceSize, result.ciphertext);
      noncePlusCiphertext.setAll(nonceSize + result.ciphertext.length, result.mac);

      currentPayload = noncePlusCiphertext;
    }

    return LayeredOnion(
      packet: currentPayload,
      totalLayers: circuit.hopCount,
      hopIds: circuit.hops.map((h) => h.node.id).toList(),
    );
  }

  RoutedMessageResult routeMessage(OnionCircuit circuit, String destination, String payload) {
    final sw = Stopwatch()..start();
    _latestTrace.clear();

    final layered = buildOnionLayers(circuit, destination, payload);

    Uint8List currentPacket = layered.packet;
    var success = true;

    for (var i = 0; i < circuit.hops.length; i++) {
      final hop = circuit.hops[i];
      final hopStart = Stopwatch()..start();

      try {
        if (currentPacket.length < 28) {
          throw Exception('Packet too short at hop $i');
        }

        final rawNonce = currentPacket.sublist(0, 12);
        final mac = currentPacket.sublist(currentPacket.length - 16, currentPacket.length);
        final ciphertext = currentPacket.sublist(12, currentPacket.length - 16);

        final decrypted = _crypto.decryptAEAD(hop.forwardKey, rawNonce, ciphertext, mac);

        final reader = ByteData.sublistView(decrypted);
        final instructionLen = reader.getUint32(0, Endian.big);
        final instruction = utf8.decode(decrypted.sublist(4, 4 + instructionLen));
        final innerPayload = decrypted.sublist(4 + instructionLen);

        final parts = instruction.split(':');
        final action = parts[0];

        if (action == 'EXIT') {
          final exitTarget = parts.length > 1 ? parts[1] : destination;
          _latestTrace.add(RoutingTraceStep(
            nodeName: hop.node.name,
            hopIndex: i,
            action: 'EXIT_DELIVER',
            latencyMs: hopStart.elapsedMilliseconds,
            detail: '→ $exitTarget · ${innerPayload.length} bytes plaintext',
          ));
          circuit.bytesReceived += payload.length;
        } else if (action == 'RELAY') {
          final nextNodeId = parts[1];
          final nextNode = _nodes[nextNodeId];
          _latestTrace.add(RoutingTraceStep(
            nodeName: hop.node.name,
            hopIndex: i,
            action: 'RELAY_FORWARD',
            latencyMs: hopStart.elapsedMilliseconds,
            detail: '→ ${nextNode?.name ?? nextNodeId} · ${innerPayload.length} bytes encrypted',
          ));
          currentPacket = innerPayload;
        } else {
          throw Exception('Unknown onion instruction: $action');
        }
      } catch (e) {
        success = false;
        _latestTrace.add(RoutingTraceStep(
          nodeName: hop.node.name,
          hopIndex: i,
          action: 'ERROR',
          latencyMs: hopStart.elapsedMilliseconds,
          detail: 'Layer decrypt failed: $e',
        ));
        break;
      }
    }

    circuit.lastActivityAt = DateTime.now();
    circuit.bytesForwarded += payload.length;

    return RoutedMessageResult(
      success: success,
      error: success ? null : 'Routing failed',
      trace: List.from(_latestTrace),
    );
  }

  void destroyCircuit(String circuitId) {
    _circuits.removeWhere((c) {
      if (c.circuitId == circuitId) {
        c.isAlive = false;
        c.statusMessage = 'Circuit destroyed';
        return true;
      }
      return false;
    });
  }

  void refreshCircuit(String circuitId) {
    final idx = _circuits.indexWhere((c) => c.circuitId == circuitId);
    if (idx == -1) return;
    final oldCircuit = _circuits[idx];
    _circuits.removeAt(idx);

    final result = buildCircuit(hopCount: oldCircuit.hopCount);
    if (result.success && result.circuit != null) {
      final oldCircuitHops = result.circuit!.hops;
      final newCircuit = OnionCircuit(
        circuitId: circuitId,
        hops: oldCircuitHops,
        bytesForwarded: oldCircuit.bytesForwarded,
        bytesReceived: oldCircuit.bytesReceived,
        statusMessage: 'Circuit refreshed',
      );
      _circuits.add(newCircuit);
    }
  }

  void expireStaleCircuits() {
    final now = DateTime.now();
    for (final circuit in _circuits) {
      if (circuit.isAlive && now.isAfter(circuit.expiresAt)) {
        circuit.isAlive = false;
        circuit.statusMessage = 'Circuit expired';
      }
    }
    _circuits.removeWhere((c) => !c.isAlive);
  }

  OnionNode? findNodeById(String id) => _nodes[id];

  String _generateCircuitId() {
    final bytes = _crypto.randomBytes(8);
    return 'CIRCUIT-${_bytesToHex(bytes).substring(0, 8).toUpperCase()}';
  }

  Map<String, dynamic> _generateMyKeyPair() {
    final domain = ECCurve_secp256r1();
    final d = _bytesToBigInt(_crypto.randomBytes(32)) % domain.n!;
    final privKey = ECPrivateKey(d, domain);
    final Q = domain.G! * d;
    return {'priv': privKey, 'pub': Q!};
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  String _pointToHex(ECPoint point) {
    final x = point.x!.toBigInteger()!;
    final y = point.y!.toBigInteger()!;
    final xb = Uint8List(32);
    final yb = Uint8List(32);
    var v = x;
    for (var i = 31; i >= 0; i--) {
      xb[i] = (v & BigInt.from(0xFF)).toInt();
      v = v >> 8;
    }
    v = y;
    for (var i = 31; i >= 0; i--) {
      yb[i] = (v & BigInt.from(0xFF)).toInt();
      v = v >> 8;
    }
    return _bytesToHex(xb) + _bytesToHex(yb);
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class _NodeSeed {
  final String id;
  final String name;
  final String region;
  const _NodeSeed(this.id, this.name, this.region);
}