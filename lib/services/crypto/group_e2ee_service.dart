import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../crypto/zero_crypto.dart';

class GroupKeyMaterial {
  final String groupId;
  final List<String> memberIds;
  final Map<String, Uint8List> senderKeys;
  final DateTime createdAt;
  DateTime lastRotatedAt;
  int epoch;

  GroupKeyMaterial({
    required this.groupId,
    required this.memberIds,
    required this.senderKeys,
    DateTime? createdAt,
    DateTime? lastRotatedAt,
    this.epoch = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastRotatedAt = lastRotatedAt ?? DateTime.now();

  Uint8List? getSenderKey(String memberId) => senderKeys[memberId];
}

class GroupEncryptedMessage {
  final String groupId;
  final String senderId;
  final int epoch;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final Uint8List mac;

  const GroupEncryptedMessage({
    required this.groupId,
    required this.senderId,
    required this.epoch,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  String serialize() {
    final senderBytes = utf8.encode(senderId);
    final buf = Uint8List(
      32 + 4 + 4 + senderBytes.length + 12 + 16 + ciphertext.length,
    );
    var offset = 0;

    final groupIdBytes = utf8.encode(groupId);
    final paddedGid = Uint8List(32);
    paddedGid.setAll(0, groupIdBytes.take(32).toList());
    buf.setAll(offset, paddedGid);
    offset += 32;

    final writer = buf.buffer.asByteData();
    writer.setUint32(offset, epoch, Endian.big);
    offset += 4;
    writer.setUint32(offset, senderBytes.length, Endian.big);
    offset += 4;

    buf.setAll(offset, senderBytes);
    offset += senderBytes.length;
    buf.setAll(offset, nonce);
    offset += 12;
    buf.setAll(offset, ciphertext);
    offset += ciphertext.length;
    buf.setAll(offset, mac);

    return _bytesToHex(buf);
  }

  static GroupEncryptedMessage deserialize(String hex) {
    final buf = _hexToBytes(hex);
    var offset = 0;

    final groupId = utf8.decode(buf.sublist(offset, offset + 32)).replaceAll('\x00', '');
    offset += 32;

    final reader = buf.buffer.asByteData();
    final epoch = reader.getUint32(offset, Endian.big);
    offset += 4;
    final senderLen = reader.getUint32(offset, Endian.big);
    offset += 4;

    final senderId = utf8.decode(buf.sublist(offset, offset + senderLen));
    offset += senderLen;
    final nonce = buf.sublist(offset, offset + 12);
    offset += 12;
    final ciphertext = buf.sublist(offset, buf.length - 16);
    final mac = buf.sublist(buf.length - 16, buf.length);

    return GroupEncryptedMessage(
      groupId: groupId,
      senderId: senderId,
      epoch: epoch,
      nonce: nonce,
      ciphertext: ciphertext,
      mac: mac,
    );
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}

class GroupE2EEService {
  factory GroupE2EEService() => _instance;
  GroupE2EEService._internal();
  static final GroupE2EEService _instance = GroupE2EEService._internal();

  final _crypto = ZeroCrypto();
  final _random = Random.secure();

  final Map<String, GroupKeyMaterial> _groups = {};

  static const _senderKeyLength = 32;
  static const _nonceLength = 12;

  GroupKeyMaterial createGroup(String groupId, List<String> memberIds) {
    final senderKeys = <String, Uint8List>{};
    for (final memberId in memberIds) {
      senderKeys[memberId] = _crypto.randomBytes(_senderKeyLength);
    }

    final material = GroupKeyMaterial(
      groupId: groupId,
      memberIds: List.from(memberIds),
      senderKeys: senderKeys,
    );
    _groups[groupId] = material;
    return material;
  }

  GroupKeyMaterial? getGroup(String groupId) => _groups[groupId];

  String encryptGroupMessage(String groupId, String senderId, String plaintext) {
    final material = _groups[groupId];
    if (material == null) {
      throw StateError('Group $groupId not found');
    }

    final senderKey = material.getSenderKey(senderId);
    if (senderKey == null) {
      throw StateError('Sender $senderId not in group $groupId');
    }

    final nonce = _crypto.randomBytes(_nonceLength);
    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final result = _crypto.encryptAEAD(senderKey, nonce, plainBytes);

    final message = GroupEncryptedMessage(
      groupId: groupId,
      senderId: senderId,
      epoch: material.epoch,
      nonce: nonce,
      ciphertext: result.ciphertext,
      mac: result.mac,
    );

    return message.serialize();
  }

  String decryptGroupMessage(String groupId, String encrypted) {
    final material = _groups[groupId];
    if (material == null) {
      throw StateError('Group $groupId not found');
    }

    final message = GroupEncryptedMessage.deserialize(encrypted);

    final senderKey = material.getSenderKey(message.senderId);
    if (senderKey == null) {
      throw StateError('Sender ${message.senderId} not in group $groupId');
    }

    if (message.epoch != material.epoch) {
      throw StateError(
        'Epoch mismatch: message=${message.epoch}, local=${material.epoch}',
      );
    }

    final plainBytes = _crypto.decryptAEAD(
      senderKey,
      message.nonce,
      message.ciphertext,
      message.mac,
    );

    return utf8.decode(plainBytes);
  }

  void addMember(String groupId, String newMemberId) {
    final material = _groups[groupId];
    if (material == null) {
      throw StateError('Group $groupId not found');
    }

    if (material.memberIds.contains(newMemberId)) return;

    material.memberIds.add(newMemberId);
    material.senderKeys[newMemberId] = _crypto.randomBytes(_senderKeyLength);

    material.epoch++;
    material.lastRotatedAt = DateTime.now();
  }

  void removeMember(String groupId, String memberId) {
    final material = _groups[groupId];
    if (material == null) {
      throw StateError('Group $groupId not found');
    }

    if (!material.memberIds.contains(memberId)) return;

    material.memberIds.remove(memberId);
    material.senderKeys.remove(memberId);

    _rotateAllKeys(groupId);
  }

  void rotateKeys(String groupId) {
    _rotateAllKeys(groupId);
  }

  void _rotateAllKeys(String groupId) {
    final material = _groups[groupId];
    if (material == null) return;

    for (final memberId in material.memberIds) {
      material.senderKeys[memberId] = _crypto.randomBytes(_senderKeyLength);
    }

    material.epoch++;
    material.lastRotatedAt = DateTime.now();
  }

  Set<String> getMemberIds(String groupId) {
    return Set.from(_groups[groupId]?.memberIds ?? []);
  }

  int getEpoch(String groupId) {
    return _groups[groupId]?.epoch ?? -1;
  }

  Uint8List getSenderKeyForExport(String groupId, String memberId) {
    final material = _groups[groupId];
    if (material == null) return Uint8List(0);
    return material.getSenderKey(memberId) ?? Uint8List(0);
  }

  void seedDemoGroup(String groupId) {
    addMember(groupId, 'alice');
    addMember(groupId, 'bob');
  }
}