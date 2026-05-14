import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/storage/dasn_storage_service.dart';
import '../../widgets/zero_card.dart';

class DASNUploadScreen extends StatefulWidget {
  const DASNUploadScreen({super.key});

  @override
  State<DASNUploadScreen> createState() => _DASNUploadScreenState();
}

class _DASNUploadScreenState extends State<DASNUploadScreen> {
  final DASNStorageService _storage = DASNStorageService();
  List<DASNFile> _files = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _storage.seedDemoFiles();
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _files = _storage.getAllFiles();
    });
  }

  int get _totalSize => _storage.getTotalSize();
  double get _usagePercent => (_totalSize / _storage.getMaxStorageBytes()).clamp(0.0, 1.0);
  int get _totalChunks => _storage.getTotalChunks();
  int get _encryptedCount => _storage.getEncryptedCount();

  Color _progressColor(double percent) {
    if (percent < 0.5) return context.zSuccess;
    if (percent < 0.8) return context.zWarning;
    return context.zError;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _loadFiles();
    });
  }

  void _togglePin(String cid) {
    setState(() {
      final file = _storage.retrieveFile(cid);
      if (file != null) {
        file.isPinned = !file.isPinned;
        _loadFiles();
      }
    });
  }

  void _showEnhancedUploadSheet() {
    final nameController = TextEditingController(text: 'untitled.txt');
    var mimeType = 'Document';
    var encryptBeforeUpload = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return _EnhancedUploadSheet(
            nameController: nameController,
            mimeType: mimeType,
            encryptBeforeUpload: encryptBeforeUpload,
            onMimeChanged: (v) => setSheetState(() => mimeType = v),
            onEncryptChanged: (v) => setSheetState(() => encryptBeforeUpload = v),
            onUpload: () {
              final name = nameController.text.trim().isEmpty
                  ? 'untitled.txt'
                  : nameController.text.trim();
              Navigator.of(ctx).pop(_UploadParams(
                name: name,
                mime: mimeType,
                encrypt: encryptBeforeUpload,
              ));
            },
          );
        },
      ),
    ).then((result) {
      if (result != null && result is _UploadParams) {
        _performUploadWithProgress(result.name, result.mime, result.encrypt);
      }
    });
  }

  Future<void> _performUploadWithProgress(String name, String mime, bool encrypt) async {
    final isZh = ZeroTheme.isZh(context);
    final content = _generatePlaceholderBytes(Random().nextInt(4000000) + 500000);

    final result = await showDialog<_UploadResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UploadProgressDialog(
        fileName: name,
        onComplete: (cid) => _UploadResult(cid: cid, name: name, size: content.length, isEncrypted: encrypt),
      ),
    );

    if (!mounted) return;

    DASNFile file;
    if (encrypt) {
      file = _storage.encryptAndStore(name, content, mime);
    } else {
      file = _storage.storeFile(name, content, mime);
    }
    _loadFiles();

    if (!mounted) return;
    _showUploadSuccessSheet(file);
  }

  void _showUploadSuccessSheet(DASNFile file) {
    final isZh = ZeroTheme.isZh(context);
    String? shareLink;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(ZeroSpacing.cardRadius)),
            ),
            padding: EdgeInsets.only(
              left: ZeroSpacing.screenHorizontal,
              right: ZeroSpacing.screenHorizontal,
              top: ZeroSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + ZeroSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: context.zTextDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.xl),
                Icon(Icons.check_circle, size: 56, color: context.zSuccess),
                const SizedBox(height: ZeroSpacing.md),
                Text(
                  isZh ? '上传成功！' : 'Upload Successful!',
                  style: ZeroTypography.headline(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ZeroSpacing.sm),
                Text(
                  file.name,
                  style: ZeroTypography.body(context).copyWith(color: context.zAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ZeroSpacing.lg),
                ZeroCard(
                  padding: EdgeInsets.all(ZeroSpacing.md),
                  borderRadius: ZeroSpacing.cardRadiusSm,
                  child: Column(
                    children: [
                      _SuccessRow(label: 'CID', value: _truncateCid(file.cid)),
                      _SuccessRow(label: isZh ? '大小' : 'Size', value: _formatSize(file.size)),
                      _SuccessRow(label: isZh ? '加密' : 'Encrypted', value: file.isEncrypted ? (isZh ? '是' : 'Yes') : (isZh ? '否' : 'No')),
                      _SuccessRow(label: isZh ? '分块' : 'Chunks', value: '${file.chunkCount}'),
                    ],
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                if (shareLink != null) ...[
                  ZeroCard(
                    padding: EdgeInsets.all(ZeroSpacing.md),
                    borderRadius: ZeroSpacing.cardRadiusSm,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, size: 14, color: context.zCeladon),
                            const SizedBox(width: ZeroSpacing.sm),
                            Text(
                              isZh ? '分享链接' : 'Share Link',
                              style: ZeroTypography.caption(context).copyWith(letterSpacing: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(ZeroSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.zFrostWhite,
                            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shareLink!,
                                  style: ZeroTypography.monoSmall(context).copyWith(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Icon(Icons.copy, size: 16, color: context.zAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ZeroSpacing.lg),
                ],
                GestureDetector(
                  onTap: () {
                    if (shareLink != null) {
                      Navigator.of(ctx).pop();
                      return;
                    }
                    setSheetState(() {
                      shareLink = _storage.generateShareLink(file.cid);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      gradient: context.zAccentGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      shareLink != null
                          ? (isZh ? '完成' : 'Done')
                          : (isZh ? '生成分享链接' : 'Generate Share Link'),
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600,
                        letterSpacing: 0.5, color: context.zBg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _truncateCid(String cid) {
    if (cid.length <= 16) return cid;
    return '${cid.substring(0, 12)}...${cid.substring(cid.length - 8)}';
  }

  Future<void> _confirmDelete(DASNFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius)),
        title: Text('Delete ${file.name}', style: ZeroTypography.title(context)),
        content: Text('Are you sure you want to delete this file? It will be removed from all storage nodes.',
            style: ZeroTypography.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel',
                style: TextStyle(color: context.zTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: context.zError, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _storage.deleteFile(file.cid);
      _loadFiles();
    }
  }

  Uint8List _generatePlaceholderBytes(int size) {
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = Random().nextInt(256);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.dasnTitle ?? 'DASN Storage')),
      body: Column(
        children: [
          _buildStorageBar(),
          _buildStatsCard(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: context.zAccent,
              backgroundColor: context.zSurfaceRaised,
              child: _files.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Text(
                            l10n?.dasnNoFiles ?? 'No files stored yet',
                            style: ZeroTypography.body(context),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                      itemCount: _files.length,
                      itemBuilder: (_, i) => _FileTile(
                        file: _files[i],
                        onTogglePin: () => _togglePin(_files[i].cid),
                        onLongPress: () => _confirmDelete(_files[i]),
                      ),
                    ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEnhancedUploadSheet,
        backgroundColor: context.zAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildStatsCard() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
      color: context.zSurface,
      child: Row(
        children: [
          Expanded(child: _StatItem(icon: Icons.inventory_2_outlined, label: isZh ? '总文件' : 'Files', value: '${_files.length}')),
          Expanded(child: _StatItem(icon: Icons.storage_outlined, label: isZh ? '总大小' : 'Size', value: _formatSize(_totalSize))),
          Expanded(child: _StatItem(icon: Icons.lock_outline, label: isZh ? '已加密' : 'Encrypted', value: '$_encryptedCount')),
          Expanded(child: _StatItem(icon: Icons.grid_view_outlined, label: isZh ? '总分块' : 'Chunks', value: '$_totalChunks')),
        ],
      ),
    );
  }

  Widget _buildStorageBar() {
    final usagePercent = _usagePercent;
    final barColor = _progressColor(usagePercent);
    final usageMB = _totalSize / (1024 * 1024);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
      color: context.zSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Usage', style: ZeroTypography.caption(context).copyWith(letterSpacing: 2)),
              Text('${usageMB.toStringAsFixed(1)} MB / 100 MB',
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent)),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  child: LinearProgressIndicator(
                    value: usagePercent,
                    backgroundColor: context.zFrostWhiteStrong,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.md),
              Text('${(usagePercent * 100).toStringAsFixed(0)}%',
                  style: ZeroTypography.mono(context).copyWith(color: barColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    final totalFileCount = _files.length;
    final totalSizeStr = _formatSize(_totalSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(top: BorderSide(color: context.zFrostWhiteStrong, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _InfoItem(label: l10n?.dasnObjects ?? 'Objects', value: '$totalFileCount'),
            _InfoItem(label: l10n?.dasnSize ?? 'Size', value: totalSizeStr),
            _InfoItem(label: 'Chunks', value: '$_totalChunks'),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _UploadParams {
  final String name;
  final String mime;
  final bool encrypt;

  _UploadParams({required this.name, required this.mime, required this.encrypt});
}

class _UploadResult {
  final String cid;
  final String name;
  final int size;
  final bool isEncrypted;

  _UploadResult({required this.cid, required this.name, required this.size, required this.isEncrypted});
}

class _EnhancedUploadSheet extends StatefulWidget {
  final TextEditingController nameController;
  final String mimeType;
  final bool encryptBeforeUpload;
  final ValueChanged<String> onMimeChanged;
  final ValueChanged<bool> onEncryptChanged;
  final VoidCallback onUpload;

  const _EnhancedUploadSheet({
    required this.nameController,
    required this.mimeType,
    required this.encryptBeforeUpload,
    required this.onMimeChanged,
    required this.onEncryptChanged,
    required this.onUpload,
  });

  @override
  State<_EnhancedUploadSheet> createState() => _EnhancedUploadSheetState();
}

class _EnhancedUploadSheetState extends State<_EnhancedUploadSheet> {
  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ZeroSpacing.cardRadius)),
      ),
      padding: EdgeInsets.only(
        left: ZeroSpacing.screenHorizontal,
        right: ZeroSpacing.screenHorizontal,
        top: ZeroSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ZeroSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.zTextDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '上传文件到 DASN' : 'Upload File to DASN',
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(isZh ? '文件名' : 'File Name', style: ZeroTypography.caption(context).copyWith(letterSpacing: 2)),
          const SizedBox(height: ZeroSpacing.sm),
          TextField(
            controller: widget.nameController,
            style: ZeroTypography.bodyBold(context),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.zFrostWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(isZh ? '文件类型' : 'File Type', style: ZeroTypography.caption(context).copyWith(letterSpacing: 2)),
          const SizedBox(height: ZeroSpacing.sm),
          Wrap(
            spacing: ZeroSpacing.sm,
            runSpacing: ZeroSpacing.sm,
            children: ['Document', 'Image', 'Video', 'Archive'].map((mime) {
              final selected = widget.mimeType == mime;
              IconData icon;
              switch (mime) {
                case 'Document':
                  icon = Icons.description;
                  break;
                case 'Image':
                  icon = Icons.image;
                  break;
                case 'Video':
                  icon = Icons.videocam;
                  break;
                case 'Archive':
                  icon = Icons.archive;
                  break;
                default:
                  icon = Icons.insert_drive_file;
              }
              return GestureDetector(
                onTap: () => widget.onMimeChanged(mime),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? context.zAccent.withOpacity(0.15) : context.zFrostWhite,
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    border: Border.all(
                      color: selected ? context.zAccent.withOpacity(0.4) : context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: selected ? context.zAccent : context.zTextSecondary),
                      const SizedBox(width: 6),
                      Text(mime,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? context.zAccent : context.zTextSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          ZeroCard(
            padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.xs),
            borderRadius: ZeroSpacing.cardRadiusSm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.encryptBeforeUpload ? Icons.lock : Icons.lock_open,
                      size: 18,
                      color: widget.encryptBeforeUpload ? context.zSuccess : context.zTextDisabled,
                    ),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      isZh ? '上传前加密' : 'Encrypt before upload',
                      style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                    ),
                  ],
                ),
                Switch(
                  value: widget.encryptBeforeUpload,
                  onChanged: widget.onEncryptChanged,
                  activeColor: context.zSuccess,
                  activeTrackColor: context.zSuccess.withOpacity(0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.xl),
          GestureDetector(
            onTap: widget.onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                gradient: context.zAccentGradient,
              ),
              alignment: Alignment.center,
              child: Text(
                isZh ? '上传到 DASN' : 'Upload to DASN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: context.zBg,
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
        ],
      ),
    );
  }
}

class _UploadProgressDialog extends StatefulWidget {
  final String fileName;
  final void Function(String cid) onComplete;

  const _UploadProgressDialog({
    required this.fileName,
    required this.onComplete,
  });

  @override
  State<_UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<_UploadProgressDialog> {
  double _progress = 0;
  String _stage = '';

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  Future<void> _simulateProgress() async {
    final isZh = ZeroTheme.isZh(context);
    final stages = [
      isZh ? '分块处理...' : 'Chunking...',
      isZh ? '计算 CID...' : 'Computing CID...',
      isZh ? '分配到节点...' : 'Distributing to nodes...',
      isZh ? '复制到副本...' : 'Replicating...',
      isZh ? '完成' : 'Complete',
    ];
    final totalSteps = 20;
    for (var i = 0; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 125));
      if (!mounted) return;
      setState(() {
        _progress = i / totalSteps;
        if (_progress < 0.4) {
          _stage = stages[0];
        } else if (_progress < 0.6) {
          _stage = stages[1];
        } else if (_progress < 0.8) {
          _stage = stages[2];
        } else if (_progress < 1.0) {
          _stage = stages[3];
        } else {
          _stage = stages[4];
        }
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    widget.onComplete('');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Dialog(
      backgroundColor: context.zSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(ZeroSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_progress < 1.0)
              SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
                  backgroundColor: context.zFrostWhiteStrong,
                  strokeWidth: 4,
                ),
              )
            else
              Icon(Icons.check_circle, size: 48, color: context.zSuccess),
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              widget.fileName,
              style: ZeroTypography.bodyBold(context),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              _stage,
              style: ZeroTypography.body(context).copyWith(
                color: _progress >= 1.0 ? context.zSuccess : context.zTextSecondary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: context.zFrostWhiteStrong,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress >= 1.0 ? context.zSuccess : context.zAccent,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: ZeroTypography.monoSmall(context).copyWith(
                color: _progress >= 1.0 ? context.zSuccess : context.zAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final DASNFile file;
  final VoidCallback onTogglePin;
  final VoidCallback onLongPress;

  const _FileTile({
    required this.file,
    required this.onTogglePin,
    required this.onLongPress,
  });

  IconData _mimeIcon(String mimeType) {
    switch (mimeType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Image':
        return Icons.image;
      case 'Archive':
        return Icons.archive;
      case 'Video':
        return Icons.videocam;
      case 'Text':
        return Icons.description;
      case 'Document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _truncateCid(String cid) {
    if (cid.length <= 16) return cid;
    return '${cid.substring(0, 8)}...${cid.substring(cid.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: const EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.zCeladon.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_mimeIcon(file.mimeType), size: 20, color: context.zCeladon),
                ),
                const SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(file.name,
                                style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Icon(
                            file.isEncrypted ? Icons.lock : Icons.lock_open,
                            size: 12,
                            color: file.isEncrypted ? context.zSuccess : context.zTextDisabled,
                          ),
                          if (file.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.push_pin, size: 12, color: context.zAccent.withOpacity(0.7)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_truncateCid(file.cid), style: ZeroTypography.monoSmall(context)),
                    ],
                  ),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatSize(file.size),
                        style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_copy, size: 10, color: context.zTextTertiary.withOpacity(0.6)),
                        const SizedBox(width: 2),
                        Text('${file.replicas}',
                            style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextTertiary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: ZeroSpacing.sm),
                GestureDetector(
                  onTap: onTogglePin,
                  child: Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: file.isPinned
                          ? context.zAccent.withOpacity(0.15)
                          : context.zFrostWhite,
                      border: Border.all(
                        color: file.isPinned
                            ? context.zAccent.withOpacity(0.3)
                            : context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      file.isPinned
                          ? (l10n?.dasnPin ?? 'Pin')
                          : (l10n?.dasnUnpin ?? 'Unpin'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: file.isPinned ? context.zAccent : context.zTextTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: ZeroTypography.mono(context).copyWith(
                color: context.zAccent, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.zTextTertiary),
        const SizedBox(height: 4),
        Text(value,
            style: ZeroTypography.mono(context).copyWith(
                color: context.zAccent, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZeroTypography.caption(context)),
          Flexible(
            child: Text(
              value,
              style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}