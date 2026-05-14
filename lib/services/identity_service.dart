import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:zero/services/crypto/zero_crypto.dart';

class IdentityService {
  static const _storageKey = 'zero_identity_seed';
  static const _mnemonicKey = 'zero_mnemonic';
  static const _initializedKey = 'zero_initialized';
  static const _storageTimeout = Duration(seconds: 3);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isInitialized() async {
    try {
      final val = await _storage.read(key: _initializedKey).timeout(_storageTimeout);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<ZeroIdentity> createIdentity() async {
    final identity = ZeroIdentity.generate();
    _persist(identity);
    return identity;
  }

  Future<ZeroIdentity> createIdentityFromMnemonic(String mnemonic) async {
    final identity = ZeroIdentity.fromMnemonic(mnemonic);
    _persist(identity);
    return identity;
  }

  Future<ZeroIdentity?> loadIdentity() async {
    try {
      final mnemonic = await _storage.read(key: _mnemonicKey).timeout(_storageTimeout);
      if (mnemonic == null) {
        final data = await _storage.read(key: _storageKey).timeout(_storageTimeout);
        if (data == null) return null;
        final legacy = ZeroIdentity.fromJson(data);
        _safeWrite(_mnemonicKey, legacy.mnemonic);
        return legacy;
      }
      return ZeroIdentity.fromMnemonic(mnemonic);
    } catch (e) {
      debugPrint('IdentityService: loadIdentity failed: $e');
      return null;
    }
  }

  Future<void> clearIdentity() async {
    try {
      await _storage.delete(key: _storageKey).timeout(_storageTimeout);
      await _storage.delete(key: _mnemonicKey).timeout(_storageTimeout);
      await _storage.delete(key: _initializedKey).timeout(_storageTimeout);
    } catch (_) {}
  }

  void _persist(ZeroIdentity identity) {
    _safeWrite(_mnemonicKey, identity.mnemonic);
    _safeWrite(_storageKey, identity.toJson());
    _safeWrite(_initializedKey, 'true');
  }

  void _safeWrite(String key, String value) {
    _storage.write(key: key, value: value).timeout(_storageTimeout).catchError((e) {
      debugPrint('IdentityService: write $key failed: $e');
    });
  }
}

class ZeroIdentity {
  final String zeroId;
  final String mnemonic;
  final String publicKeyHex;

  const ZeroIdentity({
    required this.zeroId,
    required this.mnemonic,
    required this.publicKeyHex,
  });

  factory ZeroIdentity.generate() {
    final crypto = ZeroCrypto();
    final mnemonic = crypto.generateMnemonic(strength: 128);
    final seed = crypto.mnemonicToSeed(mnemonic);
    final keys = crypto.generateIdentityKeys(seed);
    final zeroId = _deriveZeroId(keys.publicKeyHex);
    return ZeroIdentity(
      zeroId: zeroId,
      mnemonic: mnemonic,
      publicKeyHex: keys.publicKeyHex,
    );
  }

  factory ZeroIdentity.fromMnemonic(String mnemonic) {
    final crypto = ZeroCrypto();
    if (!crypto.validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }
    final seed = crypto.mnemonicToSeed(mnemonic);
    final keys = crypto.generateIdentityKeys(seed);
    final zeroId = _deriveZeroId(keys.publicKeyHex);
    return ZeroIdentity(
      zeroId: zeroId,
      mnemonic: mnemonic,
      publicKeyHex: keys.publicKeyHex,
    );
  }

  String toJson() {
    return jsonEncode({
      'zero_id': zeroId,
      'mnemonic': mnemonic,
      'public_key_hex': publicKeyHex,
    });
  }

  factory ZeroIdentity.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ZeroIdentity(
      zeroId: map['zero_id'] as String,
      mnemonic: map['mnemonic'] as String,
      publicKeyHex: map['public_key_hex'] as String,
    );
  }

  static String _deriveZeroId(String publicKeyHex) {
    final crypto = ZeroCrypto();
    final hash = crypto.sha256(Uint8List.fromList(utf8.encode(publicKeyHex)));
    final base32 = _base32Encode(hash);
    return 'Z${base32.substring(0, 9)}';
  }

  static String _base32Encode(Uint8List bytes) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    var bits = 0;
    var value = 0;

    for (final byte in bytes) {
      value = (value << 8) | byte;
      bits += 8;

      while (bits >= 5) {
        buffer.write(alphabet[(value >> (bits - 5)) & 0x1F]);
        bits -= 5;
      }
    }

    if (bits > 0) {
      buffer.write(alphabet[(value << (5 - bits)) & 0x1F]);
    }

    return buffer.toString();
  }
}