import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/chain/zerochain_service.dart';
import '../../widgets/zero_card.dart';

class ZeroChainExplorer extends StatefulWidget {
  const ZeroChainExplorer({super.key});

  @override
  State<ZeroChainExplorer> createState() => _ZeroChainExplorerState();
}

class _ZeroChainExplorerState extends State<ZeroChainExplorer> with TickerProviderStateMixin {
  late final TabController _tabController;
  final _chainService = ZeroChainService();
  Timer? _refreshTimer;
  List<ZeroBlock> _blocks = [];
  List<ZeroTransaction> _transactions = [];
  List<ZeroValidator> _validators = [];
  Map<String, dynamic> _stats = {};
  int _latestBlockNumber = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chainService.start();
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _blocks = _chainService.getLatestBlocks(50);
      _transactions = _chainService.getLatestTransactions(50);
      _validators = _chainService.getValidators();
      _stats = _chainService.getChainStats();
      _latestBlockNumber = _blocks.isNotEmpty ? _blocks.first.number : 0;
    });
  }

  String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _txTypeIcon(String type) {
    switch (type) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'stake':
        return Icons.lock_outline;
      case 'burn':
        return Icons.local_fire_department;
      case 'domain':
        return Icons.language;
      case 'dns':
        return Icons.dns;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _txTypeColor(String type) {
    switch (type) {
      case 'transfer':
        return const Color(0xFF6B9FFF);
      case 'stake':
        return const Color(0xFFC77DFF);
      case 'burn':
        return const Color(0xFFE07B5A);
      case 'domain':
        return const Color(0xFF6BAF7B);
      case 'dns':
        return const Color(0xFFC2A050);
      default:
        return const Color(0xFF6B9FFF);
    }
  }

  String _txTypeLabel(String type, bool isZh) {
    switch (type) {
      case 'transfer':
        return isZh ? '转账' : 'Transfer';
      case 'stake':
        return isZh ? '质押' : 'Stake';
      case 'burn':
        return isZh ? '销毁' : 'Burn';
      case 'domain':
        return isZh ? '域名' : 'Domain';
      case 'dns':
        return 'DNS';
      default:
        return type;
    }
  }

  String _truncateAddress(String addr) {
    if (addr.length <= 20) return addr;
    return '${addr.substring(0, 10)}...${addr.substring(addr.length - 6)}';
  }

  void _showBlockDetail(ZeroBlock block) {
    final blockTxs = _chainService.getTransactionsByBlock(block.number);
    final validator = _validators.firstWhere(
      (v) => v.id == block.validatorId,
      orElse: () => _validators.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isZh = ZeroTheme.isZh(ctx);
        return Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ZeroSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zTextDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          context.zAccent.withOpacity(0.2),
                          context.zAccent.withOpacity(0.08),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${block.number}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.zAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? '区块 #${block.number}' : 'Block #${block.number}',
                          style: ZeroTypography.headline(context),
                        ),
                        SizedBox(height: ZeroSpacing.xs),
                        Text(
                          _formatTimeAgo(block.timestamp),
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              _buildDetailSection(ctx, isZh ? '区块哈希' : 'Block Hash', block.hash, mono: true),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? '前一哈希' : 'Previous Hash', block.previousHash, mono: true),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? '验证者' : 'Validator', '${block.validatorName} (${validator.stake.toStringAsFixed(0)} ZERO stake)'),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? '时间戳' : 'Timestamp', block.timestamp.toString().substring(0, 19)),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? '交易数' : 'Transactions', '${block.txCount} tx'),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? 'ZERO 已销毁' : 'ZERO Burned', '${block.totalZeroBurned.toStringAsFixed(4)} ZERO'),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(ctx, isZh ? '区块大小' : 'Block Size', '${(block.size / 1024).toStringAsFixed(1)} KB'),
              if (blockTxs.isNotEmpty) ...[
                SizedBox(height: ZeroSpacing.lg),
                Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
                SizedBox(height: ZeroSpacing.lg),
                Text(
                  isZh ? '此区块中的交易' : 'Transactions in this Block',
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: ZeroSpacing.sm),
                ...blockTxs.map((tx) => Padding(
                  padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
                  child: Container(
                    padding: EdgeInsets.all(ZeroSpacing.md),
                    decoration: BoxDecoration(
                      color: context.zSurfaceOverlay.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                      border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(_txTypeIcon(tx.type), size: 16, color: _txTypeColor(tx.type)),
                        SizedBox(width: ZeroSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _truncateHash(tx.hash),
                                style: ZeroTypography.monoSmall(context).copyWith(fontSize: 10),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${_truncateAddress(tx.from)} → ${_truncateAddress(tx.to)}',
                                style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${tx.amount.toStringAsFixed(2)} ZERO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.zAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildDetailSection(BuildContext ctx, String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(ctx).copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ZeroSpacing.xs),
        Text(
          value,
          style: (mono ? ZeroTypography.monoSmall(ctx) : ZeroTypography.body(ctx)).copyWith(
            fontSize: mono ? 10 : 14,
            color: ctx.zTextSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              isZh ? '零界链浏览器' : 'ZeroChain Explorer',
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
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.zSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.zSuccess.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.zSuccess,
                      boxShadow: [
                        BoxShadow(
                          color: context.zSuccess.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    isZh ? '测试网 · ${_validators.length} 验证者' : 'Testnet · ${_validators.length} Validators',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.zSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.zAccent,
          labelColor: context.zAccent,
          unselectedLabelColor: context.zTextTertiary,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          tabs: [
            Tab(text: isZh ? '仪表盘' : 'Dashboard'),
            Tab(text: isZh ? '区块' : 'Blocks'),
            Tab(text: isZh ? '交易' : 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBlocksTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final isZh = ZeroTheme.isZh(context);
    final totalBlocks = _stats['totalBlocks'] ?? 0;
    final totalTxs = _stats['totalTxs'] ?? 0;
    final totalBurned = (_stats['totalBurned'] as num?)?.toDouble() ?? 0.0;
    final avgBlockTime = (_stats['avgBlockTime'] as num?)?.toDouble() ?? 3.0;
    final tps = (_stats['tps'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(right: ZeroSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zSuccess,
                  boxShadow: [
                    BoxShadow(
                      color: context.zSuccess.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.sm,
                  vertical: ZeroSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.zSuccess.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: context.zSuccess,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Block #${_blocks.isNotEmpty ? _blocks.first.number : 0}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.zSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ZeroSpacing.sm,
            crossAxisSpacing: ZeroSpacing.sm,
            childAspectRatio: 1.6,
            children: [
              _buildStatCard(isZh ? '总区块数' : 'Total Blocks', '$totalBlocks', Icons.layers, context.zAccent),
              _buildStatCard(isZh ? '总交易数' : 'Total TXs', '$totalTxs', Icons.swap_horiz, context.zCeladon),
              _buildStatCard(isZh ? '总销毁量' : 'Total Burned', '${totalBurned.toStringAsFixed(1)} ZERO', Icons.local_fire_department, const Color(0xFFE07B5A)),
              _buildStatCard(isZh ? '平均出块时间' : 'Avg Block Time', '${avgBlockTime.toStringAsFixed(1)}s', Icons.timer, const Color(0xFFC77DFF)),
            ],
          ),
          SizedBox(height: ZeroSpacing.lg),
          Row(
            children: [
              Text(
                isZh ? '网络 TPS' : 'Network TPS',
                style: ZeroTypography.caption(context).copyWith(
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Text(
                '$tps',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.zAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '验证者' : 'Validators',
            style: ZeroTypography.caption(context).copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ZeroSpacing.sm),
          ..._validators.map((v) => _buildValidatorCard(v, isZh)),
          SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadiusSm,
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.7)),
              SizedBox(width: ZeroSpacing.xs),
              Text(
                label,
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zTextTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatorCard(ZeroValidator validator, bool isZh) {
    final totalStake = _validators.fold<double>(0, (sum, v) => sum + v.stake);
    final stakePercent = ((validator.stake / totalStake) * 100).toStringAsFixed(1);
    final uptimeColor = validator.uptime >= 98
        ? context.zSuccess
        : validator.uptime >= 95
            ? context.zWarning
            : context.zError;

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        borderRadius: ZeroSpacing.cardRadiusSm,
        padding: EdgeInsets.all(ZeroSpacing.md),
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
                      colors: [
                        context.zAccent.withOpacity(0.2),
                        context.zAccent.withOpacity(0.08),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    validator.name[0],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.zAccent,
                    ),
                  ),
                ),
                SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            validator.name,
                            style: ZeroTypography.bodyBold(context),
                          ),
                          SizedBox(width: ZeroSpacing.sm),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: validator.isActive ? context.zSuccess : context.zTextDisabled,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${isZh ? '质押' : 'Stake'}: ${validator.stake.toStringAsFixed(0)} ZERO ($stakePercent%)',
                        style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${validator.rewardEarned.toStringAsFixed(1)} ZERO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.zAccent,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isZh ? '奖励' : 'reward',
                      style: ZeroTypography.caption(context).copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '${validator.blocksProduced} 已产出区块' : '${validator.blocksProduced} blocks produced',
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                      SizedBox(height: ZeroSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: validator.uptime / 100,
                          backgroundColor: context.zFrostWhiteStrong,
                          valueColor: AlwaysStoppedAnimation(uptimeColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ZeroSpacing.md),
                Text(
                  '${validator.uptime.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: uptimeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlocksTab() {
    final isZh = ZeroTheme.isZh(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
      ),
      itemCount: _blocks.length,
      itemBuilder: (_, i) {
        final block = _blocks[i];
        return Padding(
          padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: GestureDetector(
            onTap: () => _showBlockDetail(block),
            child: ZeroCard(
              borderRadius: ZeroSpacing.cardRadiusSm,
              padding: EdgeInsets.all(ZeroSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.sm,
                          vertical: ZeroSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: context.zAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.zAccent.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '#${block.number}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.zAccent,
                          ),
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _truncateHash(block.hash),
                              style: ZeroTypography.monoSmall(context).copyWith(
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatTimeAgo(block.timestamp),
                              style: ZeroTypography.caption(context).copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.sm,
                          vertical: ZeroSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: context.zCeladon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.zCeladon.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${block.txCount} tx',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.zCeladon,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 12, color: context.zTextTertiary),
                      SizedBox(width: ZeroSpacing.xs),
                      Text(
                        block.validatorName,
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                      SizedBox(width: ZeroSpacing.md),
                      Icon(Icons.local_fire_department, size: 12, color: const Color(0xFFE07B5A).withOpacity(0.7)),
                      SizedBox(width: ZeroSpacing.xs),
                      Text(
                        '${block.totalZeroBurned.toStringAsFixed(4)} ${isZh ? 'ZERO 已销毁' : 'ZERO burned'}',
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    final isZh = ZeroTheme.isZh(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
      ),
      itemCount: _transactions.length,
      itemBuilder: (_, i) {
        final tx = _transactions[i];
        final typeColor = _txTypeColor(tx.type);
        return Padding(
          padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: ZeroCard(
            borderRadius: ZeroSpacing.cardRadiusSm,
            padding: EdgeInsets.all(ZeroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: typeColor.withOpacity(0.1),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _txTypeIcon(tx.type),
                        size: 18,
                        color: typeColor,
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _txTypeLabel(tx.type, isZh),
                                style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                              ),
                              SizedBox(width: ZeroSpacing.sm),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: context.zSuccess.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: context.zSuccess.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 10, color: context.zSuccess),
                                    SizedBox(width: 2),
                                    Text(
                                      isZh ? '已确认' : 'confirmed',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: context.zSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            _truncateHash(tx.hash),
                            style: ZeroTypography.monoSmall(context).copyWith(
                              fontSize: 10,
                              color: context.zTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${tx.amount.toStringAsFixed(2)} ZERO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.zAccent,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${isZh ? '费用' : 'Fee'}: ${tx.fee.toStringAsFixed(4)}',
                          style: ZeroTypography.caption(context).copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: ZeroSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 12, color: context.zTextTertiary),
                    SizedBox(width: ZeroSpacing.xs),
                    Expanded(
                      child: Text(
                        '${_truncateAddress(tx.from)} → ${_truncateAddress(tx.to)}',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '#${tx.blockNumber}',
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 10,
                        color: context.zAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}