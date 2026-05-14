import 'dart:async';

class BLEService {
  static final BLEService _instance = BLEService._();
  factory BLEService() => _instance;
  BLEService._();

  bool _scanning = false;
  final List<BLEDevice> _discoveredDevices = [];
  final List<BLEMessage> _messageQueue = [];
  StreamController<List<BLEDevice>>? _deviceController;
  StreamController<BLEMessage>? _messageController;
  Timer? _scanTimer;

  Stream<List<BLEDevice>> get deviceStream {
    _deviceController ??= StreamController<List<BLEDevice>>.broadcast();
    return _deviceController!.stream;
  }

  Stream<BLEMessage> get messageStream {
    _messageController ??= StreamController<BLEMessage>.broadcast();
    return _messageController!.stream;
  }

  Future<bool> isAvailable() async {
    return true;
  }

  Future<void> startScanning() async {
    if (_scanning) return;
    _scanning = true;
    _discoveredDevices.clear();

    _discoveredDevices.addAll([
      BLEDevice(
        deviceId: 'DE:AD:BE:EF:01',
        zeroId: 'Z3K7M2N8XP',
        displayName: 'Node_7F3A',
        rssi: -45,
      ),
      BLEDevice(
        deviceId: 'DE:AD:BE:EF:02',
        zeroId: 'Z8P2K5W1RT',
        displayName: 'Node_B21C',
        rssi: -62,
      ),
      BLEDevice(
        deviceId: 'DE:AD:BE:EF:03',
        zeroId: null,
        displayName: 'Unknown Device',
        rssi: -78,
      ),
    ]);

    _deviceController?.add(List.unmodifiable(_discoveredDevices));

    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_scanning) return;
      _deviceController?.add(List.unmodifiable(_discoveredDevices));
    });
  }

  Future<void> stopScanning() async {
    _scanning = false;
    _scanTimer?.cancel();
  }

  Future<void> sendMessage(String zeroId, String text) async {
    final msg = BLEMessage(
      senderId: 'Z8P2K5W1RT',
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      delivered: false,
    );
    _messageQueue.add(msg);
    _messageController?.add(msg);

    Future.delayed(const Duration(milliseconds: 300), () {
      msg.delivered = true;
      _messageController?.add(msg);
    });
  }

  void dispose() {
    _scanTimer?.cancel();
    _deviceController?.close();
    _messageController?.close();
  }
}

class BLEDevice {
  final String deviceId;
  final String? zeroId;
  final String displayName;
  final int rssi;
  bool connected;

  BLEDevice({
    required this.deviceId,
    this.zeroId,
    required this.displayName,
    required this.rssi,
    this.connected = false,
  });
}

class BLEMessage {
  final String senderId;
  final String text;
  final int timestamp;
  bool delivered;

  BLEMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.delivered = false,
  });
}