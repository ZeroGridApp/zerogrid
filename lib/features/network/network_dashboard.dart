import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/onion/onion_routing_service.dart';
import '../../widgets/zero_card.dart';
import 'onion_circuit_panel.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _dhtCounterController;
  Timer? _refreshTimer;
  final _random = Random();

  int _peerCount = 12;
  String _natStatus = 'Private';
  int _relayCircuits = 3;
  double _bandwidthIn = 0.0;
  double _bandwidthOut = 0.0;
  int _dhtQueries = 847;
  int _messagesRouted = 12530;
  int _latencyMs = 42;
  int _uptimeMinutes = 347;
  final List<double> _dhtHistory = List.generate(20, (_) => 20.0 + Random().nextDouble() * 60);
  final List<_PeerNode> _peers = [];
  double _bandwidthInMax = 5.0;
  double _bandwidthOutMax = 3.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _dhtCounterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _generatePeers();
    _startSimulation();
  }

  void _generatePeers() {
    const names = [
      '12D3KooW...7F3A2B1C', '12D3KooW...B21C8D9E', '12D3KooW...USRelay1',
      '12D3KooW...D904E5F6', '12D3KooW...SN01A7B8', '12D3KooW...1A5FC9D0',
      '12D3KooW...C83EE1F2', '12D3KooW...EURelay2', '12D3KooW...6B20G3H4',
      '12D3KooW...9D47I5J6', '12D3KooW...F18CK7L8', '12D3KooW...33AAM9N0',
    ];
    _peers.clear();
    for (int i = 0; i < min(_peerCount, names.length); i++) {
      _peers.add(_PeerNode(
        id: names[i],
        latency: 20 + _random.nextInt(180),
        status: i < _peerCount - 1 ? _PeerStatus.connected : _PeerStatus.connecting,
      ));
    }
  }

  void _startSimulation() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _peerCount = 10 + _random.nextInt(8);
        _natStatus = _random.nextBool() ? 'Private' : 'Public (NAT-punched)';
        _relayCircuits = 2 + _random.nextInt(5);
        _bandwidthIn = (_random.nextDouble() * 5).clamp(0.1, 5.0);
        _bandwidthOut = (_random.nextDouble() * 3).clamp(0.05, 3.0);
        _dhtQueries += _random.nextInt(15);
        _messagesRouted += _random.nextInt(200);
        _latencyMs = 20 + _random.nextInt(100);
        _uptimeMinutes += 3;

        _dhtHistory.removeAt(0);
        _dhtHistory.add(20.0 + _random.nextDouble() * 60);
        _dhtCounterController.forward(from: 0);

        _generatePeers();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dhtCounterController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _formatUptime(int minutes) {
    final d = minutes ~/ 1440;
    final h = (minutes % 1440) ~/ 60;
    final m = minutes % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.networkDashboard),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                final opacity = 0.3 + _pulseController.value * 0.7;
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.zSuccess.withOpacity(opacity),
                    boxShadow: [
                      BoxShadow(
                        color: context.zSuccess.withOpacity(0.2 + _pulseController.value * 0.4),
                        blurRadius: 8,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                );
              },
            ),
            Spacer(),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.zSuccess.withOpacity(0.1 + _pulseController.value * 0.1),
                    border: Border.all(
                      color: context.zSuccess.withOpacity(0.2 + _pulseController.value * 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi, size: 12, color: context.zSuccess.withOpacity(0.8)),
                      SizedBox(width: 4),
                      Text(
                        l10n.networkLive,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: context.zSuccess,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.layers_rounded, color: context.zAccent, size: 22),
            tooltip: isZh ? '洋葱路由' : 'Onion Routing',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(fullscreenDialog: true, builder: (_) => const OnionCircuitPanel()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        child: Column(
          children: [
            const SizedBox(height: ZeroSpacing.sm),
            _buildStatsGrid(),
            const SizedBox(height: ZeroSpacing.md),
            _buildBandwidthCard(),
            const SizedBox(height: ZeroSpacing.md),
            _buildStatusCards(),
            const SizedBox(height: ZeroSpacing.md),
            _buildDhtSparkline(),
            const SizedBox(height: ZeroSpacing.md),
            _buildTopologyPreview(),
            const SizedBox(height: ZeroSpacing.md),
            _buildPeerList(),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: l10n.networkPeersCount,
          value: '$_peerCount',
          icon: Icons.hub_outlined,
          color: context.zAccent,
        )),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(child: _StatCard(
          label: l10n.networkDHTQRY,
          value: '$_dhtQueries',
          icon: Icons.travel_explore,
          color: context.zCeladon,
        )),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(child: _StatCard(
          label: l10n.networkMSGRTD,
          value: _messagesRouted > 9999
              ? '${(_messagesRouted / 1000).toStringAsFixed(1)}K'
              : '$_messagesRouted',
          icon: Icons.route_outlined,
          color: context.zAccent,
        )),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(child: _StatCard(
          label: l10n.networkCircuits,
          value: '$_relayCircuits',
          icon: Icons.account_tree_outlined,
          color: context.zCeladon,
        )),
      ],
    );
  }

  Widget _buildBandwidthCard() {
    final l10n = AppLocalizations.of(context);
    final inPercent = (_bandwidthIn / _bandwidthInMax).clamp(0.0, 1.0);
    final outPercent = (_bandwidthOut / _bandwidthOutMax).clamp(0.0, 1.0);

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.networkBandwidth, style: ZeroTypography.caption(context).copyWith(
            letterSpacing: 2, fontWeight: FontWeight.w600,
          )),
          SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Icon(Icons.download_outlined, size: 16, color: context.zSuccess.withOpacity(0.7)),
              SizedBox(width: 8),
              Text(l10n.networkDLSpeed, style: ZeroTypography.monoSmall(context).copyWith(color: context.zSuccess, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: inPercent,
                    backgroundColor: context.zFrostWhiteStrong,
                    valueColor: AlwaysStoppedAnimation(context.zSuccess),
                    minHeight: 6,
                  ),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  '${_bandwidthIn.toStringAsFixed(1)} MB/s',
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zSuccess, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              Icon(Icons.upload_outlined, size: 16, color: context.zAccent.withOpacity(0.7)),
              SizedBox(width: 8),
              Text(l10n.networkULSpeed, style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent, fontWeight: FontWeight.w600)),
              SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: outPercent,
                    backgroundColor: context.zFrostWhiteStrong,
                    valueColor: AlwaysStoppedAnimation(context.zAccent),
                    minHeight: 6,
                  ),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  '${_bandwidthOut.toStringAsFixed(1)} MB/s',
                  style: ZeroTypography.monoSmall(context).copyWith(color: context.zAccent, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final isPublic = _natStatus.contains('Public');
    final latencyColor = _latencyMs < 50
        ? context.zSuccess
        : _latencyMs < 150
            ? context.zWarning
            : context.zError;

    return Row(
      children: [
        Expanded(
          child: ZeroCard(
            padding: EdgeInsets.all(ZeroSpacing.md),
            borderRadius: ZeroSpacing.cardRadiusSm,
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (isPublic ? context.zSuccess : context.zWarning).withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPublic ? Icons.public : Icons.vpn_lock_outlined,
                    size: 18,
                    color: isPublic ? context.zSuccess : context.zWarning,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isPublic
                      ? (isZh ? '公网' : 'Public')
                      : (isZh ? '内网' : 'Private'),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPublic ? context.zSuccess : context.zWarning,
                  ),
                ),
                SizedBox(height: 2),
                Text(isZh ? 'NAT 类型' : 'NAT Type', style: ZeroTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: ZeroCard(
            padding: EdgeInsets.all(ZeroSpacing.md),
            borderRadius: ZeroSpacing.cardRadiusSm,
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: latencyColor.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.speed, size: 18, color: latencyColor),
                ),
                SizedBox(height: 8),
                Text(
                  '$_latencyMs ms',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: latencyColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(isZh ? '延迟' : 'Latency', style: ZeroTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: ZeroCard(
            padding: EdgeInsets.all(ZeroSpacing.md),
            borderRadius: ZeroSpacing.cardRadiusSm,
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.zAccent.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.timer_outlined, size: 18, color: context.zAccent),
                ),
                SizedBox(height: 8),
                Text(
                  _formatUptime(_uptimeMinutes),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.zAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(isZh ? '运行时间' : 'Uptime', style: ZeroTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDhtSparkline() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final maxVal = _dhtHistory.reduce(max);
    final normalized = _dhtHistory.map((v) => maxVal > 0 ? v / maxVal : 0.0).toList();

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isZh ? 'DHT 查询活动' : 'DHT QUERY ACTIVITY', style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 2, fontWeight: FontWeight.w600,
              )),
              AnimatedBuilder(
                animation: _dhtCounterController,
                builder: (_, child) {
                  return Text(
                    '${_dhtHistory.last.toStringAsFixed(0)} q/s',
                    style: ZeroTypography.monoSmall(context).copyWith(
                      color: context.zCeladon,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: Size(double.infinity, 60),
              painter: _SparklinePainter(data: normalized, lineColor: context.zCeladon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyPreview() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isZh ? '网络拓扑' : 'NETWORK TOPOLOGY', style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 2, fontWeight: FontWeight.w600,
              )),
              Text(isZh ? '$_peerCount 节点' : '$_peerCount nodes', style: ZeroTypography.caption(context)),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width - ZeroSpacing.screenHorizontal * 2 - ZeroSpacing.md * 2, 160),
              painter: _TopologyPainter(
                peerCount: _peerCount,
                pulseValue: _pulseController.value,
                accentColor: context.zAccent,
                accentGlow: context.zAccentGlow,
                celadonColor: context.zCeladon,
                celadonGlow: context.zCeladonGlow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isZh ? '已连接节点' : 'CONNECTED PEERS', style: ZeroTypography.caption(context).copyWith(
          letterSpacing: 2, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: ZeroSpacing.sm),
        ..._peers.map((peer) => _PeerTile(peer: peer)),
      ],
    );
  }
}

enum _PeerStatus { connected, connecting, disconnected }

class _PeerNode {
  final String id;
  final int latency;
  final _PeerStatus status;

  const _PeerNode({required this.id, required this.latency, required this.status});
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
          Icon(icon, size: 22, color: color.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  final _PeerNode peer;

  const _PeerTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    final statusColor = peer.status == _PeerStatus.connected
        ? context.zSuccess
        : peer.status == _PeerStatus.connecting
            ? context.zWarning
            : context.zError;

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.xs),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.md - 4,
        ),
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Text(
                peer.id,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.zTextPrimary,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.zFrostWhite,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${peer.latency}ms',
                style: ZeroTypography.monoSmall(context).copyWith(
                  color: peer.latency < 50
                      ? context.zSuccess
                      : peer.latency < 150
                          ? context.zAccent
                          : context.zWarning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            iconForStatus(peer.status, statusColor, context),
          ],
        ),
      ),
    );
  }

  Widget iconForStatus(_PeerStatus status, Color color, BuildContext context) {
    switch (status) {
      case _PeerStatus.connected:
        return Icon(Icons.check_circle_outline, size: 16, color: color.withOpacity(0.5));
      case _PeerStatus.connecting:
        return SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: context.zWarning),
        );
      case _PeerStatus.disconnected:
        return Icon(Icons.error_outline, size: 16, color: color.withOpacity(0.5));
    }
  }
}

