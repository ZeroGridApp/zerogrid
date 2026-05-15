import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/bridge/bridge_service.dart';
import '../../widgets/zero_card.dart';

class ZeroBridgeScreen extends StatefulWidget {
  const ZeroBridgeScreen({super.key});

  @override
  State<ZeroBridgeScreen> createState() => _ZeroBridgeScreenState();
}

class _ZeroBridgeScreenState extends State<ZeroBridgeScreen> with SingleTickerProviderStateMixin {
  final _bridgeService = ZeroBridgeService();

  late List<BridgeChain> _chains;
  List<BridgeAsset> _fromAssets = [];
  List<BridgeAsset> _toAssets = [];
  List<BridgeTransaction> _transactions = [];

  BridgeChain? _fromChain;
  BridgeChain? _toChain;
  BridgeAsset? _selectedAsset;
  final _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isBridging = false;
  int _bridgeStep = 0;
  String? _bridgingTxId;

  late AnimationController _swapAnimController;
  late Animation<double> _swapAnimation;

  final Set<String> _expandedTxIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();

    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swapAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swapAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _swapAnimController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _chains = _bridgeService.getSupportedChains();
      _transactions = _bridgeService.getRecentTransactions();
      if (_chains.isNotEmpty) {
        _fromChain ??= _chains.firstWhere((c) => c.id == 'zero', orElse: () => _chains.first);
        _toChain ??= _chains.firstWhere((c) => c.id == 'eth', orElse: () => _chains.first);
        _fromAssets = _bridgeService.getAssets(_fromChain!.id);
        _toAssets = _bridgeService.getAssets(_toChain!.id);
        _selectedAsset = _fromAssets.isNotEmpty ? _fromAssets.first : null;
      }
      _isLoading = false;
    });
  }

  void _selectFromChain(BridgeChain chain) {
    if (chain.id == _toChain?.id) {
      setState(() {
        _toChain = _fromChain;
        _toAssets = _bridgeService.getAssets(_toChain!.id);
      });
    }
    setState(() {
      _fromChain = chain;
      _fromAssets = _bridgeService.getAssets(chain.id);
      _selectedAsset = _fromAssets.isNotEmpty ? _fromAssets.first : null;
      _amountController.clear();
    });
  }

  void _selectToChain(BridgeChain chain) {
    if (chain.id == _fromChain?.id) return;
    setState(() {
      _toChain = chain;
      _toAssets = _bridgeService.getAssets(chain.id);
    });
  }

  void _swapChains() {
    if (_fromChain == null || _toChain == null) return;
    _swapAnimController.forward().then((_) {
      setState(() {
        final temp = _fromChain;
        _fromChain = _toChain;
        _toChain = temp;
        _fromAssets = _bridgeService.getAssets(_fromChain!.id);
        _toAssets = _bridgeService.getAssets(_toChain!.id);
        _selectedAsset = _fromAssets.isNotEmpty ? _fromAssets.first : null;
        _amountController.clear();
      });
      _swapAnimController.reset();
    });
  }

  double get _amountValue {
    return double.tryParse(_amountController.text) ?? 0;
  }

  double get _estimatedReceive {
    if (_selectedAsset == null || _amountValue <= 0) return 0;
    final feeRate = _bridgeService.getBridgeFee(_fromChain!.id, _toChain!.id, 100) / 100;
    return _amountValue * (1 - feeRate);
  }

  double get _feeAmount {
    if (_selectedAsset == null || _amountValue <= 0) return 0;
    return _bridgeService.getBridgeFee(
      _fromChain!.id,
      _toChain!.id,
      _amountValue * _selectedAsset!.usdValue,
    );
  }

  Future<void> _executeBridge() async {
    if (_fromChain == null || _toChain == null || _selectedAsset == null) return;
    if (_amountValue <= 0) return;

    final tx = _bridgeService.simulateBridge(
      _fromChain!.id,
      _toChain!.id,
      _selectedAsset!.id,
      _amountValue,
    );

    setState(() {
      _isBridging = true;
      _bridgeStep = 1;
      _bridgingTxId = tx.id;
      _transactions = _bridgeService.getRecentTransactions();
    });

    await Future.delayed(const Duration(seconds: 2));
    _bridgeService.confirmTransaction(tx.id);
    setState(() => _bridgeStep = 2);

    await Future.delayed(const Duration(seconds: 2));
    _bridgeService.confirmTransaction(tx.id);
    setState(() {
      _bridgeStep = 3;
      _transactions = _bridgeService.getRecentTransactions();
    });

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isBridging = false;
      _bridgeStep = 0;
      _bridgingTxId = null;
      _amountController.clear();
    });

    if (mounted) {
      final isZh = ZeroTheme.isZh(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isZh ? '桥接成功！' : 'Bridge completed!',
            style: ZeroTypography.caption(context).copyWith(
              color: context.zTextPrimary,
            ),
          ),
          backgroundColor: context.zSurfaceRaised,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.screenHorizontal,
            vertical: ZeroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          ),
        ),
      );
    }
  }

  Widget _buildChainChip(BridgeChain chain, bool isSelected, bool isDisabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: EdgeInsets.only(right: ZeroSpacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chain.color.withOpacity(0.12)
              : isDisabled
                  ? context.zSurfaceOverlay.withOpacity(0.3)
                  : context.zSurfaceOverlay.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: isSelected
                ? chain.color.withOpacity(0.5)
                : isDisabled
                    ? context.zTextDisabled
                    : context.zFrostWhiteStrong,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chain.icon, style: const TextStyle(fontSize: 16)),
            SizedBox(width: ZeroSpacing.xs),
            Text(
              chain.name,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? context.zTextDisabled
                    : isSelected
                        ? chain.color
                        : context.zTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBridgeStepIndicator() {
    final isZh = ZeroTheme.isZh(context);
    final steps = [
      isZh ? '锁定/销毁' : 'Lock/Burn',
      isZh ? '验证确认' : 'Validating',
      isZh ? '铸造/释放' : 'Mint/Release',
    ];

    return Container(
      padding: EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        border: Border.all(
          color: context.zAccent.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isCompleted = i + 1 < _bridgeStep;
          final isCurrent = i + 1 == _bridgeStep;
          return Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? context.zSuccess
                        : isCurrent
                            ? context.zAccent
                            : context.zSurfaceOverlay,
                    border: Border.all(
                      color: isCompleted
                          ? context.zSuccess
                          : isCurrent
                              ? context.zAccent
                              : context.zFrostWhiteStrong,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : isCurrent
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.zBg,
                              ),
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.zTextTertiary,
                              ),
                            ),
                ),
                SizedBox(height: ZeroSpacing.xs),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? context.zAccent : context.zTextTertiary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionCard(BridgeTransaction tx) {
    final isZh = ZeroTheme.isZh(context);
    final isExpanded = _expandedTxIds.contains(tx.id);

    Color statusColor;
    String statusLabel;
    switch (tx.status) {
      case 'pending':
        statusColor = context.zWarning;
        statusLabel = isZh ? '待处理' : 'Pending';
        break;
      case 'confirming':
        statusColor = context.zAccent;
        statusLabel = isZh ? '确认中' : 'Confirming';
        break;
      case 'completed':
        statusColor = context.zSuccess;
        statusLabel = isZh ? '已完成' : 'Completed';
        break;
      case 'failed':
        statusColor = context.zError;
        statusLabel = isZh ? '失败' : 'Failed';
        break;
      default:
        statusColor = context.zTextTertiary;
        statusLabel = tx.status;
    }

    final timeStr = _formatTime(tx.timestamp);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedTxIds.remove(tx.id);
          } else {
            _expandedTxIds.add(tx.id);
          }
        });
      },
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Column(
          children: [
            Row(
              children: [
                Row(
                  children: [
                    _buildChainIconMini(tx.fromChain),
                    SizedBox(width: ZeroSpacing.xs),
                    Icon(Icons.arrow_forward, size: 14, color: context.zTextTertiary),
                    SizedBox(width: ZeroSpacing.xs),
                    _buildChainIconMini(tx.toChain),
                  ],
                ),
                SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${tx.amount} ${tx.asset}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.zTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(statusLabel, statusColor),
                        ],
                      ),
                      SizedBox(height: ZeroSpacing.xs),
                      Text(
                        '${tx.txHash.substring(0, 10)}...${tx.txHash.substring(tx.txHash.length - 8)}',
                        style: ZeroTypography.monoSmall(context),
                      ),
                      SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: ZeroSpacing.md),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.md),
              Row(
                children: [
                  _buildDetailItem(
                    isZh ? '类型' : 'Type',
                    tx.type == 'burn' ? (isZh ? '销毁/铸造' : 'Burn/Mint') : (isZh ? '锁定/释放' : 'Lock/Release'),
                    Icons.swap_horiz,
                  ),
                  SizedBox(width: ZeroSpacing.lg),
                  _buildDetailItem(
                    isZh ? '手续费' : 'Fee',
                    '\$${tx.fee.toStringAsFixed(2)}',
                    Icons.receipt_long_outlined,
                  ),
                ],
              ),
              SizedBox(height: ZeroSpacing.sm),
              _buildDetailRow(
                isZh ? '交易哈希' : 'TX Hash',
                tx.txHash,
                Icons.link,
              ),
              SizedBox(height: ZeroSpacing.sm),
              _buildDetailRow(
                isZh ? '时间' : 'Time',
                '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}-${tx.timestamp.day.toString().padLeft(2, '0')} '
                    '${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                Icons.access_time,
              ),
            ],
            if (tx.status == 'pending' || tx.status == 'confirming')
              Padding(
                padding: EdgeInsets.only(top: ZeroSpacing.sm),
                child: LinearProgressIndicator(
                  backgroundColor: statusColor.withOpacity(0.1),
                  color: statusColor,
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainIconMini(String symbol) {
    String emoji;
    Color color;
    switch (symbol) {
      case 'ETH':
        emoji = '🔷';
        color = const Color(0xFF627EEA);
        break;
      case 'BSC':
        emoji = '🟡';
        color = const Color(0xFFF0B90B);
        break;
      case 'SOL':
        emoji = '🟣';
        color = const Color(0xFF9945FF);
        break;
      case 'TRX':
        emoji = '🔴';
        color = const Color(0xFFFF0013);
        break;
      case 'ZERO':
        emoji = '⚪';
        color = const Color(0xFF6BAF7B);
        break;
      default:
        emoji = '🔗';
        color = context.zTextTertiary;
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.zTextTertiary),
          SizedBox(width: ZeroSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.zTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.zTextTertiary),
        SizedBox(width: ZeroSpacing.sm),
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(fontSize: 10),
        ),
        SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: ZeroTypography.monoSmall(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final isZh = ZeroTheme.isZh(context);

    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'Just now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.zBg,
        appBar: AppBar(
          backgroundColor: context.zBg,
          elevation: 0,
          title: Text(
            isZh ? '跨链桥' : 'Bridge',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: context.zTextPrimary,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.zTextSecondary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final totalValue = _bridgeService.totalBridgedValue;
    final feeRateStr = _fromChain != null && _toChain != null
        ? '${(_bridgeService.getBridgeFee(_fromChain!.id, _toChain!.id, 100) / 100 * 100).toStringAsFixed(1)}%'
        : '0.3%';

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              isZh ? '跨链桥' : 'Bridge',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: context.zAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.zAccent.withOpacity(0.3),
                  width: 0.5,
                ),
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
                  SizedBox(width: 4),
                  Text(
                    isZh ? '跨链总价值 \$${totalValue.toStringAsFixed(0)}' : 'TVB \$${totalValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.zAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ZeroSpacing.md),
            ZeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [context.zAccent.withOpacity(0.2), context.zCeladon.withOpacity(0.08)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('🌉', style: const TextStyle(fontSize: 20)),
                      ),
                      SizedBox(width: ZeroSpacing.md),
                      Text(
                        isZh ? '跨链桥' : 'Cross-Chain Bridge',
                        style: ZeroTypography.headline(context),
                      ),
                    ],
                  ),
                  SizedBox(height: ZeroSpacing.xs),
                  Text(
                    isZh ? '安全跨链转移资产到 ZeroChain 或从 ZeroChain 转移出去' : 'Securely bridge assets to and from ZeroChain',
                    style: ZeroTypography.body(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: ZeroSpacing.md),
            ZeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZh ? '来源链' : 'From',
                    style: ZeroTypography.caption(context).copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chains.length,
                      itemBuilder: (_, i) {
                        final chain = _chains[i];
                        final isSelected = chain.id == _fromChain?.id;
                        final isDisabled = chain.id == _toChain?.id;
                        return _buildChainChip(
                          chain,
                          isSelected,
                          isDisabled,
                          () => _selectFromChain(chain),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  Center(
                    child: AnimatedBuilder(
                      animation: _swapAnimation,
                      builder: (_, child) => Transform.rotate(
                        angle: _swapAnimation.value * 3.14159,
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: _swapChains,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.zSurfaceOverlay,
                            border: Border.all(
                              color: context.zFrostWhiteStrong,
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.swap_vert,
                            size: 20,
                            color: context.zAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  Text(
                    isZh ? '目标链' : 'To',
                    style: ZeroTypography.caption(context).copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chains.length,
                      itemBuilder: (_, i) {
                        final chain = _chains[i];
                        final isSelected = chain.id == _toChain?.id;
                        final isDisabled = chain.id == _fromChain?.id;
                        return _buildChainChip(
                          chain,
                          isSelected,
                          isDisabled,
                          () => _selectToChain(chain),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
                  SizedBox(height: ZeroSpacing.lg),
                  Text(
                    isZh ? '选择资产' : 'Select Asset',
                    style: ZeroTypography.caption(context).copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  if (_fromAssets.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: context.zSurfaceOverlay.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                        border: Border.all(
                          color: context.zFrostWhiteStrong,
                          width: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BridgeAsset>(
                          value: _selectedAsset,
                          isExpanded: true,
                          dropdownColor: context.zSurfaceRaised,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.zTextPrimary,
                          ),
                          items: _fromAssets.map((asset) {
                            return DropdownMenuItem<BridgeAsset>(
                              value: asset,
                              child: Row(
                                children: [
                                  Text(asset.icon, style: const TextStyle(fontSize: 18)),
                                  SizedBox(width: ZeroSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          asset.symbol,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.zTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          isZh ? '余额: ${asset.balance}' : 'Bal: ${asset.balance}',
                                          style: ZeroTypography.caption(context).copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (asset) {
                            if (asset != null) {
                              setState(() {
                                _selectedAsset = asset;
                                _amountController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: ZeroSpacing.md),
                  Text(
                    isZh ? '数量' : 'Amount',
                    style: ZeroTypography.caption(context).copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: context.zSurfaceOverlay.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                      border: Border.all(
                        color: context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.zTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.zTextTertiary,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ZeroSpacing.md,
                                vertical: ZeroSpacing.md,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_selectedAsset != null) {
                              setState(() {
                                _amountController.text = _selectedAsset!.balance.toString();
                              });
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: ZeroSpacing.sm),
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: context.zAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: context.zAccent.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'MAX',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.zAccent,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: ZeroSpacing.md),
                          child: Text(
                            _selectedAsset?.symbol ?? '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.zTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_amountValue > 0) ...[
                    SizedBox(height: ZeroSpacing.md),
                    ZeroCard(
                      padding: EdgeInsets.all(ZeroSpacing.md),
                      borderRadius: ZeroSpacing.cardRadiusSm,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isZh ? '预计到账' : 'You will receive',
                                style: ZeroTypography.caption(context),
                              ),
                              Text(
                                '${_estimatedReceive.toStringAsFixed(6)} ${_selectedAsset?.symbol ?? ''}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.zSuccess,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_outlined, size: 14, color: context.zTextTertiary),
                                  SizedBox(width: ZeroSpacing.xs),
                                  Text(
                                    isZh ? '桥接手续费' : 'Bridge Fee',
                                    style: ZeroTypography.caption(context),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${_feeAmount.toStringAsFixed(2)} ($feeRateStr)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: context.zTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: context.zTextTertiary),
                                  SizedBox(width: ZeroSpacing.xs),
                                  Text(
                                    isZh ? '预计时间' : 'Est. time',
                                    style: ZeroTypography.caption(context),
                                  ),
                                ],
                              ),
                              Text(
                                isZh ? '约 2-5 分钟' : '~2-5 minutes',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: context.zTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: ZeroSpacing.lg),
                  if (_isBridging) ...[
                    _buildBridgeStepIndicator(),
                    SizedBox(height: ZeroSpacing.md),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_amountValue > 0 && !_isBridging) ? _executeBridge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.zAccent,
                        foregroundColor: context.zBg,
                        elevation: 0,
                        disabledBackgroundColor: context.zSurfaceOverlay,
                        disabledForegroundColor: context.zTextDisabled,
                        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                        ),
                      ),
                      child: Text(
                        _isBridging
                            ? (isZh ? '桥接中...' : 'Bridging...')
                            : (isZh ? '桥接资产' : 'Bridge Assets'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isBridging ? context.zTextDisabled : context.zBg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isZh ? '最近交易' : 'Recent Transactions',
                  style: ZeroTypography.title(context),
                ),
                Text(
                  '${_transactions.length} ${isZh ? '条' : 'txs'}',
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.sm),
            ..._transactions.map((tx) => Padding(
                  padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
                  child: _buildTransactionCard(tx),
                )),
            SizedBox(height: ZeroSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}