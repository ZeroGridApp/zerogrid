import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/tokenomics/zero_economics_service.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_button.dart';
import 'staking_calculator.dart';

class TokenomicsDashboard extends StatefulWidget {
  const TokenomicsDashboard({super.key});

  @override
  State<TokenomicsDashboard> createState() => _TokenomicsDashboardState();
}

class _TokenomicsDashboardState extends State<TokenomicsDashboard> {
  final _stakingAmountController = TextEditingController(text: '5000');
  final _scrollController = ScrollController();
  int _selectedDuration = 90;
  final List<int> _durations = [30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    _stakingAmountController.addListener(_onStakingChanged);
  }

  @override
  void dispose() {
    _stakingAmountController.removeListener(_onStakingChanged);
    _stakingAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStakingChanged() {
    setState(() {});
  }

  double get _parsedAmount {
    final text = _stakingAmountController.text.trim();
    final value = double.tryParse(text);
    return value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isZh ? 'ZERO 代币经济' : 'ZERO Tokenomics',
          style: TextStyle(
            fontFamily: isZh ? 'NotoSansSC' : 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZeroSpacing.md),
            _buildPriceCard(isZh),
            const SizedBox(height: ZeroSpacing.md),
            _buildDistributionCard(isZh),
            const SizedBox(height: ZeroSpacing.md),
            _buildBurnCard(isZh),
            const SizedBox(height: ZeroSpacing.md),
            _buildStakingCard(isZh),
            const SizedBox(height: ZeroSpacing.md),
            _buildMultiChainGasCard(isZh),
            const SizedBox(height: ZeroSpacing.md),
            _buildGovernanceCard(isZh),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(bool isZh) {
    final circulatingPercent =
        ZeroTokenomics.circulatingSupply / ZeroTokenomics.totalSupply;
    return ZeroCard(
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
                  gradient: context.zAccentGradient,
                ),
                child: Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.zBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZERO',
                    style: ZeroTypography.title(context),
                  ),
                  Text(
                    isZh ? 'Zero Network 原生代币' : 'Zero Network Native Token',
                    style: ZeroTypography.caption(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$0.50',
                style: ZeroTypography.displayMedium(context).copyWith(
                  color: context.zAccent,
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+2.3%',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.zSuccess,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                isZh ? '24h' : '24h',
                style: ZeroTypography.caption(context),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              _buildMetricColumn(
                isZh ? '市值' : 'Market Cap',
                TokenomicsFormatter.formatUsd(ZeroTokenomics.marketCap),
                isZh,
              ),
              const Spacer(),
              _buildMetricColumn(
                isZh ? 'FDV' : 'FDV',
                TokenomicsFormatter.formatUsd(
                  ZeroTokenomics.fullyDilutedValue,
                ),
                isZh,
              ),
              const Spacer(),
              _buildMetricColumn(
                isZh ? '初始价格' : 'Initial',
                '\$${ZeroTokenomics.initialPrice.toStringAsFixed(2)}',
                isZh,
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isZh ? '流通供应' : 'Circulating Supply',
                    style: ZeroTypography.caption(context),
                  ),
                  Text(
                    '${TokenomicsFormatter.formatZero(ZeroTokenomics.circulatingSupply)} / ${TokenomicsFormatter.formatZero(ZeroTokenomics.totalSupply)}',
                    style: ZeroTypography.monoSmall(context),
                  ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: circulatingPercent,
                  minHeight: 6,
                  backgroundColor: context.zFrostWhite,
                  valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
                ),
              ),
              const SizedBox(height: ZeroSpacing.xs),
              Text(
                '${(circulatingPercent * 100).toStringAsFixed(1)}% ${isZh ? '流通中' : 'in circulation'}',
                style: ZeroTypography.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(context),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: ZeroTypography.bodyBold(context),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '代币分配' : 'Token Distribution',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _DistributionPiePainter(),
                  ),
                ),
                const SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildDistributionLegend(isZh),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionLegend(bool isZh) {
    final items = [
      _LegendItem(
        color: context.zAccent,
        label: isZh ? '社区奖励' : 'Community Rewards',
        percentage: '30%',
      ),
      _LegendItem(
        color: context.zCeladon,
        label: isZh ? '生态基金' : 'Ecosystem Fund',
        percentage: '20%',
      ),
      _LegendItem(
        color: context.zWarning,
        label: isZh ? '团队与顾问' : 'Team & Advisors',
        percentage: '15%',
      ),
      _LegendItem(
        color: const Color(0xFF8FA4C0),
        label: isZh ? '投资者' : 'Investors',
        percentage: '12%',
      ),
      _LegendItem(
        color: context.zSuccess,
        label: isZh ? '开发' : 'Development',
        percentage: '10%',
      ),
      _LegendItem(
        color: const Color(0xFFC9A83C),
        label: isZh ? '储备金' : 'Reserve',
        percentage: '8%',
      ),
      _LegendItem(
        color: context.zError,
        label: isZh ? '流动性' : 'Liquidity',
        percentage: '5%',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: ZeroTypography.caption(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    item.percentage,
                    style: ZeroTypography.monoSmall(context),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBurnCard(bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '销毁机制' : 'Burn Mechanism',
                style: ZeroTypography.title(context),
              ),
              Icon(Icons.local_fire_department, color: context.zError, size: 20),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              _buildMetricColumn(
                isZh ? '已销毁' : 'Total Burned',
                TokenomicsFormatter.formatZero(ZeroTokenomics.totalBurned),
                isZh,
              ),
              const Spacer(),
              _buildMetricColumn(
                isZh ? '每笔交易销毁' : 'Burn per Tx',
                '${(ZeroTokenomics.burnRate * 100).toStringAsFixed(2)}%',
                isZh,
              ),
              const Spacer(),
              _buildMetricColumn(
                isZh ? '流通供应' : 'Circulating',
                TokenomicsFormatter.formatZero(ZeroTokenomics.circulatingSupply),
                isZh,
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            padding: const EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zFrostWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isZh ? '通缩预测' : 'Deflationary Projection',
                  style: ZeroTypography.bodyBold(context),
                ),
                const SizedBox(height: ZeroSpacing.sm),
                _buildProjectionRow(isZh, 1, ZeroTokenomics.projectedSupply(1)),
                _buildProjectionRow(isZh, 3, ZeroTokenomics.projectedSupply(3)),
                _buildProjectionRow(isZh, 5, ZeroTokenomics.projectedSupply(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionRow(bool isZh, int years, double supply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isZh ? '${years}年后' : 'Year $years',
            style: ZeroTypography.caption(context),
          ),
          Text(
            TokenomicsFormatter.formatZero(supply),
            style: ZeroTypography.monoSmall(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStakingCard(bool isZh) {
    final amount = _parsedAmount;
    final tier = StakingCalculator.getTierLevel(amount);
    final apy = StakingCalculator.getTierAPY(amount);
    final rewards = StakingCalculator.calculateRewards(amount, _selectedDuration);
    final tierLabel = isZh
        ? StakingCalculator.getTierLabelZh(tier)
        : StakingCalculator.getTierLabel(tier);

    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '质押计算器' : 'Staking Calculator',
                style: ZeroTypography.title(context),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StakingCalculatorScreen(),
                    ),
                  );
                },
                child: Text(
                  isZh ? '详情 →' : 'Details →',
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.zFrostWhite,
                    borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stakingAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: ZeroTypography.bodyBold(context),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: ZeroTypography.body(context).copyWith(
                              color: context.zTextDisabled,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        'ZERO',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.zAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.zAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isZh ? '层级 $tier · $tierLabel' : 'Tier $tier · $tierLabel',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.zAccent,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isZh ? 'APY $apy%' : 'APY $apy%',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.zSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '质押时长' : 'Staking Duration',
            style: ZeroTypography.caption(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            children: _durations
                .map(
                  (d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: d == _durations.last ? 0 : ZeroSpacing.sm,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDuration = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedDuration == d
                                ? context.zAccent.withOpacity(0.15)
                                : context.zFrostWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: _selectedDuration == d
                                ? Border.all(
                                    color: context.zAccent.withOpacity(0.4),
                                    width: 0.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              isZh ? '${d}天' : '${d}D',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedDuration == d
                                    ? context.zAccent
                                    : context.zTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            padding: const EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.zAccent.withOpacity(0.08),
                  context.zCeladon.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isZh ? '预估收益' : 'Est. Rewards',
                  style: ZeroTypography.body(context),
                ),
                Text(
                  '${TokenomicsFormatter.formatZero(rewards)} ZERO',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.zAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiChainGasCard(bool isZh) {
    final chains = ['eth', 'bsc', 'sol', 'trx', 'btc'];
    const chainColors = <String, Color>{
      'eth': Color(0xFF7B8FC0),
      'bsc': Color(0xFFC9A83C),
      'sol': Color(0xFF937BC0),
      'trx': Color(0xFFC4615E),
      'btc': Color(0xFFC89B5E),
    };

    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '多链 Gas 成本' : 'Multi-chain Gas Cost',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh
                ? 'ZERO 作为寄生 Gas 代币的多链对比'
                : 'Cross-chain comparison with ZERO as parasitic gas',
            style: ZeroTypography.caption(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 28,
            child: Row(
              children: [
                SizedBox(
                  width: 75,
                  child: Text(
                    isZh ? '链' : 'Chain',
                    style: ZeroTypography.caption(context),
                  ),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Text(
                    isZh ? '原生 Gas' : 'Native Gas',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'USD',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'ZERO',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: ZeroSpacing.sm),
                SizedBox(
                  width: 80,
                  child: Text(
                    isZh ? '节省' : 'Savings',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Divider(color: context.zDivider, height: 1),
          const SizedBox(height: ZeroSpacing.xs),
          ...chains.map((chainId) {
            final config = GasEstimator.chainConfigs[chainId]!;
            final savings = GasEstimator.getSavingsPercent(chainId);
            final color = chainColors[chainId] ?? context.zAccent;
            final isParasitic = config.zeroPerTx < config.usdPerTx;

            return Padding(
              padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: ZeroSpacing.sm),
                          Text(
                            config.name,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.zTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.sm),
                    Expanded(
                      child: Text(
                        _formatGasNative(config),
                        style: ZeroTypography.monoSmall(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${config.usdPerTx.toStringAsFixed(4)}',
                        style: ZeroTypography.monoSmall(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        TokenomicsFormatter.formatUsd(config.zeroPerTx),
                        style: ZeroTypography.monoSmall(context).copyWith(
                          color: isParasitic ? context.zSuccess : context.zError,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.sm),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isParasitic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.zSuccess.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '↓${savings.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.zSuccess,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.zWarning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ETH',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.zWarning,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatGasNative(GasConfig config) {
    if (config.avgGwei > 0) {
      return '${config.avgGwei} Gwei';
    }
    return TokenomicsFormatter.formatUsd(config.usdPerTx);
  }

  Widget _buildGovernanceCard(bool isZh) {
    const userHolding = 150000.0;
    final totalVotingPower = ZeroTokenomics.circulatingSupply;
    final votingPower = userHolding / totalVotingPower * 100;

    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '治理权重' : 'Governance Weight',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              _buildMetricColumn(
                isZh ? '你的 ZERO' : 'Your ZERO',
                TokenomicsFormatter.formatZero(userHolding),
                isZh,
              ),
              const Spacer(),
              _buildMetricColumn(
                isZh ? '投票权重' : 'Voting Power',
                '${votingPower.toStringAsFixed(2)}%',
                isZh,
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isZh ? '法定人数阈值' : 'Quorum Threshold',
                    style: ZeroTypography.caption(context),
                  ),
                  Text(
                    isZh ? '需 ≥ 10% 投票' : '≥ 10% required',
                    style: ZeroTypography.monoSmall(context),
                  ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: votingPower / 10,
                  minHeight: 6,
                  backgroundColor: context.zFrostWhite,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    votingPower >= 10 ? context.zSuccess : context.zWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Icon(Icons.how_to_vote, size: 16, color: context.zAccent),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? '创建提案成本: 1,000 ZERO' : 'Proposal cost: 1,000 ZERO',
                style: ZeroTypography.body(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });
}

class _DistributionPiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final slices = [
      _PieSlice(0.30, Colors.amber.shade700),
      _PieSlice(0.20, Colors.teal.shade400),
      _PieSlice(0.15, Colors.orange.shade400),
      _PieSlice(0.12, Colors.blueGrey.shade300),
      _PieSlice(0.10, Colors.green.shade500),
      _PieSlice(0.08, const Color(0xFFFFD700)),
      _PieSlice(0.05, Colors.red.shade400),
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    double startAngle = -pi / 2;

    for (final slice in slices) {
      paint.color = slice.color.withOpacity(0.85);
      final sweepAngle = slice.ratio * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 1.5,
      );
      startAngle += sweepAngle;
    }

    canvas.drawCircle(
      center,
      radius * 0.45,
      Paint()..color = Colors.black.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieSlice {
  final double ratio;
  final Color color;

  const _PieSlice(this.ratio, this.color);
}