class _TopologyPainter extends CustomPainter {
  final int peerCount;
  final double pulseValue;
  final Color accentColor;
  final Color accentGlow;
  final Color celadonColor;
  final Color celadonGlow;

  _TopologyPainter({
    required this.peerCount,
    required this.pulseValue,
    required this.accentColor,
    required this.accentGlow,
    required this.celadonColor,
    required this.celadonGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    final centerPaint = Paint()
      ..color = accentColor.withOpacity(0.8 + pulseValue * 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 10, centerPaint);

    final glowPaint = Paint()
      ..color = accentGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 10, glowPaint);

    for (int i = 0; i < min(peerCount, 20); i++) {
      final angle = (2 * pi / max(peerCount, 1)) * i - pi / 2;
      final x = center.dx + cos(angle) * radius * (0.6 + _randomFor(i) * 0.4);
      final y = center.dy + sin(angle) * radius * (0.6 + _randomFor(i) * 0.4);
      final point = Offset(x, y);

      final linePaint = Paint()
        ..color = accentColor.withOpacity(0.08)
        ..strokeWidth = 0.5;
      canvas.drawLine(center, point, linePaint);

      final dotPaint = Paint()
        ..color = celadonColor.withOpacity(0.3 + _randomFor(i + peerCount) * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, dotPaint);

      final dotBorder = Paint()
        ..color = celadonGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(point, 4, dotBorder);
    }
  }

  double _randomFor(int seed) {
    return ((seed * 1103515245 + 12345) & 0x7fffffff).toDouble() / 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.peerCount != peerCount;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _SparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final stepX = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * stepX, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.15),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final lastX = (data.length - 1) * stepX;
    final lastY = size.height - (data.last * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 3, dotPaint);

    final dotBorder = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(lastX, lastY), 4.5, dotBorder);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}