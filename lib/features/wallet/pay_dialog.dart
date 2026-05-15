import 'package:flutter/material.dart';

import 'package:zero/services/wallet/pay_service.dart';
import 'package:zero/services/wallet/rpc_service.dart';
import 'package:zero/services/wallet/bip44_wallet.dart' as bip44;
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

enum _DialogState { confirm, processing, success, failed }

class ZeroPayDialog extends StatelessWidget {
  final PayCommand command;
  final String fromAddress;

  const ZeroPayDialog._({
    required this.command,
    required this.fromAddress,
  });

  static Future<PaymentResult?> show(
    BuildContext context, {
    required PayCommand command,
    required String fromAddress,
  }) {
    return showGeneralDialog<PaymentResult?>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PayDialog',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ZeroPayDialog._(
          command: command,
          fromAddress: fromAddress,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.xl),
          child: _ZeroPayDialogContent(
            command: command,
            fromAddress: fromAddress,
          ),
        ),
      ),
    );
  }
}

class _ZeroPayDialogContent extends StatefulWidget {
  final PayCommand command;
  final String fromAddress;

  const _ZeroPayDialogContent({
    required this.command,
    required this.fromAddress,
  });

  @override
  State<_ZeroPayDialogContent> createState() => _ZeroPayDialogContentState();
}

