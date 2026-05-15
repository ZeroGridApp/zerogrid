import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/node/node_service.dart';
import '../../widgets/zero_card.dart';

class ZeroNetworkTopologyScreen extends StatefulWidget {
  const ZeroNetworkTopologyScreen({super.key});

  @override
  State<ZeroNetworkTopologyScreen> createState() => _ZeroNetworkTopologyScreenState();
}

class _ZeroNetworkTopologyScreenState extends State<ZeroNetworkTopologyScreen> {
  final _nodeService = ZeroNodeService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final stats = _nodeService.getNetworkStats();
    final peers = _nodeService.getPeerNodes();
    final nodeStatus = _nodeService.getStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '网络拓扑' : 'Network Topology'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZeroSpacing.lg),
            _buildNetworkOverview(isZh, stats ?? NetworkStats(totalNodes: 0, onlineNodes: 0, averageLatency: 0, totalBandwidth: 0, totalStorage: 0, topPeers: [])),
            const SizedBox(height: ZeroSpacing.lg),
            _buildNatStatus(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildTopologyMap(isZh, peers, nodeStatus ?? NodeStatus(name: '', nodeId: '', status: 'offline', nodeType: 'full', uptime: 0, peersConnected: 0, latency: 0, bandwidthUp: 0, bandwidthDown: 0, storageUsed: 0, storageTotal: 0, blocksSynced: 0, blocksTotal: 0, rewardsEarned: 0, startedAt: DateTime.now())),
            const SizedBox(height: ZeroSpacing.lg),
            _buildPeerList(isZh, peers),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOverview(bool isZh, NetworkStats stats) {
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '网络概览' : 'Network Overview',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isZh ? '总节点' : 'Total Nodes',
                  '${stats.totalNodes}',
                  Icons.dns_rounded,
                  context.zAccent,
                ),
              ),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: _buildStatItem(
                  isZh ? '在线节点' : 'Online',
                  '${stats.onlineNodes}',
                  Icons.check_circle_rounded,
                  context.zSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isZh ? '平均延迟' : 'Avg Latency',
                  '${stats.averageLatency.toStringAsFixed(1)}ms',
                  Icons.speed,
                  context.zWarning,
                ),
              ),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: _buildStatItem(
                  isZh ? '总带宽' : 'Bandwidth',
                  '${(stats.totalBandwidth / 1000).toStringAsFixed(1)} Gbps',
                  Icons.swap_vert_rounded,
                  context.zCeladon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: ZeroSpacing.sm),
        Text(
          value,
          style: ZeroTypography.bodyBold(context).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: ZeroTypography.caption(context),
        ),
      ],
    );
  }

  Widget _buildNatStatus(bool isZh) {
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zSuccess,
            ),
          ),
          const SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isZh ? 'NAT 类型' : 'NAT Type',
                  style: ZeroTypography.bodyBold(context),
                ),
                const SizedBox(height: 2),
                Text(
                  isZh ? 'Full Cone NAT — 最佳 P2P 可达性' : 'Full Cone NAT — Optimal P2P reachability',
                  style: ZeroTypography.caption(context).copyWith(color: context.zSuccess),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: context.zSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.zSuccess.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              isZh ? '优秀' : 'Excellent',
              style: ZeroTypography.caption(context).copyWith(color: context.zSuccess),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyMap(bool isZh, List<PeerNode> peers, NodeStatus nodeStatus) {
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? 'P2P 拓扑视图' : 'P2P Topology View',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '你的节点位于中心，周围是已连接的 Peer 节点。' : 'Your node is at the center with connected peers around it.',
            style: ZeroTypography.caption(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            height: 320,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TopologyPainter(
                peers: peers,
                accentColor: context.zAccent,
                successColor: context.zSuccess,
                warningColor: context.zWarning,
                errorColor: context.zError,
                lineColor: context.zFrostWhiteStrong,
                cardBgColor: context.zSurface,
                textPrimary: context.zTextPrimary,
                textTertiary: context.zTextTertiary,
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(context.zSuccess, '<20ms ${isZh ? '优秀' : 'Excellent'}'),
              const SizedBox(width: ZeroSpacing.md),
              _buildLegend(context.zWarning, '<50ms ${isZh ? '良好' : 'Good'}'),
              const SizedBox(width: ZeroSpacing.md),
              _buildLegend(const Color(0xFFD9763A), '<100ms ${isZh ? '一般' : 'Fair'}'),
              const SizedBox(width: ZeroSpacing.md),
              _buildLegend(context.zError, '>100ms ${isZh ? '较差' : 'Poor'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildPeerList(bool isZh, List<PeerNode> peers) {
    final roleIcons = {
      'relay': Icons.router_rounded,
      'storage': Icons.cloud_rounded,
      'validator': Icons.verified_rounded,
      'full': Icons.dns_rounded,
    };

    final roleLabels = {
      'relay': isZh ? '中继' : 'Relay',
      'storage': isZh ? '存储' : 'Storage',
      'validator': isZh ? '验证者' : 'Validator',
      'full': isZh ? '全节点' : 'Full',
    };

    final regionFlags = {
      'asia-east': '🇸🇬',
      'asia-south': '🇮🇳',
      'us-east': '🇺🇸',
      'us-west': '🇺🇸',
      'eu-west': '🇪🇺',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? 'Peer 节点列表' : 'Peer Nodes',
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        ...peers.map((peer) {
          final latencyColor = peer.latency < 20
              ? context.zSuccess
              : peer.latency < 50
                  ? context.zWarning
                  : peer.latency < 100
                      ? const Color(0xFFD9763A)
                      : context.zError;

          return Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: ZeroCard(
              onTap: () => _showPeerDetail(isZh, peer, latencyColor),
              padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 2),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: latencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      roleIcons[peer.role] ?? Icons.devices_rounded,
                      size: 20,
                      color: latencyColor,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              regionFlags[peer.region] ?? '🌐',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              peer.peerId,
                              style: ZeroTypography.monoSmall(context).copyWith(color: context.zTextPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${roleLabels[peer.role] ?? peer.role} · ${peer.address}',
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${peer.latency}ms',
                        style: ZeroTypography.bodyBold(context).copyWith(color: latencyColor),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: peer.isReachable ? context.zSuccess : context.zTextDisabled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showPeerDetail(bool isZh, PeerNode peer, Color latencyColor) {
    final regionNames = {
      'asia-east': isZh ? '亚洲东部' : 'Asia East',
      'asia-south': isZh ? '亚洲南部' : 'Asia South',
      'us-east': isZh ? '美国东部' : 'US East',
      'us-west': isZh ? '美国西部' : 'US West',
      'eu-west': isZh ? '欧洲西部' : 'EU West',
    };

    final roleNames = {
      'relay': isZh ? '中继节点' : 'Relay Node',
      'storage': isZh ? '存储节点' : 'Storage Node',
      'validator': isZh ? '验证者节点' : 'Validator Node',
      'full': isZh ? '全节点' : 'Full Node',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ZeroSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: latencyColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: latencyColor.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(Icons.dns_rounded, size: 28, color: latencyColor),
                ),
                const SizedBox(height: ZeroSpacing.md),
                Text(peer.peerId, style: ZeroTypography.title(context)),
                const SizedBox(height: ZeroSpacing.lg),
                _buildDetailRow(
                  isZh ? '地址' : 'Address',
                  peer.address,
                  Icons.language_rounded,
                ),
                const SizedBox(height: ZeroSpacing.md),
                _buildDetailRow(
                  isZh ? '区域' : 'Region',
                  regionNames[peer.region] ?? peer.region,
                  Icons.public_rounded,
                ),
                const SizedBox(height: ZeroSpacing.md),
                _buildDetailRow(
                  isZh ? '角色' : 'Role',
                  roleNames[peer.role] ?? peer.role,
                  Icons.label_rounded,
                ),
                const SizedBox(height: ZeroSpacing.md),
                _buildDetailRow(
                  isZh ? '延迟' : 'Latency',
                  '${peer.latency}ms',
                  Icons.speed,
                  valueColor: latencyColor,
                ),
                const SizedBox(height: ZeroSpacing.md),
                _buildDetailRow(
                  isZh ? '可达性' : 'Reachable',
                  peer.isReachable
                      ? (isZh ? '可达' : 'Reachable')
                      : (isZh ? '不可达' : 'Unreachable'),
                  Icons.wifi_rounded,
                  valueColor: peer.isReachable ? context.zSuccess : context.zError,
                ),
                const SizedBox(height: ZeroSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                      side: BorderSide(color: context.zFrostWhiteStrong),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
                    ),
                    child: Text(
                      isZh ? '关闭' : 'Close',
                      style: ZeroTypography.bodyBold(context),
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.zTextTertiary),
        const SizedBox(width: ZeroSpacing.md),
        Text(label, style: ZeroTypography.body(context)),
        const Spacer(),
        Text(
          value,
          style: ZeroTypography.bodyBold(context).copyWith(
            color: valueColor ?? context.zTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _TopologyPainter extends CustomPainter {
  final List<PeerNode> peers;
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color lineColor;
  final Color cardBgColor;
  final Color textPrimary;
  final Color textTertiary;

  _TopologyPainter({
    required this.peers,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.lineColor,
    required this.cardBgColor,
    required this.textPrimary,
    required this.textTertiary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2 - 50;
    final centerRadius = 28.0;

    final centerDot = Offset(centerX, centerY);

    final paintCenter = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerDot, centerRadius, paintCenter);

    final paintCenterBorder = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(centerDot, centerRadius + 6, paintCenterBorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'YOU',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );

    final displayedPeers = peers.take(8).toList();
    final angleStep = 2 * 3.14159 / displayedPeers.length;
    final random = Random(42);

    for (var i = 0; i < displayedPeers.length; i++) {
      final peer = displayedPeers[i];
      final radiusOffset = maxRadius * (0.5 + random.nextDouble() * 0.5);
      final angle = angleStep * i + (random.nextDouble() - 0.5) * 0.3;
      final x = centerX + radiusOffset * cos(angle);
      final y = centerY + radiusOffset * sin(angle);
      final peerDot = Offset(x, y);

      Color latencyColor;
      if (peer.latency < 20) {
        latencyColor = successColor;
      } else if (peer.latency < 50) {
        latencyColor = warningColor;
      } else if (peer.latency < 100) {
        latencyColor = const Color(0xFFD9763A);
      } else {
        latencyColor = errorColor;
      }

      final paintLine = Paint()
        ..color = latencyColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(centerDot, peerDot, paintLine);

      final paintPeer = Paint()
        ..color = latencyColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peerDot, 10, paintPeer);

      final paintPeerBorder = Paint()
        ..color = latencyColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(peerDot, 10, paintPeerBorder);

      final latencyTp = TextPainter(
        text: TextSpan(
          text: '${peer.latency}ms',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: latencyColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      latencyTp.layout();
      latencyTp.paint(
        canvas,
        Offset(x - latencyTp.width / 2, y + 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}