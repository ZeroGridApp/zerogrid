import 'dart:typed_data';

class ZeroNativeBridge {
  static final ZeroNativeBridge _instance = ZeroNativeBridge._();
  factory ZeroNativeBridge() => _instance;
  ZeroNativeBridge._();

  bool _initialized = false;

  Future<bool> isAvailable() async {
    if (_initialized) return true;
    try {
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> initFromMnemonic(String mnemonic) async {
    return 'ok';
  }

  Future<String> getZeroId() async {
    return 'Z8P2K5W1RT';
  }

  Future<Uint8List> encryptForPeer(String peerId, String plaintext) async {
    final bytes = plaintext.codeUnits;
    return Uint8List.fromList(bytes);
  }

  Future<String> decryptFromPeer(String peerId, Uint8List ciphertext) async {
    return String.fromCharCodes(ciphertext);
  }

  Future<String> getWalletAddresses() async {
    return '{"addresses":[]}';
  }
}