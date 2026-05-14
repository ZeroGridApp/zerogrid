import 'dart:convert';
import 'dart:typed_data';

import 'onion_routing_service.dart';

class OnionRoutedMessage {
  final String messageText;
  final OnionCircuit circuit;
  final RoutedMessageResult result;
  final DateTime routedAt;

  const OnionRoutedMessage({
    required this.messageText,
    required this.circuit,
    required this.result,
    required this.routedAt,
  });

  String get routeSummary {
    if (!result.success) return '⚠ Routing failed';
    final totalMs = result.trace.fold<int>(0, (s, t) => s + t.latencyMs);
    final nodeNames = circuit.hops.map((h) => h.node.name).join(' → ');
    return '🧅 $nodeNames · ${totalMs}ms';
  }
}

class OnionChatService {
  factory OnionChatService() => _instance;
  OnionChatService._internal() {
    _ensureCircuit();
  }
  static final OnionChatService _instance = OnionChatService._internal();

  final _router = OnionRoutingService();
  OnionCircuit? _activeCircuit;

  OnionCircuit? get activeCircuit => _activeCircuit;
  bool get hasCircuit => _activeCircuit != null && _activeCircuit!.isAlive;

  void _ensureCircuit() {
    _router.expireStaleCircuits();
    final actives = _router.activeCircuits;
    if (actives.isNotEmpty) {
      _activeCircuit = actives.first;
    } else {
      final result = _router.buildCircuit();
      if (result.success) {
        _activeCircuit = result.circuit;
      }
    }
  }

  void refreshCircuit() {
    _router.expireStaleCircuits();
    if (_activeCircuit != null && _activeCircuit!.isAlive) {
      _router.destroyCircuit(_activeCircuit!.circuitId);
    }
    final result = _router.buildCircuit();
    if (result.success) {
      _activeCircuit = result.circuit;
    }
  }

  OnionRoutedMessage sendMessage(String message, {String destination = 'did:zero:peer'}) {
    if (_activeCircuit == null || !_activeCircuit!.isAlive) {
      _ensureCircuit();
    }

    if (_activeCircuit == null || !_activeCircuit!.isAlive) {
      final result = RoutedMessageResult(
        success: false,
        error: 'No active onion circuit available',
        trace: [],
      );
      return OnionRoutedMessage(
        messageText: message,
        circuit: _activeCircuit ?? _router.buildCircuit().circuit!,
        result: result,
        routedAt: DateTime.now(),
      );
    }

    final routeResult = _router.routeMessage(_activeCircuit!, destination, message);

    return OnionRoutedMessage(
      messageText: message,
      circuit: _activeCircuit!,
      result: routeResult,
      routedAt: DateTime.now(),
    );
  }

  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}