import 'dart:math';

class CallRecord {
  final String id;
  final String peerName;
  final String peerDid;
  final String type;
  final String direction;
  final int durationSeconds;
  final DateTime timestamp;
  final String status;
  final bool isEncrypted;
  final bool onionRouted;

  const CallRecord({
    required this.id,
    required this.peerName,
    required this.peerDid,
    required this.type,
    required this.direction,
    required this.durationSeconds,
    required this.timestamp,
    required this.status,
    this.isEncrypted = true,
    this.onionRouted = true,
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }
}

class _ActiveCall {
  final String id;
  final String peerName;
  final String peerDid;
  final bool isVideo;
  final bool isIncoming;
  final DateTime startTime;
  bool isConnected;
  int durationSeconds;

  _ActiveCall({
    required this.id,
    required this.peerName,
    required this.peerDid,
    required this.isVideo,
    required this.isIncoming,
    required this.startTime,
    this.isConnected = false,
    this.durationSeconds = 0,
  });

  CallRecord toRecord({required String status}) {
    return CallRecord(
      id: id,
      peerName: peerName,
      peerDid: peerDid,
      type: isVideo ? 'video' : 'audio',
      direction: isIncoming ? 'incoming' : 'outgoing',
      durationSeconds: durationSeconds,
      timestamp: startTime,
      status: status,
    );
  }
}

class CallService {
  CallService._();

  static final CallService _instance = CallService._();
  static CallService get instance => _instance;

  final List<CallRecord> _history = [];
  _ActiveCall? _currentCall;
  final Random _random = Random();

  String startCall(String peerName, String peerDid, bool isVideo) {
    final id = _generateId();
    _currentCall = _ActiveCall(
      id: id,
      peerName: peerName,
      peerDid: peerDid,
      isVideo: isVideo,
      isIncoming: false,
      startTime: DateTime.now(),
    );
    return id;
  }

  String receiveCall(String peerName, String peerDid, bool isVideo) {
    final id = _generateId();
    _currentCall = _ActiveCall(
      id: id,
      peerName: peerName,
      peerDid: peerDid,
      isVideo: isVideo,
      isIncoming: true,
      startTime: DateTime.now(),
    );
    return id;
  }

  void acceptCall(String callId) {
    if (_currentCall?.id != callId) return;
    _currentCall!.isConnected = true;
  }

  void endCall(String callId) {
    if (_currentCall?.id != callId) return;
    _currentCall!.isConnected = false;
    _history.insert(0, _currentCall!.toRecord(status: 'completed'));
    _currentCall = null;
  }

  void rejectCall(String callId) {
    if (_currentCall?.id != callId) return;
    _history.insert(0, _currentCall!.toRecord(
      status: _currentCall!.isIncoming ? 'rejected' : 'missed',
    ));
    _currentCall = null;
  }

  void updateCallDuration(String callId, int seconds) {
    if (_currentCall?.id != callId) return;
    _currentCall!.durationSeconds = seconds;
  }

  List<CallRecord> getCallHistory() {
    return List.unmodifiable(_history);
  }

  _ActiveCall? getCurrentCall() {
    return _currentCall;
  }

  bool get isInCall => _currentCall != null;

  void seedDemoHistory() {
    if (_history.isNotEmpty) return;

    final demos = [
      _demo('Alice', 'Z8K2M9P1RX', 'audio', 'incoming', 125, 8, 'completed'),
      _demo('Bob', 'Z3N7R4Q2WY', 'video', 'outgoing', 1842, 42, 'completed'),
      _demo('Charlie', 'Z1V6B8S3ZT', 'audio', 'missed', 0, 65, 'missed'),
      _demo('Diana', 'Z5L0C7F4XU', 'video', 'incoming', 342, 19, 'completed'),
      _demo('Eve', 'Z9H4M2D6KP', 'audio', 'outgoing', 68, 2, 'completed'),
      _demo('Frank', 'Z7T3W1N8RJ', 'audio', 'incoming', 0, 112, 'missed'),
      _demo('Grace', 'Z2P8K5V0QL', 'video', 'outgoing', 2700, 56, 'completed'),
      _demo('Hank', 'Z4X6R9M3BY', 'audio', 'incoming', 450, 23, 'completed'),
      _demo('Ivy', 'Z6B1L7C2SW', 'audio', 'outgoing', 0, 88, 'rejected'),
      _demo('Jack', 'Z0Q3D8G5NT', 'video', 'incoming', 1200, 33, 'completed'),
      _demo('Karen', 'Z8M5V2K9FH', 'audio', 'outgoing', 35, 1, 'completed'),
      _demo('Leo', 'Z1R7P4W0DJ', 'video', 'missed', 0, 140, 'missed'),
    ];

    _history.addAll(demos);
  }

  CallRecord _demo(
    String name,
    String did,
    String type,
    String direction,
    int duration,
    int minutesAgo,
    String status,
  ) {
    return CallRecord(
      id: _generateId(),
      peerName: name,
      peerDid: did,
      type: type,
      direction: direction,
      durationSeconds: duration,
      timestamp: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      status: status,
    );
  }

  String _generateId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buf = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buf.write(chars[_random.nextInt(chars.length)]);
    }
    return 'call_${buf.toString()}';
  }
}