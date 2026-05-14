import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../services/onion/onion_routing_service.dart';
import '../../widgets/zero_card.dart';

class OnionCircuitPanel extends StatefulWidget {
  const OnionCircuitPanel({super.key});

  @override
  State<OnionCircuitPanel> createState() => _OnionCircuitPanelState();
}

class _OnionCircuitPanelState extends State<OnionCircuitPanel> {
  final _router = OnionRoutingService();
  OnionCircuit? _activeCircuit;
  bool _isBuilding = false;
  String? _testMessage;
  RoutedMessageResult? _routeResult;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();
    _buildNewCircuit();
  }

  void _buildNewCircuit() {
    setState(() {
      _isBuilding = true;
      _activeCircuit = null;
      _routeResult = null;
      _testMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      final result = _router.buildCircuit();
      if (mounted) {
        setState(() {
          _isBuilding = false;
          _activeCircuit = result.circuit;
        });
      }
    });
  }

  void _sendTestMessage() {
    if (_activeCircuit == null || !_activeCircuit!.isAlive) return;

    setState(() {
      _isRouting = true;
      _routeResult = null;
      _testMessage = 'HELLO_ONION:${DateTime.now().millisecondsSinceEpoch}';
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _activeCircuit != null) {
        final result = _router.routeMessage(
          _activeCircuit!,
          'did:zero:Z8P2K5W1RT',
          _testMessage!,
        );
        setState(() {
          _isRouting = false;
          _routeResult = result;
        });
      }
    });
  }

  String _hopLabel(int index, int total, bool isZh) {
    switch (index) {
      case 0:
        return isZh ? '入口节点' : 'Entry Node';
      default:
        if (index == total - 1) return isZh ? '出口节点' : 'Exit Node';
        return isZh ? '中继节点 $index' : 'Relay $index';
    }
  }

  IconData _hopIcon(int index, int total) {
    switch (index) {
      case 0:
        return Icons.login_rounded;
      default:
        if (index == total - 1) return Icons.logout_rounded;
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final nodes = _router.availableNodes;
    final circuits = _router.activeCircuits;

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isZh ? '洋葱路由控制台' : 'Onion Routing Console',
          style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.zAccent),
            onPressed: _isBuilding ? null : _buildNewCircuit,
            tooltip: isZh ? '重建电路' : 'Rebuild Circuit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZeroSpacing.md),
            _buildNetworkOverview(context, nodes.length),
            const SizedBox(height: ZeroSpacing.md),
            _buildActiveCircuit(context),
            const SizedBox(height: ZeroSpacing.md),
            _buildNodeList(context, nodes),
            const SizedBox(height: ZeroSpacing.md),
            _buildRoutingTrace(context),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOverview(BuildContext context, int totalNodes) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final onlineNodes = _router.availableNodes.length;
    final circuitCount = _router.activeCircuitCount;

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.zCeladonGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hub_rounded, color: context.zCeladon, size: 22),
              ),
              const SizedBox(width: ZeroSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZh ? 'Zero 洋葱网络' : 'Zero Onion Network',
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 16),
                  ),
                  Text(
                    isZh ? '多层加密 · 零知识路由' : 'Multi-layer Encryption · Zero-Knowledge Routing',
                    style: ZeroTypography.caption(context),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.zSuccess,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: context.zSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Row(
            children: [
              _buildStatChip(context, '$totalNodes', isZh ? '中继节点' : 'Relay Nodes', context.zAccent),
              const SizedBox(width: ZeroSpacing.sm),
              _buildStatChip(context, '$onlineNodes', isZh ? '在线' : 'Online', context.zSuccess),
              const SizedBox(width: ZeroSpacing.sm),
              _buildStatChip(context, '$circuitCount', isZh ? '活跃电路' : 'Active Circuits', context.zWarning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCircuit(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (_isBuilding) {
      return ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: ZeroSpacing.md),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '正在构建洋葱电路...' : 'Building onion circuit...',
              style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh ? '选择入口 → 中继 → 出口节点' : 'Selecting Entry → Relay → Exit nodes',
              style: ZeroTypography.caption(context),
            ),
            const SizedBox(height: ZeroSpacing.md),
          ],
        ),
      );
    }

    if (_activeCircuit == null) {
      return ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        onTap: _buildNewCircuit,
        child: Column(
          children: [
            Icon(Icons.router_outlined, size: 32, color: context.zTextTertiary),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              isZh ? '点击构建洋葱电路' : 'Tap to build onion circuit',
              style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
            ),
          ],
        ),
      );
    }

    final circuit = _activeCircuit!;
    final totalLatency = circuit.hops.fold<int>(0, (sum, h) => sum + h.node.latencyMs);

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zSuccess,
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                circuit.circuitId,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: context.zTextPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _buildNewCircuit,
                child: Icon(Icons.cached_rounded, size: 18, color: context.zTextTertiary),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              GestureDetector(
                onTap: () {
                  _router.destroyCircuit(circuit.circuitId);
                  setState(() => _activeCircuit = null);
                },
                child: Icon(Icons.close_rounded, size: 18, color: context.zError.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            height: 80,
            child: Row(
              children: [
                _buildYouNode(context),
                Expanded(child: _buildCircuitLine(context, circuit)),
                _buildTargetNode(context),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Row(
            children: [
              _buildCircuitInfo(context, isZh ? '跳数' : 'Hops', '${circuit.hopCount}', context.zAccent),
              const SizedBox(width: ZeroSpacing.md),
              _buildCircuitInfo(context, isZh ? '延时' : 'Latency', '${totalLatency}ms', context.zWarning),
              const SizedBox(width: ZeroSpacing.md),
              _buildCircuitInfo(context, isZh ? '转发' : 'Forwarded', '${circuit.bytesForwarded}B', context.zTextSecondary),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRouting ? null : _sendTestMessage,
              icon: _isRouting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(context.zBg),
                      ),
                    )
                  : Icon(Icons.send_rounded, size: 18, color: context.zBg),
              label: Text(
                _isRouting ? (isZh ? '路由中...' : 'Routing...') : (isZh ? '发送测试消息' : 'Send Test Message'),
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: context.zBg,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.zAccent,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouNode(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [context.zAccent, context.zAccent.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.person, color: context.zBg, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'YOU',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: context.zAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetNode(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [context.zCeladon, context.zCeladon.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.public_rounded, color: context.zBg, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'DEST',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: context.zCeladon,
          ),
        ),
      ],
    );
  }

  Widget _buildCircuitLine(BuildContext context, OnionCircuit circuit) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: circuit.hops.length,
            itemBuilder: (context, index) {
              final hop = circuit.hops[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hopColor(index, circuit.hopCount).withOpacity(0.15),
                        border: Border.all(
                          color: _hopColor(index, circuit.hopCount).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _hopIcon(index, circuit.hopCount),
                        size: 14,
                        color: _hopColor(index, circuit.hopCount),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.zAccent.withOpacity(0.3),
                context.zFrostWhiteStrong,
                context.zCeladon.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: circuit.hops.map((h) {
            return Text(
              h.node.name.substring(0, 3),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 8,
                letterSpacing: 0.5,
                color: context.zTextTertiary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _hopColor(int index, int total) {
    if (index == 0) return context.zAccent;
    if (index == total - 1) return context.zCeladon;
    return context.zWarning;
  }

  Widget _buildCircuitInfo(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(fontSize: 11),
        ),
        const SizedBox(width: ZeroSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeList(BuildContext context, List<OnionNode> nodes) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '中继节点' : 'Relay Nodes',
          style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
        ),
        const SizedBox(height: ZeroSpacing.sm),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: ZeroSpacing.sm),
            itemBuilder: (context, index) {
              final node = nodes[index];
              final isActive = _activeCircuit?.hops.any((h) => h.node.id == node.id) ?? false;

              return Container(
                width: 140,
                padding: EdgeInsets.all(ZeroSpacing.md),
                decoration: BoxDecoration(
                  color: isActive ? context.zAccent.withOpacity(0.06) : context.zSurface,
                  borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                  border: Border.all(
                    color: isActive ? context.zAccent.withOpacity(0.25) : context.zFrostWhiteStrong,
                    width: isActive ? 1 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: node.isOnline ? context.zSuccess : context.zError,
                          ),
                        ),
                        const SizedBox(width: ZeroSpacing.xs),
                        Text(
                          node.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.zTextPrimary,
                          ),
                        ),
                        if (isActive) ...[
                          const Spacer(),
                          Icon(Icons.check_circle_rounded, size: 14, color: context.zAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node.region,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        color: context.zTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${node.latencyMs}ms · ${(node.uptime * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        color: context.zTextDisabled,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 10, color: context.zTextDisabled),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            node.publicKeyHex.substring(0, 12),
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 8,
                              color: context.zTextDisabled,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoutingTrace(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (_isRouting) {
      return ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Text(
                isZh ? '洋葱消息路由中...' : 'Routing onion message...',
                style: ZeroTypography.caption(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_routeResult == null) {
      return ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.route_outlined, size: 32, color: context.zTextDisabled.withOpacity(0.4)),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh ? '发送测试消息查看路由轨迹' : 'Send a test message to view routing trace',
              style: ZeroTypography.caption(context),
            ),
          ],
        ),
      );
    }

    final result = _routeResult!;
    final totalLatency = result.trace.fold<int>(0, (sum, t) => sum + t.latencyMs);

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 18,
                color: result.success ? context.zSuccess : context.zError,
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                result.success ? (isZh ? '路由成功' : 'Route Success') : (isZh ? '路由失败' : 'Route Failed'),
                style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${totalLatency}ms',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: result.success ? context.zSuccess : context.zError,
                ),
              ),
            ],
          ),
          if (_testMessage != null) ...[
            const SizedBox(height: ZeroSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: ZeroSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _testMessage!,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: context.zTextDisabled,
                ),
              ),
            ),
          ],
          const SizedBox(height: ZeroSpacing.md),
          ...result.trace.map((step) => _buildTraceStep(context, step, result.trace)),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            result.success
                ? (isZh ? '✓ 消息已通过洋葱路由安全送达' : '✓ Message delivered securely via onion routing')
                : (isZh ? '✗ 路由中断' : '✗ Route interrupted'),
            style: ZeroTypography.caption(context).copyWith(
              color: result.success ? context.zSuccess : context.zError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceStep(BuildContext context, RoutingTraceStep step, List<RoutingTraceStep> allSteps) {
    final isLast = step == allSteps.last;
    final isError = step.action == 'ERROR';
    final iconColor = isError ? context.zError : context.zAccent;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.12),
                ),
                child: Icon(
                  _traceIcon(step.action),
                  size: 12,
                  color: iconColor,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 24,
                  color: context.zDivider,
                ),
            ],
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    step.nodeName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.zTextPrimary,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.xs),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _traceActionColor(step.action).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _traceActionLabel(step.action, isZh),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _traceActionColor(step.action),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${step.latencyMs}ms',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: context.zTextTertiary,
                    ),
                  ),
                ],
              ),
              if (step.detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  step.detail!,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    color: context.zTextDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
      ],
    );
  }

  IconData _traceIcon(String action) {
    switch (action) {
      case 'ENTRY_EXTEND':
        return Icons.login_rounded;
      case 'MIDDLE_EXTEND':
        return Icons.swap_horiz_rounded;
      case 'EXIT_EXTEND':
        return Icons.logout_rounded;
      case 'EXIT_DELIVER':
        return Icons.check_rounded;
      case 'RELAY_FORWARD':
        return Icons.arrow_forward_rounded;
      case 'ERROR':
        return Icons.close_rounded;
      default:
        return Icons.circle;
    }
  }

  String _traceActionLabel(String action, bool isZh) {
    switch (action) {
      case 'ENTRY_EXTEND':
        return isZh ? '入口扩展' : 'Entry Extend';
      case 'MIDDLE_EXTEND':
        return isZh ? '中继扩展' : 'Relay Extend';
      case 'EXIT_EXTEND':
        return isZh ? '出口扩展' : 'Exit Extend';
      case 'EXIT_DELIVER':
        return isZh ? '送达' : 'Delivered';
      case 'RELAY_FORWARD':
        return isZh ? '转发' : 'Forward';
      case 'ERROR':
        return isZh ? '错误' : 'Error';
      default:
        return action;
    }
  }

  Color _traceActionColor(String action) {
    switch (action) {
      case 'ENTRY_EXTEND':
        return context.zAccent;
      case 'MIDDLE_EXTEND':
        return context.zWarning;
      case 'EXIT_EXTEND':
        return context.zCeladon;
      case 'EXIT_DELIVER':
        return context.zSuccess;
      case 'RELAY_FORWARD':
        return context.zAccent;
      case 'ERROR':
        return context.zError;
      default:
        return context.zTextTertiary;
    }
  }
}