class _ZeroPayDialogContentState extends State<_ZeroPayDialogContent>
    with TickerProviderStateMixin {
  _DialogState _state = _DialogState.confirm;
  PaymentResult? _result;
  String? _errorMessage;
  double _estimatedFee = 0;
  double _usdPrice = 0;
  String? _feeSymbol;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  late final AnimationController _checkmarkController;
  late final Animation<double> _checkmarkScale;
  late final Animation<double> _checkmarkOpacity;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final _rpc = RpcService();
  final _payService = ZeroPayService();

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkmarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: Curves.elasticOut,
      ),
    );

    _checkmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _loadFeeEstimate();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _checkmarkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _chainId {
    return widget.command.chainId ?? _inferChainId();
  }

  String _inferChainId() {
    final t = (widget.command.token ?? '').toLowerCase();
    const map = {'eth': 'eth', 'bsc': 'bsc', 'bnb': 'bsc', 'btc': 'btc', 'trx': 'trx', 'sol': 'sol'};
    return map[t] ?? 'eth';
  }

  String get _tokenSymbol {
    final fromCmd = widget.command.token;
    if (fromCmd != null && fromCmd.isNotEmpty) return fromCmd.toUpperCase();
    try {
      return bip44.ChainConfig.fromChainId(_chainId.toUpperCase()).symbol;
    } catch (_) {
      return _chainId.toUpperCase();
    }
  }

  String get _chainName {
    try {
      return bip44.ChainConfig.fromChainId(_chainId.toUpperCase()).name;
    } catch (_) {
      return _chainId.toUpperCase();
    }
  }

  Future<void> _loadFeeEstimate() async {
    try {
      final chainConfig = _rpc.getChainConfig(_chainId);
      if (chainConfig != null) {
        _usdPrice = 0.0;
        _feeSymbol = chainConfig.symbol;
      } else {
        _usdPrice = await _rpc.getUsdPrice(_chainId);
        _feeSymbol = _tokenSymbol;
      }

      final toAddr = widget.command.toAddress ?? widget.fromAddress;
      _estimatedFee = await _rpc.estimateFee(
        _chainId,
        widget.fromAddress,
        toAddr,
        widget.command.amount,
      );
    } catch (_) {
      _estimatedFee = 0;
      _usdPrice = 0;
      _feeSymbol = _tokenSymbol;
    }
    if (mounted) setState(() {});
  }

  double get _usdValue => widget.command.amount * _usdPrice;

  String _abbreviate(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  String _abbreviateTxHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}';
  }

  Future<void> _confirmPayment() async {
    setState(() => _state = _DialogState.processing);

    try {
      final result = await _payService.executePayment(widget.command);
      if (!mounted) return;

      setState(() {
        _result = result;
        _state = result.success ? _DialogState.success : _DialogState.failed;
        _errorMessage = result.errorMessage;
      });

      if (result.success) {
        _checkmarkController.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _DialogState.failed;
        _errorMessage = e.toString();
      });
    }
  }

  void _close([PaymentResult? result]) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    switch (_state) {
      case _DialogState.confirm:
        return _buildConfirmState(isZh);
      case _DialogState.processing:
        return _buildProcessingState(isZh);
      case _DialogState.success:
        return _buildSuccessState(isZh);
      case _DialogState.failed:
        return _buildFailedState(isZh);
    }
  }

  Widget _buildConfirmState(bool isZh) {
    final amountStr = widget.command.amount.toString().contains('.')
        ? widget.command.amount.toString().replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : widget.command.amount.toStringAsFixed(0);

    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: ZeroSpacing.sm),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.zAccentGradient,
              boxShadow: [
                BoxShadow(
                  color: context.zAccentGlow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '发送付款' : 'Send Payment',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            '$amountStr $_tokenSymbol',
            style: ZeroTypography.displayMedium(context).copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            '≈ \$${_formatUsd(_usdValue)} USD',
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 14,
              color: context.zTextTertiary,
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Container(
            height: 0.5,
            color: context.zDivider.withOpacity(0.3),
          ),
          const SizedBox(height: ZeroSpacing.md),
          _buildInfoRow(
            Icons.account_balance_wallet_outlined,
            isZh ? '发送方' : 'From',
            _abbreviate(widget.fromAddress),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          _buildInfoRow(
            Icons.arrow_forward_rounded,
            isZh ? '接收方' : 'To',
            widget.command.toIdentity ?? _abbreviate(widget.command.toAddress ?? '—'),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          _buildInfoRow(
            Icons.language_rounded,
            isZh ? '网络' : 'Network',
            _chainName,
          ),
          const SizedBox(height: ZeroSpacing.sm),
          _buildInfoRow(
            Icons.speed_rounded,
            isZh ? '预估费用' : 'Estimated Fee',
            _estimatedFee > 0
                ? '${_estimatedFee.toStringAsFixed(6)} ${_feeSymbol ?? _tokenSymbol}'
                : (isZh ? '计算中...' : 'Calculating...'),
            valueColor: context.zTextSecondary,
          ),
          const SizedBox(height: ZeroSpacing.lg),
          _buildConfirmButton(isZh),
          const SizedBox(height: ZeroSpacing.sm),
          _buildCancelButton(isZh),
          const SizedBox(height: ZeroSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.zTextTertiary),
        const SizedBox(width: ZeroSpacing.sm),
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(color: context.zTextTertiary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: ZeroTypography.monoSmall(context).copyWith(
              color: valueColor ?? context.zTextSecondary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(bool isZh) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.zAccentGradient,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: context.zAccentGlow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
            onTap: _confirmPayment,
            child: Center(
              child: Text(
                isZh ? '确认并支付' : 'Confirm & Pay',
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(bool isZh) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          onTap: () => _close(),
          child: Center(
            child: Text(
              isZh ? '取消' : 'Cancel',
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState(bool isZh) {
    return ZeroCard(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.xl, vertical: ZeroSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: ZeroSpacing.md),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.zAccentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: context.zAccentGlow.withOpacity(_pulseAnimation.value * 0.5),
                      blurRadius: 24 * _pulseAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '正在处理支付...' : 'Processing payment...',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      context.zTextDisabled.withOpacity(0.0),
                      context.zTextSecondary.withOpacity(0.3),
                      context.zTextDisabled.withOpacity(0.0),
                    ],
                    stops: [
                      (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                      _shimmerAnimation.value.clamp(0.0, 1.0),
                      (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds);
                },
                child: Text(
                  isZh ? '请稍候，我们正在处理您的链上交易' : 'Please wait while we process your transaction on the blockchain',
                  style: ZeroTypography.caption(context),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          const SizedBox(height: ZeroSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isZh) {
    final txHash = _result?.txHash ?? '';
    final amountStr = widget.command.amount.toString().contains('.')
        ? widget.command.amount.toString().replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : widget.command.amount.toStringAsFixed(0);

    return ZeroCard(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.xl, vertical: ZeroSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: ZeroSpacing.sm),
          AnimatedBuilder(
            animation: _checkmarkScale,
            builder: (context, child) {
              return Opacity(
                opacity: _checkmarkOpacity.value,
                child: Transform.scale(
                  scale: _checkmarkScale.value,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6BAF7B),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x406BAF7B),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '支付成功' : 'Payment Successful',
            style: ZeroTypography.headline(context).copyWith(
              color: context.zSuccess,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '$amountStr $_tokenSymbol 发送成功' : '$amountStr $_tokenSymbol sent successfully',
            style: ZeroTypography.body(context),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            height: 0.5,
            color: context.zDivider.withOpacity(0.3),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Text(
                isZh ? '交易哈希' : 'Transaction Hash',
                style: ZeroTypography.caption(context),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  _abbreviateTxHash(txHash),
                  style: ZeroTypography.monoSmall(context).copyWith(
                    color: context.zAccent,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          _buildDoneButton(isZh),
          const SizedBox(height: ZeroSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildDoneButton(bool isZh) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.zAccentGradient,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: context.zAccentGlow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
            onTap: () => _close(_result),
            child: Center(
              child: Text(
                isZh ? '完成' : 'Done',
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailedState(bool isZh) {
    final amountStr = widget.command.amount.toString().contains('.')
        ? widget.command.amount.toString().replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : widget.command.amount.toStringAsFixed(0);

    return ZeroCard(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.xl, vertical: ZeroSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: ZeroSpacing.sm),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zError.withOpacity(0.15),
            ),
            child: Icon(
              Icons.close_rounded,
              color: context.zError,
              size: 40,
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '支付失败' : 'Payment Failed',
            style: ZeroTypography.headline(context).copyWith(
              color: context.zError,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '$amountStr $_tokenSymbol 发送失败' : '$amountStr $_tokenSymbol was not sent',
            style: ZeroTypography.body(context),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: ZeroSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              decoration: BoxDecoration(
                color: context.zError.withOpacity(0.06),
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                border: Border.all(
                  color: context.zError.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              child: Text(
                _errorMessage!,
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zError.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: ZeroSpacing.lg),
          _buildRetryButton(isZh),
          const SizedBox(height: ZeroSpacing.sm),
          _buildCloseTextButton(isZh),
          const SizedBox(height: ZeroSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildRetryButton(bool isZh) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.zAccentGradient,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: context.zAccentGlow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
            onTap: _confirmPayment,
            child: Center(
              child: Text(
                isZh ? '重试' : 'Try Again',
                style: ZeroTypography.bodyBold(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseTextButton(bool isZh) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          onTap: () => _close(_result),
          child: Center(
            child: Text(
              isZh ? '关闭' : 'Close',
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatUsd(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    if (value >= 1) return value.toStringAsFixed(2);
    if (value >= 0.01) return value.toStringAsFixed(4);
    return value.toStringAsFixed(6);
  }
}