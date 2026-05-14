import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_button.dart';

class FileTransferScreen extends StatefulWidget {
  final String peerName;

  const FileTransferScreen({super.key, required this.peerName});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  final List<_TransferItem> _transfers = [
    _TransferItem(
      fileName: 'zero-whitepaper-v2.pdf',
      fileSize: 4270000,
      progress: 0.78,
      direction: _TransferDirection.receiving,
      speed: 2.3,
      status: _TransferStatus.transferring,
    ),
    _TransferItem(
      fileName: 'arch-diagram.png',
      fileSize: 1280000,
      progress: 1.0,
      direction: _TransferDirection.sending,
      speed: 0,
      status: _TransferStatus.completed,
    ),
    _TransferItem(
      fileName: 'encryption-audit.zip',
      fileSize: 8240000,
      progress: 0.35,
      direction: _TransferDirection.receiving,
      speed: 1.1,
      status: _TransferStatus.transferring,
    ),
    _TransferItem(
      fileName: 'node-config.yaml',
      fileSize: 24000,
      progress: 0.0,
      direction: _TransferDirection.sending,
      speed: 0,
      status: _TransferStatus.failed,
    ),
  ];

  void _simulateFilePick() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.fileSelecting),
        backgroundColor: context.zAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _transfers.insert(
          0,
          _TransferItem(
            fileName: 'shared-doc-${DateTime.now().millisecond}.pdf',
            fileSize: 1560000,
            progress: 0.0,
            direction: _TransferDirection.sending,
            speed: 0,
            status: _TransferStatus.queued,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final activeCount =
        _transfers.where((t) => t.status == _TransferStatus.transferring).length;
    final completedCount =
        _transfers.where((t) => t.status == _TransferStatus.completed).length;

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.fileTransfer),
        actions: [
          if (activeCount > 0)
            Container(
              margin: EdgeInsets.only(right: ZeroSpacing.sm),
              padding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.zAccentGlow,
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              ),
              child: Text(
                isZh ? '$activeCount 个进行中' : '$activeCount active',
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
          vertical: ZeroSpacing.md,
        ),
        children: [
          _buildDropZone(),
          const SizedBox(height: ZeroSpacing.lg),
          _buildStatsBar(activeCount, completedCount),
          const SizedBox(height: ZeroSpacing.lg),
          if (_transfers.isNotEmpty) ...[
            Text(l10n.fileActiveTransfers),
            const SizedBox(height: ZeroSpacing.sm),
            ..._transfers.map((t) => _TransferTile(transfer: t)),
          ] else
            _buildEmptyState(),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zAccent.withOpacity(0.08),
              border: Border.all(
                color: context.zAccent.withOpacity(0.15),
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 28,
              color: context.zAccent.withOpacity(0.5),
            ),
          ),
          SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '拖放文件到此处分享' : 'Drop files to share',
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '端到端加密传输' : 'End-to-end encrypted transfer',
            style: ZeroTypography.caption(context).copyWith(
              color: context.zTextDisabled,
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZeroButton(
                label: l10n.fileSelecting.replaceAll('...', ''),
                onTap: _simulateFilePick,
                outlined: true,
                compact: true,
                icon: Icons.add_rounded,
                width: 160,
              ),
              const SizedBox(width: ZeroSpacing.sm),
              ZeroButton(
                label: l10n.fileShare,
                onTap: _simulateFilePick,
                compact: true,
                icon: Icons.share_rounded,
                width: 160,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(int activeCount, int completedCount) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _statChip(
          icon: Icons.sync_rounded,
          label: '$activeCount ${l10n.fileSending}',
          color: context.zAccent,
          bgOpacity: 0.12,
        ),
        SizedBox(width: ZeroSpacing.sm),
        _statChip(
          icon: Icons.check_circle_outline,
          label: '$completedCount ${l10n.fileComplete}',
          color: context.zSuccess,
          bgOpacity: 0.1,
        ),
        SizedBox(width: ZeroSpacing.sm),
        _statChip(
          icon: Icons.lock,
          label: l10n.fileEncrypted,
          color: context.zCeladon,
          bgOpacity: 0.1,
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
    required double bgOpacity,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: context.zTextDisabled.withOpacity(0.5),
            ),
            SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '暂无传输' : 'No transfers yet',
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh ? '点击上方按钮选择文件开始传输' : 'Tap the button above to select files and start transferring',
              style: ZeroTypography.caption(context).copyWith(
                color: context.zTextDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TransferDirection { sending, receiving }

enum _TransferStatus { queued, transferring, completed, failed }

class _TransferItem {
  final String fileName;
  final int fileSize;
  final double progress;
  final _TransferDirection direction;
  final double speed;
  final _TransferStatus status;

  const _TransferItem({
    required this.fileName,
    required this.fileSize,
    required this.progress,
    required this.direction,
    required this.speed,
    required this.status,
  });
}

class _TransferTile extends StatelessWidget {
  final _TransferItem transfer;

  const _TransferTile({required this.transfer});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatSpeed(double mbPerSec) {
    if (mbPerSec <= 0) return '--';
    if (mbPerSec < 1) return '${(mbPerSec * 1024).toStringAsFixed(0)} KB/s';
    return '${mbPerSec.toStringAsFixed(1)} MB/s';
  }

  IconData _statusIcon(_TransferStatus status) {
    switch (status) {
      case _TransferStatus.queued:
        return Icons.hourglass_empty;
      case _TransferStatus.transferring:
        return Icons.sync_rounded;
      case _TransferStatus.completed:
        return Icons.check_circle_outline;
      case _TransferStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _statusColor(_TransferStatus status, BuildContext context) {
    switch (status) {
      case _TransferStatus.queued:
        return context.zTextTertiary;
      case _TransferStatus.transferring:
        return context.zAccent;
      case _TransferStatus.completed:
        return context.zSuccess;
      case _TransferStatus.failed:
        return context.zError;
    }
  }

  String _statusLabel(_TransferStatus status, bool isZh) {
    switch (status) {
      case _TransferStatus.queued:
        return isZh ? '排队中' : 'Queued';
      case _TransferStatus.transferring:
        return _formatSpeed(transfer.speed);
      case _TransferStatus.completed:
        return isZh ? '已完成' : 'Completed';
      case _TransferStatus.failed:
        return isZh ? '失败' : 'Failed';
    }
  }

  String _iconByExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'PDF';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return 'IMG';
      case 'zip':
      case 'tar':
      case 'gz':
        return 'ZIP';
      case 'yaml':
      case 'yml':
        return 'CFG';
      default:
        return 'FILE';
    }
  }

  Color _iconColorByExtension(String fileName, BuildContext context) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return context.zError;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return context.zCeladon;
      case 'zip':
      case 'tar':
      case 'gz':
        return context.zWarning;
      case 'yaml':
      case 'yml':
        return context.zAccent;
      default:
        return context.zTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final isTransferring = transfer.status == _TransferStatus.transferring;
    final isCompleted = transfer.status == _TransferStatus.completed;
    final isQueued = transfer.status == _TransferStatus.queued;
    final statusColor = _statusColor(transfer.status, context);
    final fileType = _iconByExtension(transfer.fileName);
    final fileTypeColor = _iconColorByExtension(transfer.fileName, context);

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: fileTypeColor.withOpacity(0.08),
                    border: Border.all(
                      color: fileTypeColor.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    fileType,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: fileTypeColor,
                    ),
                  ),
                ),
                SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: ZeroTypography.bodyBold(context).copyWith(
                          fontSize: 13,
                          color: isCompleted
                              ? context.zTextSecondary
                              : context.zTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatSize(transfer.fileSize),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ZeroSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      _statusIcon(transfer.status),
                      size: 18,
                      color: isTransferring
                          ? statusColor
                          : statusColor.withOpacity(0.7),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _statusLabel(transfer.status, isZh),
                      style: ZeroTypography.monoSmall(context).copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isQueued) ...[
              SizedBox(height: ZeroSpacing.sm),
              Row(
                children: [
                  Text(
                    '${(transfer.progress * 100).toInt()}%',
                    style: ZeroTypography.monoSmall(context).copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    transfer.direction == _TransferDirection.sending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: context.zTextDisabled,
                  ),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: transfer.progress,
                  backgroundColor: context.zFrostWhiteStrong,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: isCompleted ? 3 : 4,
                ),
              ),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}