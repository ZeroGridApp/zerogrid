import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/tokenomics/zero_economics_service.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_button.dart';

class StakingCalculatorScreen extends StatefulWidget {
  const StakingCalculatorScreen({super.key});

  @override
  State<StakingCalculatorScreen> createState() => _StakingCalculatorScreenState();
}

class _StakingCalculatorScreenState extends State<StakingCalculatorScreen> {
  final _amountController = TextEditingController(text: '5000');
  double _duration = 90;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  double get _parsedAmount {
    final text = _amountController.text.trim();
    final value = double.tryParse(text);
    return value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final amount = _parsedAmount;
    final days = _duration.round();
    final tier = StakingCalculator.getTierLevel(amount);
    final apy = StakingCalculator.getTierAPY(amount);
    final rewards = StakingCalculator.calculateRewards(amount, days);
    final schedule = StakingCalculator.calculateRewardSchedule(amount, days);
    final tierLabel = isZh
        ? StakingCalculator.getTierLabelZh(tier)
        : StakingCalculator.getTierLabel(tier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isZh ? '质押计算器' : 'Staking Calculator',
          style: TextStyle(
            fontFamily: isZh ? 'NotoSansSC' : 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZeroSpacing.md),
            _buildAmountSection(isZh, amount, tier, apy, tierLabel),
            const SizedBox(height: ZeroSpacing.md),
            _buildDurationSection(isZh, days, apy, amount),
            const SizedBox(height: ZeroSpacing.md),
            _buildRewardSummary(isZh, amount, rewards, days, apy),
            const SizedBox(height: ZeroSpacing.md),
            _buildRewardChart(isZh, amount, days),
            const SizedBox(height: ZeroSpacing.md),
            _buildScheduleBreakdown(isZh, schedule),
            const SizedBox(height: ZeroSpacing.md),
            _buildTierComparison(isZh),
            const SizedBox(height: ZeroSpacing.md),
            ZeroButton(
              label: isZh ? '开始质押' : 'Start Staking',
              icon: Icons.lock,
              onTap: () {},
            ),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(
    bool isZh,
    double amount,
    int tier,
    double apy,
    String tierLabel,
  ) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '质押金额' : 'Stake Amount',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zFrostWhite,
              borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
              border: Border.all(
                color: context.zAccent.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: ZeroTypography.headline(context).copyWith(
                      color: context.zAccent,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: ZeroTypography.headline(context).copyWith(
                        color: context.zTextDisabled,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.zAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ZERO',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.zBg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              _buildTierBadge(isZh, tier, tierLabel),
              const SizedBox(width: ZeroSpacing.sm),
              _buildApyBadge(apy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(bool isZh, int tier, String label) {
    final tierColors = [
      const Color(0xFFCD7F32),
      const Color(0xFFC0C0C0),
      const Color(0xFFFFD700),
      const Color(0xFFE5E4E2),
      const Color(0xFFB9F2FF),
    ];
    final color = tierColors[(tier - 1).clamp(0, 4)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: ZeroSpacing.xs),
          Text(
            isZh ? '层级 $tier · $label' : 'Tier $tier · $label',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApyBadge(double apy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.zSuccess.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.zSuccess.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        'APY ${apy.toStringAsFixed(1)}%',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.zSuccess,
        ),
      ),
    );
  }

  Widget _buildDurationSection(bool isZh, int days, double apy, double amount) {
    final dailyPercent = apy / 365;

    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '质押时长' : 'Staking Duration',
                style: ZeroTypography.title(context),
              ),
              Text(
                isZh ? '${days}天' : '$days Days',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.zAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: context.zAccent,
              inactiveTrackColor: context.zFrostWhite,
              thumbColor: context.zAccent,
              overlayColor: context.zAccent.withOpacity(0.15),
              valueIndicatorColor: context.zAccent,
              valueIndicatorTextStyle: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.zBg,
              ),
            ),
            child: Slider(
              value: _duration,
              min: 7,
              max: 365,
              divisions: 358,
              label: isZh ? '${_duration.round()}天' : '${_duration.round()}D',
              onChanged: (v) => setState(() => _duration = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '7天' : '7D',
                style: ZeroTypography.caption(context),
              ),
              Text(
                isZh ? '365天' : '365D',
                style: ZeroTypography.caption(context),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isZh ? '日收益率' : 'Daily Rate',
                  style: ZeroTypography.caption(context),
                ),
                Text(
                  '${dailyPercent.toStringAsFixed(4)}%',
                  style: ZeroTypography.monoSmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSummary(
    bool isZh,
    double amount,
    double rewards,
    int days,
    double apy,
  ) {
    final total = amount + rewards;
    final roi = amount > 0 ? (rewards / amount * 100) : 0.0;

    return ZeroCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ZeroSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.zAccent.withOpacity(0.12),
              context.zCeladon.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
        ),
        child: Column(
          children: [
            Text(
              isZh ? '预估总收益' : 'Estimated Total Reward',
              style: ZeroTypography.caption(context),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              '${TokenomicsFormatter.formatZero(rewards)} ZERO',
              style: ZeroTypography.displayMedium(context).copyWith(
                color: context.zAccent,
              ),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh
                  ? '约 ${TokenomicsFormatter.formatUsd(rewards * ZeroTokenomics.currentPrice)} (ROI ${roi.toStringAsFixed(2)}%)'
                  : '≈ ${TokenomicsFormatter.formatUsd(rewards * ZeroTokenomics.currentPrice)} (ROI ${roi.toStringAsFixed(2)}%)',
              style: ZeroTypography.caption(context),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    isZh ? '本金' : 'Principal',
                    '${TokenomicsFormatter.formatZero(amount)} ZERO',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.zDivider,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    isZh ? '收益' : 'Rewards',
                    '${TokenomicsFormatter.formatZero(rewards)} ZERO',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.zDivider,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    isZh ? '总计' : 'Total',
                    '${TokenomicsFormatter.formatZero(total)} ZERO',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: ZeroTypography.caption(context),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.zTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRewardChart(bool isZh, double amount, int days) {
    final points = _generateChartPoints(amount, days);

    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '收益增长曲线' : 'Reward Growth Curve',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _RewardLinePainter(points: points),
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isZh ? '第1天' : 'Day 1',
                style: ZeroTypography.caption(context),
              ),
              Text(
                isZh ? '第${days}天' : 'Day $days',
                style: ZeroTypography.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartPoint> _generateChartPoints(double amount, int days) {
    final points = <_ChartPoint>[];
    final apy = StakingCalculator.getTierAPY(amount);
    final steps = min(days, 30).toDouble();

    for (int i = 0; i <= steps; i++) {
      final day = (days * i / steps).round();
      final reward = amount * (apy / 100) * (day / 365.0);
      points.add(_ChartPoint(day: day, value: reward));
    }
    return points;
  }

  Widget _buildScheduleBreakdown(bool isZh, Map<String, double> schedule) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '收益明细' : 'Reward Breakdown',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          _buildScheduleRow(
            isZh ? '每日' : 'Daily',
            schedule['daily'] ?? 0,
            Icons.today,
          ),
          const Divider(height: ZeroSpacing.md, color: Colors.transparent),
          _buildScheduleRow(
            isZh ? '每周' : 'Weekly',
            schedule['weekly'] ?? 0,
            Icons.view_week,
          ),
          const Divider(height: ZeroSpacing.md, color: Colors.transparent),
          _buildScheduleRow(
            isZh ? '每月' : 'Monthly',
            schedule['monthly'] ?? 0,
            Icons.calendar_month,
          ),
          const Divider(height: ZeroSpacing.md, color: Colors.transparent),
          _buildScheduleRow(
            isZh ? '每年' : 'Yearly',
            schedule['yearly'] ?? 0,
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, double amount, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.zTextTertiary),
        const SizedBox(width: ZeroSpacing.md),
        Text(
          label,
          style: ZeroTypography.body(context),
        ),
        const Spacer(),
        Text(
          '${TokenomicsFormatter.formatZero(amount)} ZERO',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.zAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTierComparison(bool isZh) {
    return ZeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '层级对比' : 'Tier Comparison',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    isZh ? '层级' : 'Tier',
                    style: ZeroTypography.caption(context),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    isZh ? '最低质押' : 'Min Stake',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'APY',
                    style: ZeroTypography.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Divider(color: context.zDivider, height: 1),
          const SizedBox(height: ZeroSpacing.xs),
          ...List.generate(5, (index) {
            final tier = index + 1;
            final minStake = ZeroTokenomics.stakingTiers[index];
            final tierApy = ZeroTokenomics.stakingAPYs[index];
            final tierLabel = isZh
                ? StakingCalculator.getTierLabelZh(tier)
                : StakingCalculator.getTierLabel(tier);
            final isActive = StakingCalculator.getTierLevel(_parsedAmount) == tier;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
              decoration: isActive
                  ? BoxDecoration(
                      color: context.zAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? ZeroSpacing.sm : 0,
                ),
                child: SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            if (isActive)
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: context.zAccent,
                              ),
                            if (isActive)
                              const SizedBox(width: ZeroSpacing.xs),
                            Text(
                              '$tier · $tierLabel',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? context.zAccent
                                    : context.zTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          TokenomicsFormatter.formatZero(minStake),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive
                                ? context.zTextPrimary
                                : context.zTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${tierApy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive
                                ? context.zSuccess
                                : context.zTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final int day;
  final double value;

  const _ChartPoint({required this.day, required this.value});
}

class _RewardLinePainter extends CustomPainter {
  final List<_ChartPoint> points;

  _RewardLinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final maxDay = points.last.day.toDouble();
    final maxValue = points.last.value;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 4; i++) {
      final y = padding + chartHeight * (i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF9BB88C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = padding + (points[i].day / maxDay) * chartWidth;
      final y = padding + chartHeight - (points[i].value / maxValue) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9BB88C).withOpacity(0.3),
          const Color(0xFF9BB88C).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, padding, size.width, chartHeight));

    final fillPath = Path.from(path);
    final lastX = padding + (points.last.day / maxDay) * chartWidth;
    fillPath.lineTo(lastX, padding + chartHeight);
    fillPath.lineTo(padding, padding + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, shadowPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF9BB88C);
    final lastPoint = points.last;
    final dotX = padding + (lastPoint.day / maxDay) * chartWidth;
    final dotY =
        padding + chartHeight - (lastPoint.value / maxValue) * chartHeight;
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RewardLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}