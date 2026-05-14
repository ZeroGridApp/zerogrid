import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'bip39_wordlist.dart';

class ZeroCrypto {
  static final ZeroCrypto _instance = ZeroCrypto._();
  factory ZeroCrypto() => _instance;
  ZeroCrypto._();

  final _random = Random.secure();

  // ── BIP39 Mnemonic ──────────────────────────────────────────────

  String generateMnemonic({int strength = 128}) {
    assert(strength == 128 || strength == 256, 'Strength must be 128 or 256 bits');
    final entropy = _randomBytes(strength ~/ 8);
    return _entropyToMnemonic(entropy);
  }

  String _entropyToMnemonic(Uint8List entropy) {
    final ent = entropy.length * 8;
    final cs = ent ~/ 32;
    final hash = SHA256Digest().process(entropy);
    final hashBits = _bytesToBits(Uint8List.fromList([hash[0]]));
    final checksumBits = hashBits.sublist(0, cs);

    final entropyBits = _bytesToBits(entropy);
    final allBits = [...entropyBits, ...checksumBits];

    final words = <String>[];
    for (var i = 0; i < allBits.length; i += 11) {
      final chunk = allBits.sublist(i, i + 11);
      final index = _bitsToInt(chunk);
      words.add(Bip39Wordlist.words[index]);
    }
    return words.join(' ');
  }

