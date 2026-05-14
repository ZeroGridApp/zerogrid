import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/node/node_service.dart';
import '../../widgets/zero_card.dart';

class ZeroNodeDeployScreen extends StatefulWidget {
  const ZeroNodeDeployScreen({super.key});

  @override
  State<ZeroNodeDeployScreen> createState() => _ZeroNodeDeployScreenState();
}

class _ZeroNodeDeployScreenState extends State<ZeroNodeDeployScreen> {
  final _nodeService = ZeroNodeService();
  int _currentStep = 0;

  String _selectedType = 'relay';
  String _selectedRegion = 'asia-east';
  final _portController = TextEditingController(text: '9744');
  final _storageController = TextEditingController(text: '50');
  bool _autoStart = true;
  bool _natTraversal = true;

  bool _isDeploying = false;
  bool _deployComplete = false;
  NodeStatus? _deployedStatus;
  double _deployProgress = 0.0;

  final _typeOptions = const [
    {
      'value': 'relay',
      'icon': Icons.router_rounded,
      'titleEn': 'Relay Node',
      'titleZh': '中继节点',
      'descEn': 'Onion routing relay. Routes encrypted traffic through the Zero network. Low resource requirements.',
      'descZh': '洋葱路由中继。在 Zero 网络中路由加密流量。低资源需求。',
      'stake': 1000,
    },
    {
      'value': 'storage',
      'icon': Icons.cloud_rounded,
      'titleEn': 'Storage Node',
      'titleZh': '存储节点',
      'descEn': 'DASN distributed storage provider. Contribute disk space and earn ZERO rewards.',
      'descZh': 'DASN 分布式存储提供者。贡献磁盘空间赚取 ZERO 奖励。',
      'stake': 5000,
    },
    {
      'value': 'validator',
      'icon': Icons.verified_rounded,
      'titleEn': 'Validator Node',
      'titleZh': '验证者节点',
      'descEn': 'Consensus validator. Participate in block production and governance voting.',
      'descZh': '共识验证者。参与区块生产和治理投票。',
      'stake': 10000,
    },
    {
      'value': 'full',
      'icon': Icons.dns_rounded,
      'titleEn': 'Full Node',
      'titleZh': '全节点',
      'descEn': 'Complete blockchain node. Full history storage, API serving, and transaction validation.',
      'descZh': '完整区块链节点。全历史存储、API 服务和交易验证。',
      'stake': 2000,
    },
  ];

  final _regionOptions = const [
    {
      'value': 'us-east',
      'titleEn': 'US East',
      'titleZh': '美国东部',
      'flag': '🇺🇸',
      'latency': 42,
      'peers': 312,
    },
    {
      'value': 'us-west',
      'titleEn': 'US West',
      'titleZh': '美国西部',
      'flag': '🇺🇸',
      'latency': 68,
      'peers': 198,
    },
    {
      'value': 'eu-west',
      'titleEn': 'EU West',
      'titleZh': '欧洲西部',
      'flag': '🇪🇺',
      'latency': 35,
      'peers': 287,
    },
    {
      'value': 'asia-east',
      'titleEn': 'Asia East',
      'titleZh': '亚洲东部',
      'flag': '🇸🇬',
      'latency': 15,
      'peers': 356,
    },
    {
      'value': 'asia-south',
      'titleEn': 'Asia South',
      'titleZh': '亚洲南部',
      'flag': '🇮🇳',
      'latency': 58,
      'peers': 142,
    },
  ];

