import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:zero/services/crypto/zero_crypto.dart';

class DASNFile {
  final String cid;
  final String name;
  final int size;
  final String mimeType;
  final int chunkCount;
  final int replicas;
  bool isPinned;
  final DateTime uploadedAt;
  final String contentBase64;
  bool isEncrypted;
  String? encryptionKey;
  List<String> sharedWith;
  int shareCount;
  int downloadCount;

  DASNFile({
    required this.cid,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.chunkCount,
    required this.replicas,
    this.isPinned = true,
    required this.uploadedAt,
    required this.contentBase64,
    this.isEncrypted = false,
    this.encryptionKey,
    this.sharedWith = const [],
    this.shareCount = 0,
    this.downloadCount = 0,
  });
}

class DASNChunk {
  final int chunkIndex;
  final String cid;
  final int size;
  final List<String> nodeIds;

  DASNChunk({
    required this.chunkIndex,
    required this.cid,
    required this.size,
    required this.nodeIds,
  });
}

class DASNStorageService {
  factory DASNStorageService() => _instance;
  DASNStorageService._internal();
  static final DASNStorageService _instance = DASNStorageService._internal();

  static const int _chunkSize = 256 * 1024;
  static const _maxStorageBytes = 100 * 1024 * 1024;

  final Map<String, DASNFile> _files = {};
  final Map<String, List<DASNChunk>> _chunks = {};
  final _random = Random();

  DASNFile storeFile(String name, Uint8List content, String mimeType) {
    final fileCid = ZeroCrypto().sha256Hex(content);

    final chunkCount = (content.length / _chunkSize).ceil();
    final fileChunks = <DASNChunk>[];

    for (var i = 0; i < chunkCount; i++) {
      final start = i * _chunkSize;
      final end = (start + _chunkSize).clamp(0, content.length);
      final chunkData = content.sublist(start, end);
      final chunkCid = ZeroCrypto().sha256Hex(chunkData);

      final nodeCount = _random.nextInt(4) + 2;
      final nodeIds = List.generate(
        nodeCount,
        (_) => 'node-${_random.nextInt(9000) + 1000}',
      );

      fileChunks.add(DASNChunk(
        chunkIndex: i,
        cid: chunkCid,
        size: chunkData.length,
        nodeIds: nodeIds,
      ));
    }

    final replicas = _random.nextInt(4) + 2;
    final contentBase64 = base64Encode(content);

    final file = DASNFile(
      cid: fileCid,
      name: name,
      size: content.length,
      mimeType: mimeType,
      chunkCount: chunkCount,
      replicas: replicas,
      isPinned: true,
      uploadedAt: DateTime.now(),
      contentBase64: contentBase64,
    );

    _files[fileCid] = file;
    _chunks[fileCid] = fileChunks;

    return file;
  }

  DASNFile? retrieveFile(String cid) {
    return _files[cid];
  }

  void deleteFile(String cid) {
    _files.remove(cid);
    _chunks.remove(cid);
  }

  List<DASNFile> getAllFiles() {
    return _files.values.toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  int getTotalSize() {
    return _files.values.fold<int>(0, (sum, f) => sum + f.size);
  }

  int getTotalChunks() {
    return _chunks.values.fold<int>(0, (sum, chunks) => sum + chunks.length);
  }

  int getReplicaCount(String cid) {
    return _files[cid]?.replicas ?? 0;
  }

  DASNFile encryptAndStore(String name, Uint8List content, String mimeType) {
    final file = storeFile(name, content, mimeType);
    file.isEncrypted = true;
    file.encryptionKey = 'aes256-${_random.nextInt(9000) + 1000}-${_random.nextInt(9000) + 1000}';
    return file;
  }

  String generateShareLink(String cid) {
    final file = _files[cid];
    if (file != null) {
      file.shareCount++;
    }
    return 'zero://store/$cid';
  }

  void shareWithUser(String cid, String userDid) {
    final file = _files[cid];
    if (file != null && !file.sharedWith.contains(userDid)) {
      file.sharedWith.add(userDid);
      file.shareCount++;
    }
  }

  List<DASNFile> getSharedWithMe(String userDid) {
    return _files.values.where((f) => f.sharedWith.contains(userDid)).toList();
  }

  Future<DASNFile> uploadWithProgress(String name, Uint8List content, String mimeType, void Function(double) onProgress) async {
    final totalSteps = 10;
    for (var i = 0; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      onProgress(i / totalSteps);
    }
    return storeFile(name, content, mimeType);
  }

  Future<void> downloadWithProgress(String cid, void Function(double) onProgress) async {
    final totalSteps = 10;
    for (var i = 0; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(i / totalSteps);
    }
    final file = _files[cid];
    if (file != null) {
      file.downloadCount++;
    }
  }

  int getEncryptedCount() {
    return _files.values.where((f) => f.isEncrypted).length;
  }

  int getMaxStorageBytes() => _maxStorageBytes;

  void seedDemoFiles() {
    if (_files.isNotEmpty) return;

    final fakePdfContent = _generatePlaceholderBytes(4200000);
    final pdfFile = storeFile('whitepaper.pdf', fakePdfContent, 'PDF');
    pdfFile.isEncrypted = true;
    pdfFile.encryptionKey = 'aes256-8742-1938';
    pdfFile.shareCount = 3;
    pdfFile.sharedWith = ['alice.zero', 'bob.zero'];

    final fakePngContent = _generatePlaceholderBytes(1200000);
    final pngFile = storeFile('logo.png', fakePngContent, 'Image');
    pngFile.shareCount = 1;
    pngFile.sharedWith = ['carol.zero'];

    final fakeZipContent = _generatePlaceholderBytes(8200000);
    final zipFile = storeFile('audit.zip', fakeZipContent, 'Archive');
    zipFile.isEncrypted = true;
    zipFile.encryptionKey = 'aes256-5521-4012';
    zipFile.shareCount = 5;
    zipFile.sharedWith = ['alice.zero', 'bob.zero', 'dave.zero'];
    zipFile.downloadCount = 12;

    final fakeVideoContent = _generatePlaceholderBytes(6400000);
    final videoFile = storeFile('intro.mp4', fakeVideoContent, 'Video');
    videoFile.shareCount = 2;
    videoFile.sharedWith = ['alice.zero'];
    videoFile.downloadCount = 5;
  }

  Uint8List _generatePlaceholderBytes(int size) {
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}