  bool validateMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) return false;

    final indices = <int>[];
    for (final w in words) {
      final idx = Bip39Wordlist.indexOf(w);
      if (idx == null) return false;
      indices.add(idx);
    }

    final ent = words.length * 11 * 32 ~/ 33;
    final cs = ent ~/ 32;
    final totalBits = words.length * 11;

    final allBits = <int>[];
    for (final idx in indices) {
      allBits.addAll(_intToBits(idx, 11));
    }

    final entropyBits = allBits.sublist(0, ent);
    final checksumProvided = allBits.sublist(ent, totalBits);

    final entropy = _bitsToBytes(entropyBits);

    final hash = SHA256Digest().process(entropy);
    final hashBits = _bytesToBits(Uint8List.fromList([hash[0]]));
    final checksumExpected = hashBits.sublist(0, cs);

    for (var i = 0; i < cs; i++) {
      if (checksumProvided[i] != checksumExpected[i]) return false;
    }
    return true;
  }

  // ── Seed derivation ─────────────────────────────────────────────

  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    final salt = 'mnemonic$passphrase';
    final keyDerivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    keyDerivator.init(Pbkdf2Parameters(
      Uint8List.fromList(salt.codeUnits),
      2048,
      64,
    ));
    return keyDerivator.process(utf8.encode(mnemonic) as Uint8List);
  }

  // ── P-256 ECDSA Identity Keys ──────────────────────────────────

  IdentityKeyPair generateIdentityKeys(Uint8List seed) {
    final privBytes = _hkdfRaw(seed, utf8.encode('zero-identity'), null, 32);
    final domain = ECCurve_secp256r1();
    final d = _bytesToBigInt(privBytes) % domain.n!;
    final privKey = ECPrivateKey(d, domain);
    final Q = domain.G! * d;
    final pubKey = ECPublicKey(Q!, domain);
    return IdentityKeyPair(
      privateKeyHex: _bytesToHex(privBytes),
      publicKeyHex: _pointToHex(Q),
      privateKey: privKey,
      publicKey: pubKey,
    );
  }

  // ── ECDSA Sign / Verify ────────────────────────────────────────

  ECSignature sign(ECPrivateKey privateKey, Uint8List message) {
    final signer = ECDSASigner(SHA256Digest(), null);
    final random = FortunaRandom();
    random.seed(KeyParameter(_randomBytes(32)));
    signer.init(true, ParametersWithRandom(PrivateKeyParameter<ECPrivateKey>(privateKey), random));
    return signer.generateSignature(message) as ECSignature;
  }

  bool verify(ECPublicKey publicKey, Uint8List message, ECSignature signature) {
    final signer = ECDSASigner(SHA256Digest(), null);
    signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));
    return signer.verifySignature(message, signature);
  }

  // ── Pre-Key Generation ─────────────────────────────────────────

  ECPreKeyPair generatePreKeyPair(Uint8List seed, int index) {
    final domain = ECCurve_secp256r1();
    final indexBytes = Uint8List(4)..buffer.asByteData().setUint32(0, index, Endian.big);
    final privBytes = _hkdfRaw(seed, indexBytes, utf8.encode('zero-prek'), 32);
    final d = _bytesToBigInt(privBytes) % domain.n!;
    final privKey = ECPrivateKey(d, domain);
    final Q = domain.G! * d;
    final pubKey = ECPublicKey(Q!, domain);
    return ECPreKeyPair(
      privateKey: privKey,
      publicKey: pubKey,
      publicKeyHex: _pointToHex(Q),
      index: index,
    );
  }

  // ── ECDH Key Agreement ─────────────────────────────────────────

  Uint8List computeSharedSecret(ECPrivateKey privateKey, ECPublicKey publicKey) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final secret = agreement.calculateAgreement(publicKey);
    final fieldSize = agreement.getFieldSize();
    final bytes = Uint8List(fieldSize);
    _bigIntToBytes(secret, bytes);
    return bytes;
  }

  // ── ChaCha20-Poly1305 AEAD ──────────────────────────────────────

  EncryptResult encryptAEAD(Uint8List key, Uint8List nonce, Uint8List plaintext, {Uint8List? aad}) {
    final cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, nonce, aad ?? Uint8List(0)));

    final totalOut = cipher.getOutputSize(plaintext.length);
    final out = Uint8List(totalOut);
    final pLen = cipher.processBytes(plaintext, 0, plaintext.length, out, 0);
    final fLen = cipher.doFinal(out, pLen);

    const macLen = 16;
    final combinedLen = pLen + fLen;
    return EncryptResult(
      ciphertext: out.sublist(0, combinedLen - macLen),
      mac: out.sublist(combinedLen - macLen, combinedLen),
    );
  }

  Uint8List decryptAEAD(Uint8List key, Uint8List nonce, Uint8List ciphertext, Uint8List mac, {Uint8List? aad}) {
    final cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    cipher.init(false, AEADParameters(KeyParameter(key), 128, nonce, aad ?? Uint8List(0)));

    final combined = Uint8List.fromList([...ciphertext, ...mac]);
    final totalOut = cipher.getOutputSize(combined.length);
    final out = Uint8List(totalOut);
    final pLen = cipher.processBytes(combined, 0, combined.length, out, 0);
    final fLen = cipher.doFinal(out, pLen);

    return Uint8List.sublistView(out, 0, pLen + fLen);
  }

  // ── SHA256 ──────────────────────────────────────────────────────

  Uint8List sha256(Uint8List data) {
    return SHA256Digest().process(data);
  }

  String sha256Hex(Uint8List data) {
    return _bytesToHex(sha256(data));
  }

  // ── HKDF ────────────────────────────────────────────────────────

  Uint8List hkdf(Uint8List salt, Uint8List ikm, Uint8List? info, int length) {
    return _hkdfRaw(salt, ikm, info, length);
  }

  // ── Random ──────────────────────────────────────────────────────

  Uint8List randomBytes(int length) {
    return _randomBytes(length);
  }

  // ── Internal helpers ────────────────────────────────────────────

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Uint8List _hkdfRaw(Uint8List salt, Uint8List ikm, Uint8List? info, int length) {
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    hkdf.init(HkdfParameters(ikm, length, info ?? Uint8List(0), salt));
    return hkdf.process(Uint8List(0));
  }

  List<int> _bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (final b in bytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    return bits;
  }

  Uint8List _bitsToBytes(List<int> bits) {
    final bytes = Uint8List(bits.length ~/ 8);
    for (var i = 0; i < bytes.length; i++) {
      var val = 0;
      for (var j = 0; j < 8; j++) {
        val = (val << 1) | bits[i * 8 + j];
      }
      bytes[i] = val;
    }
    return bytes;
  }

  List<int> _intToBits(int val, int bitCount) {
    final bits = <int>[];
    for (var i = bitCount - 1; i >= 0; i--) {
      bits.add((val >> i) & 1);
    }
    return bits;
  }

  int _bitsToInt(List<int> bits) {
    var val = 0;
    for (final b in bits) {
      val = (val << 1) | b;
    }
    return val;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  void _bigIntToBytes(BigInt value, Uint8List output) {
    var v = value;
    for (var i = output.length - 1; i >= 0; i--) {
      output[i] = (v & BigInt.from(0xFF)).toInt();
      v = v >> 8;
    }
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _pointToHex(ECPoint point) {
    final xBytes = _bigIntToFixedBytes(point.x!.toBigInteger()!, 32);
    final yBytes = _bigIntToFixedBytes(point.y!.toBigInteger()!, 32);
    return _bytesToHex(xBytes) + _bytesToHex(yBytes);
  }

  Uint8List _bigIntToFixedBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var v = value;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (v & BigInt.from(0xFF)).toInt();
      v = v >> 8;
    }
    return bytes;
  }
}

// ── Data classes ─────────────────────────────────────────────────

class IdentityKeyPair {
  final String privateKeyHex;
  final String publicKeyHex;
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;

  const IdentityKeyPair({
    required this.privateKeyHex,
    required this.publicKeyHex,
    required this.privateKey,
    required this.publicKey,
  });
}

class ECPreKeyPair {
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;
  final String publicKeyHex;
  final int index;

  const ECPreKeyPair({
    required this.privateKey,
    required this.publicKey,
    required this.publicKeyHex,
    required this.index,
  });
}

class EncryptResult {
  final Uint8List ciphertext;
  final Uint8List mac;

  const EncryptResult({required this.ciphertext, required this.mac});
}