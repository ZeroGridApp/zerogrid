import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/storage/dasn_storage_service.dart';
import '../../widgets/zero_card.dart';
import 'dasn_upload_screen.dart';

class DASNScreen extends StatefulWidget {
  const DASNScreen({super.key});

  @override
  State<DASNScreen> createState() => _DASNScreenState();
}

class _DASNScreenState extends State<DASNScreen> {
  final DASNStorageService _storage = DASNStorageService();
  List<DASNFile> _files = [];
  List<DASNFile> _sharedFiles = [];
  bool _ipfsGatewayOnline = true;
  bool _isRefreshing = false;
  bool _sharedSectionExpanded = true;
  final String _myDid = 'alice.zero';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _files = _storage.getAllFiles();
      _sharedFiles = _storage.getSharedWithMe(_myDid);
    });
  }

  int get _totalSize => _storage.getTotalSize();
  double get _usagePercent => (_totalSize / _storage.getMaxStorageBytes()).clamp(0.0, 1.0);
  int get _pinnedCount => _files.where((f) => f.isPinned).length;
  int get _totalReplicas => _files.fold<int>(0, (s, f) => s + f.replicas);

  Color _healthColor(double percent) {
    if (percent < 0.5) return context.zSuccess;
    if (percent < 0.8) return context.zWarning;
    return context.zError;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _ipfsGatewayOnline = !_ipfsGatewayOnline;
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

  void _showDetailSheet(DASNFile file) {
    final isZh = ZeroTheme.isZh(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailSheet(
        file: file,
        storage: _storage,
        onTogglePin: () => _togglePin(file.cid),
        onToggleEncryption: () {
          setState(() {
            file.isEncrypted = !file.isEncrypted;
            if (file.isEncrypted && file.encryptionKey == null) {
              file.encryptionKey = 'aes256-${Random().nextInt(9000) + 1000}-${Random().nextInt(9000) + 1000}';
            }
            if (!file.isEncrypted) {
              file.encryptionKey = null;
            }
            _loadFiles();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dasnTitle)),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: context.zAccent,
        backgroundColor: context.zSurfaceRaised,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildGaugeCard(),
            const SizedBox(height: ZeroSpacing.md),
            _buildHealthIndicator(),
            const SizedBox(height: ZeroSpacing.md),
            _buildStatsRow(),
            if (_sharedFiles.isNotEmpty) ...[
              const SizedBox(height: ZeroSpacing.lg),
              _buildSharedSection(),
            ],
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              isZh ? '存储对象' : 'STORED OBJECTS',
              style: ZeroTypography.caption(context).copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            ...List.generate(
              _files.length,
              (i) => _ObjectTile(
                file: _files[i],
                onTap: () => _showDetailSheet(_files[i]),
                onTogglePin: () => _togglePin(_files[i].cid),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const DASNUploadScreen())),
        backgroundColor: context.zAccent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildGaugeCard() {
    final l10n = AppLocalizations.of(context);
    final usageMB = _totalSize / (1024 * 1024);
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.dasnUsage, style: ZeroTypography.caption(context).copyWith(letterSpacing: 2)),
              Text('${usageMB.toStringAsFixed(1)} MB / 100 MB',
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent)),
            ],
          ),
          SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _GaugePainter(
                percentage: _usagePercent,
                accentColor: context.zAccent,
                trackColor: context.zFrostWhiteStrong,
                textColor: context.zTextPrimary,
                celadonColor: context.zCeladon,
                tertiaryTextColor: context.zTextTertiary,
                usedLabel: l10n.dasnUsed,
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text('Content-addressed, encrypted, distributed across 5 supernodes',
              style: ZeroTypography.caption(context)),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator() {
    final isZh = ZeroTheme.isZh(context);
    final healthColor = _healthColor(_usagePercent);
    String label;
    String subtitle;
    if (_usagePercent < 0.5) {
      label = isZh ? '存储健康度：良好' : 'Storage Health: Good';
      subtitle = isZh ? '剩余空间充足' : 'Plenty of space remaining';
    } else if (_usagePercent < 0.8) {
      label = isZh ? '存储健康度：注意' : 'Storage Health: Warning';
      subtitle = isZh ? '建议清理或扩展存储' : 'Consider cleanup or expansion';
    } else {
      label = isZh ? '存储健康度：紧张' : 'Storage Health: Critical';
      subtitle = isZh ? '存储空间即将用完' : 'Storage nearly full';
    }
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: healthColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.sm),
                  Text(label, style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13)),
                ],
              ),
              Text('${(_usagePercent * 100).toStringAsFixed(1)}%',
                  style: ZeroTypography.monoSmall(context).copyWith(color: healthColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
            child: LinearProgressIndicator(
              value: _usagePercent,
              backgroundColor: context.zFrostWhiteStrong,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(subtitle, style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSharedSection() {
    final isZh = ZeroTheme.isZh(context);
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _sharedSectionExpanded = !_sharedSectionExpanded),
          child: ZeroCard(
            padding: EdgeInsets.all(ZeroSpacing.md),
            borderRadius: ZeroSpacing.cardRadiusSm,
            child: Row(
              children: [
                Icon(Icons.share, size: 16, color: context.zCeladon),
                const SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Text(
                    isZh ? '分享给我的' : 'Shared with me',
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13, color: context.zCeladon),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.zCeladon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_sharedFiles.length}',
                      style: ZeroTypography.monoSmall(context).copyWith(color: context.zCeladon, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Icon(
                  _sharedSectionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: context.zTextTertiary,
                ),
              ],
            ),
          ),
        ),
        if (_sharedSectionExpanded) ...[
          const SizedBox(height: ZeroSpacing.sm),
          ...List.generate(
            _sharedFiles.length,
            (i) => _ObjectTile(
              file: _sharedFiles[i],
              onTap: () => _showDetailSheet(_sharedFiles[i]),
              onTogglePin: () => _togglePin(_sharedFiles[i].cid),
              isShared: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _StatCard(label: l10n.dasnObjects, value: '${_files.length}', icon: Icons.inventory_2_outlined, color: context.zAccent)),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(child: _StatCard(label: l10n.dasnReplicas, value: '$_totalReplicas', icon: Icons.copy_outlined, color: context.zCeladon)),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(child: _StatCard(
          label: l10n.dasnIPFS,
          value: _ipfsGatewayOnline ? l10n.dasnIPFSOnline : l10n.dasnIPFSOffline,
          icon: _ipfsGatewayOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: _ipfsGatewayOnline ? context.zSuccess : context.zError,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.6)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 16,
              fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ObjectTile extends StatelessWidget {
  final DASNFile file;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final bool isShared;

  const _ObjectTile({
    required this.file,
    required this.onTap,
    required this.onTogglePin,
    this.isShared = false,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _truncateCid(String cid) {
    if (cid.length <= 16) return cid;
    return '${cid.substring(0, 8)}...${cid.substring(cid.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.zCeladon.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(file.mimeType.substring(0, 1), style: TextStyle(
                      fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700,
                      color: context.zCeladon)),
                ),
                SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(file.name, style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                          ),
                          Icon(
                            file.isEncrypted ? Icons.lock : Icons.lock_open,
                            size: 12,
                            color: file.isEncrypted ? context.zSuccess : context.zTextDisabled,
                          ),
                          if (file.shareCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: context.zCeladon.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share, size: 8, color: context.zCeladon),
                                  const SizedBox(width: 2),
                                  Text('${file.shareCount}',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: context.zCeladon)),
                                ],
                              ),
                            ),
                          ],
                          if (file.isPinned)
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.push_pin, size: 12, color: context.zAccent.withOpacity(0.7)),
                            ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(_truncateCid(file.cid), style: ZeroTypography.monoSmall(context)),
                    ],
                  ),
                ),
                SizedBox(width: ZeroSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatSize(file.size),
                        style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent)),
                    SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_copy, size: 10, color: context.zTextTertiary.withOpacity(0.6)),
                        SizedBox(width: 2),
                        Text('${file.replicas}',
                            style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextTertiary)),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: ZeroSpacing.sm),
                GestureDetector(
                  onTap: onTogglePin,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: file.isPinned ? context.zAccent.withOpacity(0.1) : context.zFrostWhite,
                      border: Border.all(
                        color: file.isPinned ? context.zAccent.withOpacity(0.2) : context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      file.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 16,
                      color: file.isPinned ? context.zAccent : context.zTextTertiary,
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

class _DetailSheet extends StatefulWidget {
  final DASNFile file;
  final DASNStorageService storage;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleEncryption;

  const _DetailSheet({
    required this.file,
    required this.storage,
    required this.onTogglePin,
    required this.onToggleEncryption,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _isSharing = false;
  String? _shareLink;
  bool _showQrPlaceholder = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final link = widget.storage.generateShareLink(widget.file.cid);
    if (!mounted) return;
    setState(() {
      _shareLink = link;
      _showQrPlaceholder = true;
      _isSharing = false;
    });
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    await widget.storage.downloadWithProgress(widget.file.cid, (progress) {
      if (!mounted) return;
      setState(() => _downloadProgress = progress);
    });
    if (!mounted) return;
    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final file = widget.file;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ZeroSpacing.cardRadius)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: ZeroSpacing.screenHorizontal,
          right: ZeroSpacing.screenHorizontal,
          top: ZeroSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + ZeroSpacing.xl,
        ),
        child: Column(
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
            const SizedBox(height: ZeroSpacing.lg),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.zCeladon.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(file.mimeType.substring(0, 1), style: TextStyle(
                      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700,
                      color: context.zCeladon)),
                ),
                const SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.name, style: ZeroTypography.headline(context)),
                      const SizedBox(height: 2),
                      Text(_truncateCid(file.cid), style: ZeroTypography.monoSmall(context)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeroSpacing.lg),
            _buildMetadataSection(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildEncryptionRow(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildActionButtons(isZh),
            if (_shareLink != null) ...[
              const SizedBox(height: ZeroSpacing.lg),
              _buildShareLinkSection(isZh),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: ZeroSpacing.lg),
              _buildDownloadProgress(),
            ],
            if (file.sharedWith.isNotEmpty) ...[
              const SizedBox(height: ZeroSpacing.lg),
              _buildSharedWithList(isZh),
            ],
            if (file.downloadCount > 0) ...[
              const SizedBox(height: ZeroSpacing.md),
              Text(
                isZh
                    ? '下载次数：${file.downloadCount}'
                    : 'Downloads: ${file.downloadCount}',
                style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: ZeroSpacing.lg),
          ],
        ),
      ),
    );
  }

  String _truncateCid(String cid) {
    if (cid.length <= 16) return cid;
    return '${cid.substring(0, 12)}...${cid.substring(cid.length - 8)}';
  }

  Widget _buildMetadataSection(bool isZh) {
    final file = widget.file;
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        children: [
          _MetadataRow(label: 'CID', value: _truncateCid(file.cid), mono: true),
          _MetadataRow(label: isZh ? '大小' : 'Size', value: _formatSize(file.size), mono: true),
          _MetadataRow(label: isZh ? '分块数' : 'Chunks', value: '${file.chunkCount}', mono: true),
          _MetadataRow(label: isZh ? '副本' : 'Replicas', value: '${file.replicas}', mono: true),
          _MetadataRow(label: isZh ? '上传时间' : 'Uploaded', value: _formatDate(file.uploadedAt), mono: false, isLast: true),
        ],
      ),
    );
  }

  Widget _buildEncryptionRow(bool isZh) {
    final file = widget.file;
    return ZeroCard(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                file.isEncrypted ? Icons.lock : Icons.lock_open,
                size: 18,
                color: file.isEncrypted ? context.zSuccess : context.zTextDisabled,
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZh ? '加密状态' : 'Encryption',
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                  ),
                  if (file.isEncrypted && file.encryptionKey != null)
                    Text(file.encryptionKey!,
                        style: ZeroTypography.monoSmall(context).copyWith(fontSize: 9, color: context.zSuccess)),
                  if (!file.isEncrypted)
                    Text(isZh ? '未加密' : 'Not encrypted',
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
                ],
              ),
            ],
          ),
          Switch(
            value: file.isEncrypted,
            onChanged: (_) => widget.onToggleEncryption(),
            activeColor: context.zSuccess,
            activeTrackColor: context.zSuccess.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isZh) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isSharing ? null : _handleShare,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                gradient: context.zAccentGradient,
              ),
              alignment: Alignment.center,
              child: _isSharing
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.zBg),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: 18, color: context.zBg),
                        const SizedBox(width: ZeroSpacing.sm),
                        Text(
                          isZh ? '分享' : 'Share',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
                            letterSpacing: 0.5, color: context.zBg,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: _isDownloading ? null : _handleDownload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                border: Border.all(color: context.zAccent.withOpacity(0.4), width: 0.5),
                color: context.zAccent.withOpacity(0.08),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 18, color: context.zAccent),
                  const SizedBox(width: ZeroSpacing.sm),
                  Text(
                    isZh ? '下载' : 'Download',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: context.zAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareLinkSection(bool isZh) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: context.zSuccess),
              const SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Text(
                  isZh ? '分享链接已生成' : 'Share link generated',
                  style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13, color: context.zSuccess),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
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
                    _shareLink!,
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
          const SizedBox(height: ZeroSpacing.md),
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              borderRadius: BorderRadius.circular(8),
              color: context.zFrostWhite,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 48, color: context.zTextDisabled),
                const SizedBox(height: ZeroSpacing.sm),
                Text(
                  isZh ? 'QR 码占位' : 'QR Placeholder',
                  style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final isZh = ZeroTheme.isZh(context);
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isZh ? '下载中...' : 'Downloading...', style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13)),
              Text('${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: context.zFrostWhiteStrong,
              valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
              minHeight: 6,
            ),
          ),
          if (_downloadProgress >= 1.0) ...[
            const SizedBox(height: ZeroSpacing.sm),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: context.zSuccess),
                const SizedBox(width: ZeroSpacing.xs),
                Text(isZh ? '下载完成' : 'Download complete',
                    style: ZeroTypography.caption(context).copyWith(color: context.zSuccess, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharedWithList(bool isZh) {
    final file = widget.file;
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '已分享给' : 'Shared with',
            style: ZeroTypography.caption(context).copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ...file.sharedWith.map((user) => Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: context.zCeladon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(user[0].toUpperCase(),
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: context.zCeladon)),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Text(user, style: ZeroTypography.monoSmall(context).copyWith(fontSize: 11, color: context.zTextSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool isLast;

  const _MetadataRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : ZeroSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZeroTypography.caption(context)),
          Flexible(
            child: Text(
              value,
              style: (mono
                  ? ZeroTypography.monoSmall(context)
                  : ZeroTypography.caption(context).copyWith(fontFamily: 'Inter'))
                  .copyWith(color: context.zTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color accentColor;
  final Color trackColor;
  final Color textColor;
  final Color celadonColor;
  final Color tertiaryTextColor;
  final String usedLabel;

  _GaugePainter({
    required this.percentage,
    required this.accentColor,
    required this.trackColor,
    required this.textColor,
    required this.celadonColor,
    required this.tertiaryTextColor,
    required this.usedLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;
    const startAngle = -pi * 0.75;
    const sweepAngle = pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    final clampedPercent = percentage.clamp(0.0, 1.0);
    final progressSweep = sweepAngle * clampedPercent;

    final gradient = SweepGradient(
      colors: [
        accentColor.withOpacity(0.5),
        accentColor,
        celadonColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, progressSweep, false, progressPaint);

    final endAngle = startAngle + progressSweep;
    final dotCenter = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );
    final dotPaint = Paint()..color = celadonColor..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, strokeWidth / 2, dotPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(clampedPercent * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 8));

    final labelPainter = TextPainter(
      text: TextSpan(
        text: usedLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
          color: tertiaryTextColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy + 18));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.usedLabel != usedLabel;
  }
}