  @override
  void dispose() {
    _portController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final typeInfo = _typeOptions.firstWhere((t) => t['value'] == _selectedType);
    final regionInfo = _regionOptions.firstWhere((r) => r['value'] == _selectedRegion);

    if (_deployComplete && _deployedStatus != null) {
      return _buildSuccessPanel(isZh);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '部署节点' : 'Deploy Node'),
      ),
      body: Column(
        children: [
          _buildStepper(isZh),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
              child: _currentStep == 0
                  ? _buildTypeStep(isZh)
                  : _currentStep == 1
                      ? _buildRegionStep(isZh)
                      : _currentStep == 2
                          ? _buildConfigStep(isZh)
                          : _buildReviewStep(isZh, typeInfo, regionInfo),
            ),
          ),
          _buildBottomBar(isZh, typeInfo),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isZh) {
    final steps = [
      isZh ? '节点类型' : 'Node Type',
      isZh ? '区域' : 'Region',
      isZh ? '配置' : 'Config',
      isZh ? '审查部署' : 'Review',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(bottom: BorderSide(color: context.zFrostWhiteStrong, width: 0.5)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? context.zAccent : context.zFrostWhiteStrong,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? context.zAccent
                        : isCompleted
                            ? context.zAccentMuted
                            : context.zFrostWhiteStrong,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 16, color: context.zBg)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive ? context.zBg : context.zTextTertiary,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? context.zAccent : context.zFrostWhiteStrong,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypeStep(bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZeroSpacing.lg),
        Text(
          isZh ? '选择节点类型' : 'Select Node Type',
          style: ZeroTypography.headline(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          isZh ? '每种节点在 Zero 网络中扮演不同角色，质押要求也不同。' : 'Each node plays a different role in the Zero network with varying stake requirements.',
          style: ZeroTypography.body(context),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ..._typeOptions.map((type) {
          final selected = _selectedType == type['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.md),
            child: ZeroCard(
              onTap: () => setState(() => _selectedType = type['value'] as String),
              padding: const EdgeInsets.all(ZeroSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? context.zAccent.withOpacity(0.15) : context.zFrostWhiteStrong,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? context.zAccent : context.zFrostWhiteStrong,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Icon(
                      type['icon'] as IconData,
                      color: selected ? context.zAccent : context.zTextSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? type['titleZh'] as String : type['titleEn'] as String,
                          style: ZeroTypography.title(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isZh ? type['descZh'] as String : type['descEn'] as String,
                          style: ZeroTypography.caption(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${type['stake']} ZERO',
                        style: ZeroTypography.bodyBold(context).copyWith(color: context.zAccent),
                      ),
                      Text(
                        isZh ? '质押' : 'Stake',
                        style: ZeroTypography.caption(context),
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

  Widget _buildRegionStep(bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZeroSpacing.lg),
        Text(
          isZh ? '选择部署区域' : 'Select Region',
          style: ZeroTypography.headline(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          isZh ? '靠近你的区域延迟更低，连接更稳定。' : 'Regions closer to you offer lower latency and more stable connections.',
          style: ZeroTypography.body(context),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ..._regionOptions.map((region) {
          final selected = _selectedRegion == region['value'];
          final latency = region['latency'] as int;
          final latencyColor = latency < 20
              ? context.zSuccess
              : latency < 50
                  ? context.zWarning
                  : context.zError;

          return Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.md),
            child: ZeroCard(
              onTap: () => setState(() => _selectedRegion = region['value'] as String),
              padding: const EdgeInsets.all(ZeroSpacing.md),
              child: Row(
                children: [
                  Text(
                    region['flag'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? region['titleZh'] as String : region['titleEn'] as String,
                          style: ZeroTypography.title(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${region['peers']} ${isZh ? '个节点' : 'peers'}',
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: latencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: latencyColor.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, size: 14, color: latencyColor),
                        const SizedBox(width: 4),
                        Text(
                          '${latency}ms',
                          style: ZeroTypography.caption(context).copyWith(color: latencyColor),
                        ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: ZeroSpacing.sm),
                    Icon(Icons.check_circle, color: context.zAccent, size: 22),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfigStep(bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZeroSpacing.lg),
        Text(
          isZh ? '节点配置' : 'Node Configuration',
          style: ZeroTypography.headline(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          isZh ? '自定义节点的网络和存储参数。' : 'Customize your node\'s network and storage parameters.',
          style: ZeroTypography.body(context),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ZeroCard(
          padding: const EdgeInsets.all(ZeroSpacing.lg),
          child: Column(
            children: [
              _buildConfigField(
                isZh,
                Icons.settings_ethernet_rounded,
                isZh ? '端口号' : 'Port',
                _portController,
                isZh ? '默认: 9744' : 'Default: 9744',
              ),
              const SizedBox(height: ZeroSpacing.lg),
              _buildConfigField(
                isZh,
                Icons.storage_rounded,
                isZh ? '存储分配 (GB)' : 'Storage Allocation (GB)',
                _storageController,
                isZh ? '推荐: 50-500 GB' : 'Recommended: 50-500 GB',
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ZeroCard(
          padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isZh ? '开机自启' : 'Auto Start',
                  style: ZeroTypography.bodyBold(context),
                ),
                subtitle: Text(
                  isZh ? '设备启动时自动运行节点' : 'Automatically start node on device boot',
                  style: ZeroTypography.caption(context),
                ),
                value: _autoStart,
                onChanged: (v) => setState(() => _autoStart = v),
                activeColor: context.zAccent,
              ),
              Divider(height: 1, color: context.zFrostWhiteStrong),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isZh ? 'NAT 穿透' : 'NAT Traversal',
                  style: ZeroTypography.bodyBold(context),
                ),
                subtitle: Text(
                  isZh ? '自动穿透 NAT 防火墙以改善 P2P 连接' : 'Automatically traverse NAT firewalls for better P2P connectivity',
                  style: ZeroTypography.caption(context),
                ),
                value: _natTraversal,
                onChanged: (v) => setState(() => _natTraversal = v),
                activeColor: context.zAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.xl),
      ],
    );
  }

  Widget _buildConfigField(
    bool isZh,
    IconData icon,
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.zTextSecondary),
        const SizedBox(width: ZeroSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZeroTypography.bodyBold(context)),
              const SizedBox(height: ZeroSpacing.xs),
              TextField(
                controller: controller,
                style: ZeroTypography.mono(context),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: ZeroTypography.caption(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                  filled: true,
                  fillColor: context.zFrostWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(bool isZh, Map<String, dynamic> typeInfo, Map<String, dynamic> regionInfo) {
    final storageGb = int.tryParse(_storageController.text) ?? 50;
    final stake = typeInfo['stake'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZeroSpacing.lg),
        Text(
          isZh ? '审查配置' : 'Review Configuration',
          style: ZeroTypography.headline(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          isZh ? '请确认以下部署信息，确认后将开始部署节点。' : 'Please confirm the deployment details below.',
          style: ZeroTypography.body(context),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ZeroCard(
          padding: const EdgeInsets.all(ZeroSpacing.lg),
          child: Column(
            children: [
              _buildReviewRow(
                isZh ? '节点类型' : 'Node Type',
                isZh ? typeInfo['titleZh'] as String : typeInfo['titleEn'] as String,
                Icons.dns_rounded,
              ),
              _buildDivider(),
              _buildReviewRow(
                isZh ? '部署区域' : 'Region',
                '${regionInfo['flag']} ${isZh ? regionInfo['titleZh'] : regionInfo['titleEn']}',
                Icons.public_rounded,
              ),
              _buildDivider(),
              _buildReviewRow(
                isZh ? '端口' : 'Port',
                _portController.text,
                Icons.settings_ethernet_rounded,
              ),
              _buildDivider(),
              _buildReviewRow(
                isZh ? '存储' : 'Storage',
                '$storageGb GB',
                Icons.storage_rounded,
              ),
              _buildDivider(),
              _buildReviewRow(
                isZh ? '开机自启' : 'Auto Start',
                isZh ? (_autoStart ? '是' : '否') : (_autoStart ? 'Yes' : 'No'),
                Icons.power_settings_new_rounded,
              ),
              _buildDivider(),
              _buildReviewRow(
                isZh ? 'NAT 穿透' : 'NAT Traversal',
                isZh ? (_natTraversal ? '是' : '否') : (_natTraversal ? 'Yes' : 'No'),
                Icons.wifi_find_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.lg),
        ZeroCard(
          padding: const EdgeInsets.all(ZeroSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: context.zAccent, size: 24),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? '质押金额' : 'Stake Amount',
                      style: ZeroTypography.body(context),
                    ),
                    Text(
                      '$stake ZERO',
                      style: ZeroTypography.displayMedium(context).copyWith(color: context.zAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.xl),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.zTextTertiary),
          const SizedBox(width: ZeroSpacing.md),
          Text(label, style: ZeroTypography.body(context)),
          const Spacer(),
          Text(value, style: ZeroTypography.bodyBold(context)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: context.zFrostWhiteStrong);
  }

  Widget _buildBottomBar(bool isZh, Map<String, dynamic> typeInfo) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom,
      ),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(top: BorderSide(color: context.zFrostWhiteStrong, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isDeploying ? null : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  side: BorderSide(color: context.zFrostWhiteStrong),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
                ),
                child: Text(
                  isZh ? '上一步' : 'Back',
                  style: ZeroTypography.bodyBold(context),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: _isDeploying
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    decoration: BoxDecoration(
                      color: context.zAccent,
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(context.zBg),
                          ),
                        ),
                        const SizedBox(width: ZeroSpacing.sm),
                        Text(
                          isZh ? '部署中...' : 'Deploying...',
                          style: ZeroTypography.bodyBold(context).copyWith(color: context.zBg),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _currentStep == 3 ? () => _onDeploy(isZh, typeInfo) : () => setState(() => _currentStep++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.zAccent,
                      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
                    ),
                    child: Text(
                      _currentStep == 3
                          ? (isZh ? '部署节点' : 'Deploy Node')
                          : (isZh ? '下一步' : 'Next'),
                      style: ZeroTypography.bodyBold(context).copyWith(color: context.zBg),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _onDeploy(bool isZh, Map<String, dynamic> typeInfo) {
    setState(() {
      _isDeploying = true;
      _deployProgress = 0.0;
    });

    final config = NodeConfig(
      nodeType: _selectedType,
      region: _selectedRegion,
      port: int.tryParse(_portController.text) ?? 9744,
      autoStart: _autoStart,
      natTraversal: _natTraversal,
      storageGb: int.tryParse(_storageController.text) ?? 50,
      stakeAmount: typeInfo['stake'] as int,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _deployProgress = 0.3);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _deployProgress = 0.6);
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _deployProgress = 0.85);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _nodeService.deployNode(config);
      setState(() {
        _deployProgress = 1.0;
        _deployedStatus = _nodeService.getStatus();
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _isDeploying = false;
          _deployComplete = true;
        });
      });
    });
  }

  Widget _buildSuccessPanel(bool isZh) {
    final status = _deployedStatus!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '部署成功' : 'Deployment Successful'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          children: [
            const SizedBox(height: ZeroSpacing.xxl),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.zSuccess.withOpacity(0.15),
                border: Border.all(color: context.zSuccess, width: 2),
              ),
              child: Icon(Icons.check_rounded, color: context.zSuccess, size: 44),
            ),
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              isZh ? '节点部署成功！' : 'Node Deployed Successfully!',
              style: ZeroTypography.displayMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              isZh ? '你的 Zero 节点已成功部署并连接到网络。' : 'Your Zero node has been deployed and connected to the network.',
              style: ZeroTypography.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ZeroSpacing.xl),
            ZeroCard(
              padding: const EdgeInsets.all(ZeroSpacing.lg),
              child: Column(
                children: [
                  _buildSuccessRow(
                    isZh ? '节点 ID' : 'Node ID',
                    status.nodeId,
                    Icons.fingerprint,
                  ),
                  _buildDivider(),
                  _buildSuccessRow(
                    isZh ? '节点名称' : 'Node Name',
                    status.name,
                    Icons.label_rounded,
                  ),
                  _buildDivider(),
                  _buildSuccessRow(
                    isZh ? '状态' : 'Status',
                    status.status.toUpperCase(),
                    Icons.circle,
                  ),
                  _buildDivider(),
                  _buildSuccessRow(
                    isZh ? '端口' : 'Port',
                    '${_nodeService.getConfig().port}',
                    Icons.settings_ethernet_rounded,
                  ),
                  _buildDivider(),
                  _buildSuccessRow(
                    isZh ? '已连接节点' : 'Peers Connected',
                    '${status.peersConnected}',
                    Icons.people_rounded,
                  ),
                  _buildDivider(),
                  _buildSuccessRow(
                    isZh ? '延迟' : 'Latency',
                    '${status.latency}ms',
                    Icons.speed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeroSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zAccent,
                  padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius)),
                ),
                child: Text(
                  isZh ? '前往监控面板' : 'Go to Monitor',
                  style: ZeroTypography.bodyBold(context).copyWith(color: context.zBg),
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.zTextTertiary),
          const SizedBox(width: ZeroSpacing.md),
          Text(label, style: ZeroTypography.body(context)),
          const Spacer(),
          Text(
            value,
            style: ZeroTypography.mono(context).copyWith(color: context.zTextPrimary),
          ),
        ],
      ),
    );
  }
}