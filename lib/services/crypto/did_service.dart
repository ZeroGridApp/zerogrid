import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'package:zero/services/crypto/zero_crypto.dart';

class DIDService {
  static final DIDService _instance = DIDService._();
  factory DIDService() => _instance;
  DIDService._();

  final _crypto = ZeroCrypto();
  final _didStore = <String, Map<String, dynamic>>{};

  Map<String, dynamic> createDIDDocument(
    String zeroId,
    String identityPubKeyHex,
    String keyAgreementPubKeyHex,
  ) {
    final didId = 'did:zero:$zeroId';

    return {
      '@context': ['https://www.w3.org/ns/did/v1'],
      'id': didId,
      'controller': didId,
      'verificationMethod': [
        {
          'id': '$didId#keys-1',
          'type': 'EcdsaSecp256r1VerificationKey2019',
          'controller': didId,
          'publicKeyHex': identityPubKeyHex,
        }
      ],
      'authentication': ['$didId#keys-1'],
      'assertionMethod': ['$didId#keys-1'],
      'keyAgreement': [
        {
          'id': '$didId#keys-2',
          'type': 'EcdhSecp256r1KeyAgreementKey2019',
          'controller': didId,
          'publicKeyHex': keyAgreementPubKeyHex,
        }
      ],
      'service': [
        {
          'id': '$didId#zero-chat',
          'type': 'ZeroChatService',
          'serviceEndpoint': 'p2p://$zeroId',
        }
      ],
    };
  }

  String signDIDDocument(Map<String, dynamic> didDocument, ECPrivateKey privateKey) {
    final docCopy = Map<String, dynamic>.from(didDocument);
    docCopy.remove('proof');

    final canonicalJson = _canonicalize(docCopy);
    final message = Uint8List.fromList(utf8.encode(canonicalJson));
    final signature = _crypto.sign(privateKey, message);

    final rBytes = _bigIntToFixedBytes(signature.r, 32);
    final sBytes = _bigIntToFixedBytes(signature.s, 32);
    final sigBytes = Uint8List.fromList([...rBytes, ...sBytes]);
    final proofValue = base64Url.encode(sigBytes);

    final didId = didDocument['id'] as String;
    final proof = {
      'type': 'EcdsaSecp256r1Signature2019',
      'created': DateTime.now().toUtc().toIso8601String(),
      'verificationMethod': '$didId#keys-1',
      'proofValue': proofValue,
    };

    didDocument['proof'] = proof;

    final signedJson = const JsonEncoder.withIndent('  ').convert(didDocument);
    _didStore[didId] = Map<String, dynamic>.from(didDocument);

    return signedJson;
  }

  bool verifyDIDDocument(String didJson) {
    try {
      final doc = jsonDecode(didJson) as Map<String, dynamic>;
      final proof = doc['proof'] as Map<String, dynamic>?;
      if (proof == null) return false;

      final docCopy = Map<String, dynamic>.from(doc);
      docCopy.remove('proof');

      final canonicalJson = _canonicalize(docCopy);
      final message = Uint8List.fromList(utf8.encode(canonicalJson));

      final proofValue = proof['proofValue'] as String;
      final sigBytes = base64Url.decode(proofValue);
      if (sigBytes.length != 64) return false;

      final rBytes = Uint8List.fromList(sigBytes.sublist(0, 32));
      final sBytes = Uint8List.fromList(sigBytes.sublist(32, 64));
      final r = _bytesToBigInt(rBytes);
      final s = _bytesToBigInt(sBytes);

      final verificationMethods = doc['verificationMethod'] as List<dynamic>?;
      if (verificationMethods == null || verificationMethods.isEmpty) return false;

      final vm = verificationMethods[0] as Map<String, dynamic>;
      final publicKeyHex = vm['publicKeyHex'] as String?;
      if (publicKeyHex == null || publicKeyHex.length != 128) return false;

      final domain = ECCurve_secp256r1();
      final xHex = publicKeyHex.substring(0, 64);
      final yHex = publicKeyHex.substring(64, 128);
      final x = BigInt.parse(xHex, radix: 16);
      final y = BigInt.parse(yHex, radix: 16);
      final curvePoint = domain.curve.createPoint(x, y);
      final publicKey = ECPublicKey(curvePoint, domain);

      final ecSignature = ECSignature(r, s);
      return _crypto.verify(publicKey, message, ecSignature);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> resolveDID(String didId) async {
    if (_didStore.containsKey(didId)) {
      return Map<String, dynamic>.from(_didStore[didId]!);
    }
    throw Exception('DID not found: $didId');
  }

  void storeDID(Map<String, dynamic> didDocument) {
    final didId = didDocument['id'] as String;
    _didStore[didId] = didDocument;
  }

  bool hasDID(String didId) {
    return _didStore.containsKey(didId);
  }

  String _canonicalize(Map<String, dynamic> map) {
    return jsonEncode(_sortJsonKeys(map));
  }

  dynamic _sortJsonKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final sorted = <String, dynamic>{};
      final keys = value.keys.toList()..sort();
      for (final key in keys) {
        sorted[key] = _sortJsonKeys(value[key]);
      }
      return sorted;
    } else if (value is List) {
      return value.map(_sortJsonKeys).toList();
    }
    return value;
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

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }
}