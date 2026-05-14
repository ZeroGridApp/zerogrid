import 'dart:convert';
import 'dart:typed_data';

import 'package:zero/services/crypto/zero_crypto.dart';

String generateContentId(Uint8List content) {
  final hash = ZeroCrypto().sha256(content);
  final truncated = hash.sublist(0, 16);
  return 'z0${_bytesToHex(truncated)}';
}

String generateContentIdFromString(String content) {
  return generateContentId(utf8.encode(content));
}

bool verifyContentId(String cid, Uint8List content) {
  final expected = generateContentId(content);
  return cid == expected;
}

String formatCid(String cid) {
  if (!isValidCid(cid)) return cid;
  final hex = cid.substring(2);
  final groups = <String>[];
  for (var i = 0; i < hex.length; i += 4) {
    groups.add(hex.substring(i, i + 4));
  }
  return 'z0:${groups.join(':')}';
}

bool isValidCid(String cid) {
  if (!cid.startsWith('z0')) return false;
  if (cid.length != 34) return false;
  final hexPart = cid.substring(2);
  return RegExp(r'^[0-9a-f]{32}$').hasMatch(hexPart);
}

String cidToPinString(String cid) {
  if (cid.length < 10) return cid;
  return '${cid.substring(0, 6)}...${cid.substring(cid.length - 4)}';
}

int estimateStorage(String cid) {
  return 16;
}

String _bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}