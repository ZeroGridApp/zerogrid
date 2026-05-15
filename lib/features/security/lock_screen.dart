import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_logo.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String? title;
  final VoidCallback? onCancel;

  const LockScreen({
    super.key,
    required this.onUnlock,
    this.title,
    this.onCancel,
  });

  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _LockScreenRoute(
            animation: animation,
            child: LockScreen(
              onUnlock: () => Navigator.of(context).pop(true),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return result ?? false;
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenRoute extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _LockScreenRoute({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  static const int _pinLength = 6;
  static const int _maxAttempts = 3;
  static const int _lockoutSeconds = 30;

  late final String _correctPin;

  final List<String> _enteredDigits = [];
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;
  bool _showError = false;
  bool _unlocking = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimationController;
  late final AnimationController _successController;
  late final Animation<double> _successFade;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _correctPin = List.generate(_pinLength, (_) => rng.nextInt(10).toString()).join();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimationController = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(_shakeController);

    _successController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _successFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
    _successScale = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    _successController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onUnlock();
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_isLockedOut || _unlocking) return;
    if (_showError) {
      setState(() => _showError = false);
    }
    if (_enteredDigits.length < _pinLength) {
      setState(() => _enteredDigits.add(digit));
      if (_enteredDigits.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_isLockedOut || _unlocking) return;
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits.removeLast();
        _showError = false;
      });
    }
  }

  void _verifyPin() {
    final entered = _enteredDigits.join();
    if (entered == _correctPin) {
      _onUnlockSuccess();
    } else {
      _onWrongPin();
    }
  }

  void _onUnlockSuccess() {
    setState(() => _unlocking = true);
    _successController.forward();
  }

  void _onWrongPin() {
    _failedAttempts++;
    setState(() {
      _showError = true;
      _enteredDigits.clear();
    });

    _shakeController.forward(from: 0);

    if (_failedAttempts >= _maxAttempts) {
      _startLockout();
    }
  }

  void _startLockout() {
    _isLockedOut = true;
    _lockoutRemaining = _lockoutSeconds;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          _isLockedOut = false;
          _failedAttempts = 0;
          _showError = false;
          timer.cancel();
        }
      });
    });
  }

  void _onEmergencyPressed() {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '紧急警报已发送' : 'Emergency alert sent'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_successFade, _successScale]),
      builder: (context, child) {
        return Opacity(
          opacity: _successFade.value,
          child: Transform.scale(
            scale: _successScale.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const Spacer(),
                  const ZeroLogo(size: 40),
                  const SizedBox(height: ZeroSpacing.lg),
                  Text(
                    widget.title ?? (isZh ? '输入PIN码' : 'Enter PIN'),
                    style: ZeroTypography.title(context),
                  ),
                  const SizedBox(height: ZeroSpacing.xl),
                  _buildDotIndicators(),
                  const SizedBox(height: ZeroSpacing.md),
                  _buildErrorOrLockoutText(isZh),
                  const SizedBox(height: ZeroSpacing.xl),
                  _buildKeypad(),
                  const SizedBox(height: ZeroSpacing.lg),
                  _buildEmergencyButton(isZh),
                  const Spacer(),
                ],
              ),
              if (widget.onCancel != null)
                Positioned(
                  top: ZeroSpacing.sm,
                  left: ZeroSpacing.sm,
                  child: _buildCancelButton(isZh),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(bool isZh) {
    return IconButton(
      icon: const Icon(Icons.close),
      color: context.zTextSecondary,
      onPressed: _isLockedOut ? null : widget.onCancel,
      tooltip: isZh ? '取消' : 'Cancel',
    );
  }

  Widget _buildDotIndicators() {
    return AnimatedBuilder(
      animation: _shakeAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimationController.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (index) {
          final isFilled = index < _enteredDigits.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? context.zAccent
                  : context.zTextDisabled.withOpacity(0.2),
              border: Border.all(
                color: isFilled
                    ? context.zAccent
                    : context.zTextDisabled.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorOrLockoutText(bool isZh) {
    return SizedBox(
      height: 24,
      child: _isLockedOut
          ? Text(
              isZh
                  ? '$_lockoutRemaining秒后重试'
                  : 'Try again in $_lockoutRemaining seconds',
              style: ZeroTypography.caption(context).copyWith(
                color: context.zWarning,
              ),
            )
          : _showError
              ? Text(
                  isZh ? 'PIN码错误' : 'Incorrect PIN',
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zError,
                  ),
                )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBiometricSlot(),
              _buildKeypadButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isLockedOut ? null : () => _onDigitPressed(digit),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zFrostWhite.withOpacity(0.08),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: ZeroTypography.headline(context).copyWith(
                color: _isLockedOut
                    ? context.zTextDisabled
                    : context.zTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isLockedOut ? null : _onDeletePressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zFrostWhite.withOpacity(0.08),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              color: _isLockedOut
                  ? context.zTextDisabled
                  : context.zTextSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricSlot() {
    return const SizedBox(width: 56, height: 56);
  }

  Widget _buildEmergencyButton(bool isZh) {
    return TextButton(
      onPressed: _isLockedOut ? null : _onEmergencyPressed,
      child: Text(
        isZh ? '紧急情况' : 'Emergency',
        style: ZeroTypography.caption(context).copyWith(
          color: context.zWarning,
        ),
      ),
    );
  }
}