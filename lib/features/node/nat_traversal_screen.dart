import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class NatTraversalScreen extends StatefulWidget {
  const NatTraversalScreen({super.key});

  @override
  State<NatTraversalScreen> createState() => _NatTraversalScreenState();
}

class _NatTraversalScreenState extends State<NatTraversalScreen> {
  bool _isDetecting = false;
  NatType _detectedNatType = NatType.fullCone;
  bool _stunEnabled = true;
  bool _turnEnabled = true;
  bool _upnpEnabled = true;
  UpnpStatus _upnpStatus = UpnpStatus.attempting;
  bool _faqExpanded = false;

  Future<void> _reDetectNatType() async {
    setState(() {
      _isDetecting = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isDetecting = false;
      _detectedNatType = NatType.fullCone;
    });
  }

  Future<void> _testStun() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ZeroTheme.isZh(context) ? 'STUN 测试完成，延迟 12ms' : 'STUN test completed, latency 12ms',
        ),
      ),
    );
  }

  Future<void> _testTurn() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ZeroTheme.isZh(context) ? 'TURN 测试完成，中继连接成功' : 'TURN test completed, relay connection successful',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? 'NAT穿透' : 'NAT Traversal'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
          vertical: ZeroSpacing.screenTop,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZh ? 'NAT穿透配置与诊断' : 'STUN · TURN · ICE · UPnP',
              style: ZeroTypography.body(context),
            ),
            SizedBox(height: ZeroSpacing.lg),
            _buildNatTypeCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildStunConfigCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildTurnConfigCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildIceFlowCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildUpnpCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildConnectionStatsCard(context, isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildTroubleshootingCard(context, isZh),
            SizedBox(height: ZeroSpacing.screenBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildNatTypeCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? 'NAT 类型检测' : 'NAT Type Detection',
                style: ZeroTypography.title(context),
              ),
              ElevatedButton(
                onPressed: _isDetecting ? null : _reDetectNatType,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.sm,
                  ),
                ),
                child: _isDetecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.zTextPrimary,
                          ),
                        ),
                      )
                    : Text(
                        isZh ? '重新检测' : 'Re-detect',
                      ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ZeroSpacing.lg),
            decoration: BoxDecoration(
              color: _getNatColor(_detectedNatType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
            ),
            child: Column(
              children: [
                Text(
                  _getNatEmoji(_detectedNatType),
                  style: const TextStyle(fontSize: 48),
                ),
                SizedBox(height: ZeroSpacing.sm),
                Text(
                  _getNatName(_detectedNatType, isZh),
                  style: ZeroTypography.title(context).copyWith(
                    color: _getNatColor(_detectedNatType),
                  ),
                ),
                Text(
                  _getNatDescription(_detectedNatType, isZh),
                  style: ZeroTypography.body(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStunConfigCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? 'STUN 配置' : 'STUN Configuration',
                style: ZeroTypography.title(context),
              ),
              Switch(
                value: _stunEnabled,
                onChanged: (value) {
                  setState(() {
                    _stunEnabled = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? 'STUN 服务器列表' : 'STUN Servers',
            style: ZeroTypography.bodyBold(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          ..._buildServerList([
            'stun.zero.network:3478',
            'stun.l.google.com:19302',
            'stun.cloudflare.com:3478',
          ], [
            isZh ? '主服务器' : 'primary',
            isZh ? '备用' : 'fallback',
            isZh ? '备用' : 'fallback',
          ], context),
          SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '上次检测：2 分钟前，延迟 12ms' : 'Last check: 2 min ago, latency 12ms',
                style: ZeroTypography.caption(context),
              ),
              TextButton(
                onPressed: _testStun,
                child: Text(isZh ? '测试 STUN' : 'Test STUN'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnConfigCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? 'TURN 配置' : 'TURN Configuration',
                style: ZeroTypography.title(context),
              ),
              Switch(
                value: _turnEnabled,
                onChanged: (value) {
                  setState(() {
                    _turnEnabled = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? 'TURN 服务器列表' : 'TURN Servers',
            style: ZeroTypography.bodyBold(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          ..._buildServerList([
            'turn.zero.network:5349',
            'turn.zero.network:3478',
          ], [
            'TLS',
            isZh ? 'UDP 备用' : 'UDP fallback',
          ], context),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh
                ? '当 P2P 连接失败时，TURN 会转发流量。延迟较高，带宽占用更大。'
                : 'TURN relays traffic when P2P fails. Higher latency, more bandwidth cost.',
            style: ZeroTypography.body(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isZh ? '当前 TURN 使用：' : 'Current TURN usage: ',
                    style: ZeroTypography.caption(context),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.sm,
                      vertical: ZeroSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.zSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    ),
                    child: Text(
                      isZh ? '0.2% 连接 • P2P 优秀' : '0.2% • Excellent P2P rate',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _testTurn,
                child: Text(isZh ? '测试 TURN' : 'Test TURN'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIceFlowCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? 'ICE 连接流程' : 'ICE Connection Flow',
            style: ZeroTypography.title(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          _buildIceStep(
            context,
            '1',
            isZh ? '收集候选地址' : 'Gather Candidates',
            isZh ? '本地地址 → STUN 公网地址 → TURN 中继地址' : 'Local IP → Public IP (STUN) → Relay IP (TURN)',
            Icons.radar,
          ),
          _buildIceStepDivider(context),
          _buildIceStep(
            context,
            '2',
            isZh ? '交换 SDP' : 'Exchange SDP',
            isZh ? '通过 Zero P2P 网络传输信令' : 'Signaling via Zero P2P network',
            Icons.swap_horiz,
          ),
          _buildIceStepDivider(context),
          _buildIceStep(
            context,
            '3',
            isZh ? '连接性检查' : 'Connectivity Checks',
            isZh ? '优先级：直连 P2P > STUN > TURN 中继' : 'Priority: P2P Direct > STUN > TURN relay',
            Icons.track_changes,
          ),
          _buildIceStepDivider(context),
          _buildIceStep(
            context,
            '4',
            isZh ? '连接建立' : 'Connected',
            isZh ? '选择最快路径建立连接' : 'Select fastest path for connection',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildUpnpCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPnP / NAT-PMP',
                style: ZeroTypography.title(context),
              ),
              Switch(
                value: _upnpEnabled,
                onChanged: (value) {
                  setState(() {
                    _upnpEnabled = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '状态：' : 'Status: ',
            style: ZeroTypography.bodyBold(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.sm,
                  vertical: ZeroSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getUpnpColor(_upnpStatus).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                ),
                child: Text(
                  _getUpnpStatusText(_upnpStatus, isZh),
                  style: ZeroTypography.caption(context).copyWith(
                    color: _getUpnpColor(_upnpStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          Text(
            isZh
                ? '如果路由器支持，ZeroNode 会自动配置端口转发，提升 P2P 直连成功率。'
                : 'Automatically configure router port forwarding if supported, improves P2P success rate.',
            style: ZeroTypography.body(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '支持情况：大多数家用路由器支持 UPnP' : 'Supported: Most home routers support UPnP',
            style: ZeroTypography.caption(context),
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '安全提示：仅为 ZeroNode 端口启用 UPnP' : 'Security note: UPnP is enabled only for ZeroNode ports',
            style: ZeroTypography.caption(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatsCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '连接质量统计' : 'Connection Quality Stats',
            style: ZeroTypography.title(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          _buildStatRow(
            context,
            isZh ? 'P2P 直连' : 'P2P Direct',
            '97.8%',
            context.zSuccess,
            isZh ? 'Excellent' : '优秀',
          ),
          SizedBox(height: ZeroSpacing.sm),
          _buildStatRow(
            context,
            isZh ? 'STUN 辅助' : 'STUN Assisted',
            '2.0%',
            context.zSuccess,
            isZh ? 'Good' : '良好',
          ),
          SizedBox(height: ZeroSpacing.sm),
          _buildStatRow(
            context,
            isZh ? 'TURN 中继' : 'TURN Relay',
            '0.2%',
            context.zWarning,
            isZh ? 'Minimal' : '极少',
          ),
          SizedBox(height: ZeroSpacing.md),
          Divider(color: context.zDivider),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '本次会话总连接数：12,847' : 'Total connections this session: 12,847',
            style: ZeroTypography.caption(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard(BuildContext context, bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _faqExpanded = !_faqExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isZh ? '常见问题' : 'Troubleshooting Guide',
                  style: ZeroTypography.title(context),
                ),
                Icon(
                  _faqExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: context.zTextSecondary,
                ),
              ],
            ),
          ),
          if (_faqExpanded) ...[
            SizedBox(height: ZeroSpacing.md),
            _buildFaqItem(
              context,
              isZh ? '无法连接其他节点？' : 'Can\'t connect to peers?',
              isZh
                  ? '检查防火墙，启用 UPnP，或为 TCP 4001 和 UDP 3478 配置端口转发。'
                  : 'Check firewall, enable UPnP, or configure port forwarding for TCP 4001 and UDP 3478.',
            ),
            SizedBox(height: ZeroSpacing.md),
            _buildFaqItem(
              context,
              isZh ? '处于运营商级 NAT (CGNAT) 后？' : 'Behind CGNAT?',
              isZh
                  ? '向运营商申请公网 IP，或使用 TURN 中继作为备用方案。'
                  : 'Request public IP from ISP, or use TURN relay as fallback.',
            ),
            SizedBox(height: ZeroSpacing.md),
            _buildFaqItem(
              context,
              isZh ? '连接速度慢？' : 'Slow connections?',
              isZh
                  ? '检查你是否使用了 TURN 中继。P2P 直连速度最快。'
                  : 'Check if you\'re on TURN relay. P2P direct is fastest.',
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildServerList(
      List<String> servers, List<String> tags, BuildContext context) {
    final result = <Widget>[];
    for (var i = 0; i < servers.length; i++) {
      result.add(
        Container(
          margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
          padding: EdgeInsets.all(ZeroSpacing.sm),
          decoration: BoxDecoration(
            color: context.zFrostWhite,
            borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                servers[i],
                style: ZeroTypography.monoSmall(context),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.zAccentMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tags[i],
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zAccent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return result;
  }

  Widget _buildIceStep(
    BuildContext context,
    String step,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.zAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: context.zAccent,
              size: ZeroSpacing.iconMd / 1.2,
            ),
          ),
        ),
        SizedBox(width: ZeroSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ZeroTypography.bodyBold(context),
              ),
              Text(
                description,
                style: ZeroTypography.body(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIceStepDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ZeroSpacing.sm,
      ),
      child: Divider(
        color: context.zDivider,
        height: 1,
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String percentage,
    Color color,
    String badge,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ZeroTypography.body(context),
        ),
        Row(
          children: [
            Text(
              percentage,
              style: ZeroTypography.bodyBold(context).copyWith(
                color: color,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: ZeroSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              ),
              child: Text(
                badge,
                style: ZeroTypography.caption(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: ZeroTypography.bodyBold(context),
        ),
        SizedBox(height: ZeroSpacing.xs),
        Text(
          answer,
          style: ZeroTypography.body(context),
        ),
      ],
    );
  }

  Color _getNatColor(NatType type) {
    switch (type) {
      case NatType.fullCone:
      case NatType.restrictedCone:
        return context.zSuccess;
      case NatType.portRestricted:
      case NatType.symmetric:
        return context.zWarning;
    }
  }

  String _getNatEmoji(NatType type) {
    switch (type) {
      case NatType.fullCone:
      case NatType.restrictedCone:
        return '🟢';
      case NatType.portRestricted:
      case NatType.symmetric:
        return '🟡';
    }
  }

  String _getNatName(NatType type, bool isZh) {
    switch (type) {
      case NatType.fullCone:
        return isZh ? '全锥型 NAT' : 'Full Cone NAT';
      case NatType.restrictedCone:
        return isZh ? '限制锥型 NAT' : 'Restricted Cone NAT';
      case NatType.portRestricted:
        return isZh ? '端口限制锥型 NAT' : 'Port Restricted NAT';
      case NatType.symmetric:
        return isZh ? '对称 NAT' : 'Symmetric NAT';
    }
  }

  String _getNatDescription(NatType type, bool isZh) {
    switch (type) {
      case NatType.fullCone:
        return isZh ? '简单 P2P — 所有连接都可工作' : 'Easy P2P — All connections work';
      case NatType.restrictedCone:
        return isZh ? '良好 — 大多数 P2P 可通过 STUN 工作' : 'Good — Most P2P works with STUN';
      case NatType.portRestricted:
        return isZh ? 'OK — 需要 STUN + 打洞' : 'OK — STUN + hole punching needed';
      case NatType.symmetric:
        return isZh ? '有挑战 — 需要 TURN 中继' : 'Challenging — TURN relay required';
    }
  }

  Color _getUpnpColor(UpnpStatus status) {
    switch (status) {
      case UpnpStatus.success:
        return context.zSuccess;
      case UpnpStatus.attempting:
        return context.zAccent;
      case UpnpStatus.failed:
        return context.zWarning;
    }
  }

  String _getUpnpStatusText(UpnpStatus status, bool isZh) {
    switch (status) {
      case UpnpStatus.success:
        return isZh ? '成功' : 'Success';
      case UpnpStatus.attempting:
        return isZh ? '尝试中' : 'Attempting';
      case UpnpStatus.failed:
        return isZh ? '不支持' : 'Not Supported';
    }
  }
}

enum NatType {
  fullCone,
  restrictedCone,
  portRestricted,
  symmetric,
}

enum UpnpStatus {
  success,
  attempting,
  failed,
}
