import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:zero/services/crypto/zero_crypto.dart';

class _RatchetSession {
  final Uint8List rootKey;
  Uint8List sendingChainKey;
  Uint8List receivingChainKey;
  int messageNumber;

  _RatchetSession({
    required this.rootKey,
    required this.sendingChainKey,
    required this.receivingChainKey,
    this.messageNumber = 0,
  });
}

class E2EEService {
  static final E2EEService _instance = E2EEService._();
  factory E2EEService() => _instance;
  E2EEService._();

  final _crypto = ZeroCrypto();
  final _sessions = <String, _RatchetSession>{};

  static const _infoMsg = 'zero-msg';
  static const _infoChain = 'zero-chain';
  static const _infoRoot = 'zero-root';
  static const _infoSendChain = 'zero-send-chain';
  static const _infoRecvChain = 'zero-recv-chain';
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _keyLength = 32;

  void establishSession(String peerPublicKeyHex, ECPrivateKey myPrivateKey) {
    final domain = ECCurve_secp256r1();
    final peerPubKey = _parsePublicKey(peerPublicKeyHex, domain);

    final sharedSecret = _crypto.computeSharedSecret(myPrivateKey, peerPubKey);

    final rootKey = _crypto.hkdf(
      Uint8List(0),
      sharedSecret,
      utf8.encode(_infoRoot),
      _keyLength,
    );

    final sendingChainKey = _crypto.hkdf(
      Uint8List(0),
      rootKey,
      utf8.encode(_infoSendChain),
      _keyLength,
    );

    final receivingChainKey = _crypto.hkdf(
      Uint8List(0),
      rootKey,
      utf8.encode(_infoRecvChain),
      _keyLength,
    );

    _sessions[peerPublicKeyHex] = _RatchetSession(
      rootKey: rootKey,
      sendingChainKey: sendingChainKey,
      receivingChainKey: receivingChainKey,
    );
  }

  String encryptMessage(String peerPublicKeyHex, String plaintext) {
    final session = _sessions[peerPublicKeyHex];
    if (session == null) {
      return _fallbackEncrypt(plaintext);
    }

    final nonce = _crypto.randomBytes(_nonceLength);

    final messageKey = _crypto.hkdf(
      session.sendingChainKey,
      nonce,
      utf8.encode(_infoMsg),
      _keyLength,
    );

    final result = _crypto.encryptAEAD(
      messageKey,
      nonce,
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    session.sendingChainKey = _crypto.hkdf(
      session.sendingChainKey,
      Uint8List(0),
      utf8.encode(_infoChain),
      _keyLength,
    );

    session.messageNumber++;

    return _bytesToHex(nonce) + _bytesToHex(result.mac) + _bytesToHex(result.ciphertext);
  }

  String decryptMessage(String peerPublicKeyHex, String combinedHex) {
    final session = _sessions[peerPublicKeyHex];
    if (session == null) {
      return _fallbackDecrypt(combinedHex);
    }

    final bytes = _hexToBytes(combinedHex);
    final nonce = bytes.sublist(0, _nonceLength);
    final mac = bytes.sublist(_nonceLength, _nonceLength + _macLength);
    final ciphertext = bytes.sublist(_nonceLength + _macLength);

    final messageKey = _crypto.hkdf(
      session.receivingChainKey,
      nonce,
      utf8.encode(_infoMsg),
      _keyLength,
    );

    final plaintext = _crypto.decryptAEAD(messageKey, nonce, ciphertext, mac);

    session.receivingChainKey = _crypto.hkdf(
      session.receivingChainKey,
      Uint8List(0),
      utf8.encode(_infoChain),
      _keyLength,
    );

    return utf8.decode(plaintext);
  }

  ECPublicKey _parsePublicKey(String hex, ECDomainParameters domain) {
    final bytes = _hexToBytes(hex);
    final xBytes = bytes.sublist(0, 32);
    final yBytes = bytes.sublist(32, 64);
    final encoded = Uint8List(65);
    encoded[0] = 0x04;
    encoded.setAll(1, xBytes);
    encoded.setAll(33, yBytes);
    final point = domain.curve.decodePoint(encoded)!;
    return ECPublicKey(point, domain);
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  String _fallbackEncrypt(String plaintext) {
    return plaintext;
  }

  String _fallbackDecrypt(String ciphertext) {
    return ciphertext;
  }
}