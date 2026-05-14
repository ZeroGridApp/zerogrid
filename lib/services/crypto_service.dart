import 'dart:convert';
import 'dart:typed_data';

class CryptoService {
  static Uint8List generateKey() {
    final key = List<int>.generate(32, (_) => DateTime.now().microsecondsSinceEpoch & 0xFF);
    return Uint8List.fromList(key);
  }

  static String encryptMessage(Uint8List key, String plaintext) {
    final plainBytes = utf8.encode(plaintext);
    final encrypted = <int>[];
    for (int i = 0; i < plainBytes.length; i++) {
      encrypted.add(plainBytes[i] ^ key[i % key.length]);
    }
    return base64Encode(encrypted);
  }

  static String decryptMessage(Uint8List key, String ciphertext) {
    final encrypted = base64Decode(ciphertext);
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key[i % key.length]);
    }
    return utf8.decode(decrypted);
  }

  static String hashMessage(String senderId, String recipientId, String content, int timestamp) {
    final input = '$senderId:$recipientId:$content:$timestamp';
    final hash = input.codeUnits.fold<int>(0, (prev, element) => ((prev << 5) + prev) ^ element);
    return hash.toRadixString(16).padLeft(16, '0');
  }
}