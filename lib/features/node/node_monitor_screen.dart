import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/node/node_service.dart';
import '../../widgets/zero_card.dart';

class ZeroNodeMonitorScreen extends StatefulWidget {
  const ZeroNodeMonitorScreen({super.key});

  @override
  State<ZeroNodeMonitorScreen> createState() => _ZeroNodeMonitorScreenState();
}

class _ZeroNodeMonitorScreenState extends State<ZeroNodeMonitorScreen> {
  final _nodeService = ZeroNodeService();

  @override
  void initState() {
    super.initState();
    _nodeService.seedDemoData();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final status = _nodeService.getStatus();
    final peers = _nodeService.getPeerNodes();
    final isOnline = status.status == 'online';

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '节点监控' : 'Node Monitor'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _nodeService.restartNode();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: ZeroSpacing.lg),
              _buildStatusHeader(isZh, status, isOnline),
              const SizedBox(height: ZeroSpacing.lg),
              _buildConnectionMetrics(isZh, status, isOnline),
              const SizedBox(height: ZeroSpacing.lg),
              _buildStorageProgress(isZh, status),
              const SizedBox(height: ZeroSpacing.lg),
              _buildBlockSync(isZh, status),
              const SizedBox(height: ZeroSpacing.lg),
              _buildRewardsCard(isZh, status),
              const SizedBox(height: ZeroSpacing.lg),
              _buildUptimeHistory(isZh),
              const SizedBox(height: ZeroSpacing.lg),
              _buildPeerList(isZh, peers, isOnline),
              const SizedBox(height: ZeroSpacing.lg),
              _buildActionButtons(isZh, isOnline),
              const SizedBox(height: ZeroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isZh, NodeStatus status, bool isOnline) {
    final statusColor = isOnline ? context.zSuccess : context.zError;
    final statusText = isOnline
        ? (isZh ? '运行中 ${status.uptime.toStringAsFixed(1)}%' : 'Online ${status.uptime.toStringAsFixed(1)}%')
        : (isZh ? '已离线' : 'Offline');

    final typeLabels = {
      'relay': isZh ? '中继节点' : 'Relay Node',
      'storage': isZh ? '存储节点' : 'Storage Node',
      'validator': isZh ? '验证者节点' : 'Validator Node',
      'full': isZh ? '全节点' : 'Full Node',
    };

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.name,
                      style: ZeroTypography.headline(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${statusText} · ${typeLabels[status.nodeType] ?? status.nodeType}',
                      style: ZeroTypography.body(context).copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
            decoration: BoxDecoration(
              color: context.zFrostWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  isZh ? '节点 ID: ' : 'Node ID: ',
                  style: ZeroTypography.caption(context),
                ),
                Text(
                  status.nodeId,
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextPrimary),
                ),
                const Spacer(),
                Icon(Icons.copy_rounded, size: 14, color: context.zTextTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionMetrics(bool isZh, NodeStatus status, bool isOnline) {
    final metrics = [
      {
        'icon': Icons.people_rounded,
        'label': isZh ? '连接节点' : 'Peers',
        'value': isOnline ? '${status.peersConnected}' : '--',
        'color': context.zAccent,
      },
      {
        'icon': Icons.speed,
        'label': isZh ? '延迟' : 'Latency',
        'value': isOnline ? '${status.latency}ms' : '--',
        'color': context.zSuccess,
      },
      {
        'icon': Icons.upload_rounded,
        'label': isZh ? '上行' : 'Upload',
        'value': isOnline ? '${status.bandwidthUp.toStringAsFixed(1)} Mbps' : '--',
        'color': context.zCeladon,
      },
      {
        'icon': Icons.download_rounded,
        'label': isZh ? '下行' : 'Download',
        'value': isOnline ? '${status.bandwidthDown.toStringAsFixed(1)} Mbps' : '--',
        'color': context.zWarning,
      },
    ];

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Row(
        children: metrics.map((m) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m['icon'] as IconData, size: 18, color: m['color'] as Color),
                ),
                const SizedBox(height: ZeroSpacing.xs),
                Text(
                  m['value'] as String,
                  style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                ),
                Text(
                  m['label'] as String,
                  style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorageProgress(bool isZh, NodeStatus status) {
    final usedGb = (status.storageUsed / 1024).toStringAsFixed(1);
    final totalGb = (status.storageTotal / 1024).toStringAsFixed(1);
    final ratio = status.storageTotal > 0 ? status.storageUsed / status.storageTotal : 0.0;

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, size: 20, color: context.zAccent),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? '存储使用' : 'Storage Usage',
                style: ZeroTypography.title(context),
              ),
              const Spacer(),
              Text(
                '$usedGb / $totalGb GB',
                style: ZeroTypography.bodyBold(context),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: context.zFrostWhiteStrong,
              valueColor: AlwaysStoppedAnimation(
                ratio > 0.85 ? context.zWarning : context.zAccent,
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            '${(ratio * 100).toStringAsFixed(1)}% ${isZh ? '已使用' : 'used'}',
            style: ZeroTypography.caption(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockSync(bool isZh, NodeStatus status) {
    final synced = status.blocksSynced;
    final total = status.blocksTotal;
    final ratio = total > 0 ? synced / total : 0.0;
    final isSynced = ratio >= 0.999;

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, size: 20, color: context.zCeladon),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? '区块同步' : 'Block Sync',
                style: ZeroTypography.title(context),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: isSynced
                      ? context.zSuccess.withOpacity(0.1)
                      : context.zWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSynced
                      ? (isZh ? '已同步' : 'Synced')
                      : (isZh ? '同步中' : 'Syncing'),
                  style: ZeroTypography.caption(context).copyWith(
                    color: isSynced ? context.zSuccess : context.zWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(synced)} / ${_formatNumber(total)}',
                style: ZeroTypography.mono(context),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(2)}%',
                style: ZeroTypography.mono(context).copyWith(color: context.zAccent),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: context.zFrostWhiteStrong,
              valueColor: AlwaysStoppedAnimation(
                isSynced ? context.zSuccess : context.zCeladon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(bool isZh, NodeStatus status) {
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.zAccent, context.zCeladon],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isZh ? '奖励收益' : 'Rewards Earned',
                  style: ZeroTypography.body(context),
                ),
                Text(
                  '${status.rewardsEarned} ZERO',
                  style: ZeroTypography.displayMedium(context).copyWith(
                    color: context.zAccent,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.zTextTertiary),
        ],
      ),
    );
  }

  Widget _buildUptimeHistory(bool isZh) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabels = isZh
        ? ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
        : days;

    final random = Random(7);
    final values = List.generate(7, (_) => 97.5 + random.nextDouble() * 2.5);

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '7天在线率' : '7-Day Uptime',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index].toStringAsFixed(1)}%',
                          style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: ZeroSpacing.xs),
                        Container(
                          height: (values[index] - 95) / 5 * 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.zAccent,
                                context.zAccent.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        Text(
                          dayLabels[index],
                          style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList(bool isZh, List<PeerNode> peers, bool isOnline) {
    final roleLabels = {
      'relay': isZh ? '中继' : 'Relay',
      'storage': isZh ? '存储' : 'Storage',
      'validator': isZh ? '验证者' : 'Validator',
      'full': isZh ? '全节点' : 'Full',
    };

    final displayedPeers = peers.take(4).toList();

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isZh ? '已连接节点' : 'Connected Peers',
                style: ZeroTypography.title(context),
              ),
              const Spacer(),
              Text(
                isOnline ? '${peers.length}' : '0',
                style: ZeroTypography.bodyBold(context).copyWith(color: context.zAccent),
              ),
            ],
          ),
          if (!isOnline) ...[
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '节点离线，无活动连接' : 'Node offline, no active connections',
              style: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
            ),
          ] else ...[
            const SizedBox(height: ZeroSpacing.md),
            ...displayedPeers.map((peer) {
              final latencyColor = peer.latency < 20
                  ? context.zSuccess
                  : peer.latency < 50
                      ? context.zWarning
                      : context.zError;

              return Padding(
                padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: peer.isReachable ? context.zSuccess : context.zTextDisabled,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.md),
                    Expanded(
                      child: Text(
                        peer.peerId,
                        style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.zFrostWhite,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabels[peer.role] ?? peer.role,
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      '${peer.latency}ms',
                      style: ZeroTypography.caption(context).copyWith(color: latencyColor),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isZh, bool isOnline) {
    return Row(
      children: [
        if (isOnline)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _nodeService.stopNode();
                setState(() {});
              },
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: Text(isZh ? '停止节点' : 'Stop Node'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                side: BorderSide(color: context.zError.withOpacity(0.5)),
                foregroundColor: context.zError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
              ),
            ),
          ),
        if (!isOnline)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _nodeService.startNode();
                setState(() {});
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(isZh ? '启动节点' : 'Start Node'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.zSuccess,
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
              ),
            ),
          ),
        const SizedBox(width: ZeroSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _nodeService.restartNode();
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isZh ? '重启节点' : 'Restart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.zAccent,
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}