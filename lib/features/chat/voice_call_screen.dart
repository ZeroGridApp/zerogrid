import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/call/call_service.dart';

enum _CallState { dialing, connected, ended }

class VoiceCallScreen extends StatefulWidget {
  final String peerName;
  final String peerDid;
  final bool isIncoming;
  final bool isVideo;

  const VoiceCallScreen({
    super.key,
    required this.peerName,
    this.peerDid = 'Z0000000000',
    this.isIncoming = false,
    this.isVideo = false,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _dotsController;
  Timer? _callTimer;
  int _callSeconds = 0;
  bool _muted = false;
  bool _speaker = true;
  bool _videoOn = false;
  bool _accepted = false;
  _CallState _callState = _CallState.dialing;
  String _callId = '';
  bool _showHistory = false;

  final CallService _callService = CallService.instance;

  int _dotsCount = 0;

  @override
  void initState() {
    super.initState();
    _callService.seedDemoHistory();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotsController.addListener(() {
      final newDots = ((_dotsController.value * 4) % 4).floor();
      if (newDots != _dotsCount) {
        setState(() => _dotsCount = newDots);
      }
    });

    final isVideo = widget.isVideo;
    if (!widget.isIncoming) {
      _callId = _callService.startCall(widget.peerName, widget.peerDid, isVideo);
      _startCallSimulation();
    } else {
      _callId = _callService.receiveCall(widget.peerName, widget.peerDid, isVideo);
    }
  }

  void _startCallSimulation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _callService.acceptCall(_callId);
      setState(() => _callState = _CallState.connected);
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _callSeconds++;
        _callService.updateCallDuration(_callId, _callSeconds);
      });
    });
  }

  void _acceptCall() {
    setState(() => _accepted = true);
    _callService.acceptCall(_callId);
    _startCallSimulation();
  }

  void _rejectCall() {
    _callService.rejectCall(_callId);
    Navigator.of(context).pop();
  }

  void _cancelDialing() {
    _callService.rejectCall(_callId);
    Navigator.of(context).pop();
  }

  void _endCall() {
    _callTimer?.cancel();
    _callService.endCall(_callId);
    setState(() => _callState = _CallState.ended);
  }

  void _callAgain() {
    final isVideo = widget.isVideo || _videoOn;
    _callId = _callService.startCall(widget.peerName, widget.peerDid, isVideo);
    _callSeconds = 0;
    _callState = _CallState.dialing;
    _accepted = true;
    _startCallSimulation();
  }

  void _returnToChat() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _dotsController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _timeAgo(DateTime time, bool isZh) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isIncoming && !_accepted) {
      return _buildIncomingCall();
    }
    return _buildCallScreen();
  }

  Widget _buildCallScreen() {
    switch (_callState) {
      case _CallState.dialing:
        return _buildDialing();
      case _CallState.connected:
        return _buildConnected();
      case _CallState.ended:
        return _buildEnded();
    }
  }

  Widget _buildDialing() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildCallingAvatar(),
              const SizedBox(height: ZeroSpacing.lg),
              Text(
                widget.peerName,
                style: ZeroTypography.displayMedium(context).copyWith(
                  color: context.zTextPrimary,
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.voiceConnecting,
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zAccent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '.' * (_dotsCount + 1),
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.lg),
              _encryptedBadge(),
              const SizedBox(height: ZeroSpacing.xs),
              _onionRouteBadge(),
              const Spacer(flex: 2),
              _buildCancelButton(),
              const SizedBox(height: ZeroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnected() {
    final isVideo = widget.isVideo || _videoOn;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildConnectedAvatar(),
              const SizedBox(height: ZeroSpacing.lg),
              Text(
                widget.peerName,
                style: ZeroTypography.headline(context),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Text(
                _formatDuration(_callSeconds),
                style: ZeroTypography.mono(context).copyWith(
                  fontSize: 22,
                  color: context.zSuccess,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: ZeroSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _encryptedBadge(),
                  const SizedBox(width: ZeroSpacing.sm),
                  _onionRouteBadge(),
                ],
              ),
              const Spacer(flex: 2),
              _buildControls(isVideo: isVideo),
              const SizedBox(height: ZeroSpacing.lg),
              _buildEndCallButton(),
              const SizedBox(height: ZeroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnded() {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildEndedAvatar(),
              const SizedBox(height: ZeroSpacing.lg),
              Text(
                widget.peerName,
                style: ZeroTypography.displayMedium(context).copyWith(
                  color: context.zTextPrimary,
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Text(
                isZh ? '通话已结束' : 'Call Ended',
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextSecondary,
                ),
              ),
              const SizedBox(height: ZeroSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.lg,
                  vertical: ZeroSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: context.zFrostWhite,
                  borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                  border: Border.all(
                    color: context.zDivider,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_callSeconds),
                      style: ZeroTypography.displayMedium(context).copyWith(
                        fontSize: 28,
                        color: context.zTextPrimary,
                      ),
                    ),
                    const SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh ? '通话时长' : 'Duration',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ZeroSpacing.md),
              _buildQualityBadge(),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildEndedAction(
                        icon: Icons.chat_bubble_outline,
                        label: isZh ? '返回聊天' : 'Back to Chat',
                        onTap: _returnToChat,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.md),
                    Expanded(
                      child: _buildEndedAction(
                        icon: Icons.call,
                        label: isZh ? '再次呼叫' : 'Call Again',
                        onTap: _callAgain,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ZeroSpacing.lg),
              _buildHistoryToggle(),
              if (_showHistory) _buildHistoryList(),
              if (!_showHistory) const SizedBox(height: ZeroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCall() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              Spacer(flex: 2),
              _buildRingAvatar(),
              SizedBox(height: ZeroSpacing.lg),
              Text(
                widget.peerName,
                style: ZeroTypography.displayMedium(context).copyWith(
                  color: context.zTextPrimary,
                ),
              ),
              SizedBox(height: ZeroSpacing.sm),
              Text(
                l10n.voiceIncomingCall,
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextSecondary,
                ),
              ),
              SizedBox(height: ZeroSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _encryptedBadge(),
                  const SizedBox(width: ZeroSpacing.sm),
                  _onionRouteBadge(),
                ],
              ),
              Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IncomingButton(
                    icon: Icons.call_end_rounded,
                    label: l10n.voiceDecline,
                    color: context.zError,
                    onTap: _rejectCall,
                  ),
                  SizedBox(width: ZeroSpacing.xxl),
                  _IncomingButton(
                    icon: widget.isVideo ? Icons.videocam : Icons.call,
                    label: l10n.voiceAccept,
                    color: context.zSuccess,
                    onTap: _acceptCall,
                  ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallingAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _pulseRing(
              size: 120 + _pulseController.value * 20,
              opacity: 0.06 + _pulseController.value * 0.08,
            ),
            _pulseRing(
              size: 100 + _pulseController.value * 12,
              opacity: 0.1 + _pulseController.value * 0.1,
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.4),
                    context.zCeladon.withOpacity(0.4),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.peerName[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectedAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _pulseRing(
              size: 160 + _pulseController.value * 30,
              opacity: 0.06 + _pulseController.value * 0.08,
            ),
            _pulseRing(
              size: 140 + _pulseController.value * 20,
              opacity: 0.1 + _pulseController.value * 0.1,
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.3),
                    context.zCeladon.withOpacity(0.3),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.peerName[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndedAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _pulseRing(size: 140, opacity: 0.04),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                context.zTextTertiary.withOpacity(0.2),
                context.zTextTertiary.withOpacity(0.1),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.peerName[0].toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w200,
              color: context.zTextTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRingAvatar() {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _pulseRing(
              size: 180 + sin(_ringController.value * 2 * pi) * 20,
              opacity: 0.04 + sin(_ringController.value * 2 * pi) * 0.06,
            ),
            _pulseRing(
              size: 160 + sin(_ringController.value * 2 * pi + 1) * 15,
              opacity: 0.08 + sin(_ringController.value * 2 * pi + 1) * 0.08,
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.3),
                    context.zCeladon.withOpacity(0.3),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.peerName[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pulseRing({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.zAccent.withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }

  Widget _encryptedBadge() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.zFrostWhite,
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(
          color: context.zSuccess.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔒',
            style: TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            isZh ? '端到端加密' : 'E2EE Encrypted',
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 10,
              color: context.zSuccess.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onionRouteBadge() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.zFrostWhite,
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(
          color: context.zAccent.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🧅',
            style: TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            isZh ? '洋葱路由' : 'Onion Routed',
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 10,
              color: context.zAccent.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.zFrostWhite,
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(
          color: context.zSuccess.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_cellular_alt, size: 14, color: context.zSuccess),
          const SizedBox(width: 6),
          Text(
            isZh ? '通话质量: 极佳' : 'Quality: Excellent',
            style: ZeroTypography.caption(context).copyWith(
              color: context.zSuccess.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    final isZh = ZeroTheme.isZh(context);
    return GestureDetector(
      onTap: _cancelDialing,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zError,
              boxShadow: [
                BoxShadow(
                  color: context.zError.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? '取消' : 'Cancel',
            style: ZeroTypography.bodyBold(context).copyWith(
              color: context.zError,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.zError,
          boxShadow: [
            BoxShadow(
              color: context.zError.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildControls({required bool isVideo}) {
    final isZh = ZeroTheme.isZh(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CallButton(
          icon: _muted ? Icons.mic_off : Icons.mic,
          label: _muted ? (isZh ? '取消静音' : 'Unmute') : (isZh ? '静音' : 'Mute'),
          active: !_muted,
          onTap: () => setState(() => _muted = !_muted),
        ),
        const SizedBox(width: ZeroSpacing.md),
        _CallButton(
          icon: _speaker ? Icons.volume_up : Icons.volume_off,
          label: isZh ? '扬声器' : 'Speaker',
          active: _speaker,
          onTap: () => setState(() => _speaker = !_speaker),
        ),
        const SizedBox(width: ZeroSpacing.md),
        _CallButton(
          icon: _videoOn ? Icons.videocam : Icons.videocam_off,
          label: isZh ? '视频' : 'Video',
          active: _videoOn,
          onTap: () => setState(() => _videoOn = !_videoOn),
        ),
      ],
    );
  }

  Widget _buildEndedAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? context.zAccent : context.zSurfaceOverlay,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: isPrimary
              ? null
              : Border.all(
                  color: context.zFrostWhiteStrong,
                  width: 0.5,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? context.zAccent.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white
                  : context.zTextPrimary,
            ),
            const SizedBox(width: ZeroSpacing.sm),
            Text(
              label,
              style: ZeroTypography.bodyBold(context).copyWith(
                fontSize: 15,
                color: isPrimary
                    ? context.zAccent.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white
                    : context.zTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryToggle() {
    final isZh = ZeroTheme.isZh(context);
    return GestureDetector(
      onTap: () => setState(() => _showHistory = !_showHistory),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.lg,
          vertical: ZeroSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showHistory
                  ? (isZh ? '收起通话记录' : 'Hide Call History')
                  : (isZh ? '查看通话记录' : 'View Call History'),
              style: ZeroTypography.caption(context).copyWith(
                color: context.zTextSecondary,
              ),
            ),
            const SizedBox(width: ZeroSpacing.xs),
            Icon(
              _showHistory ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: context.zTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final isZh = ZeroTheme.isZh(context);
    final history = _callService.getCallHistory();
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: ZeroSpacing.lg),
        child: Text(
          isZh ? '暂无通话记录' : 'No call history',
          style: ZeroTypography.caption(context),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        itemCount: history.length,
        separatorBuilder: (_, __) => Divider(
          color: context.zDivider,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final record = history[index];
          return _buildHistoryItem(record);
        },
      ),
    );
  }

  Widget _buildHistoryItem(CallRecord record) {
    final isZh = ZeroTheme.isZh(context);
    final isMissed = record.status == 'missed';
    final isRejected = record.status == 'rejected';

    Color directionColor;
    IconData directionIcon;
    if (record.direction == 'outgoing') {
      directionColor = context.zSuccess;
      directionIcon = Icons.arrow_upward;
    } else if (isMissed) {
      directionColor = context.zError;
      directionIcon = Icons.arrow_downward;
    } else {
      directionColor = const Color(0xFF5B9BD5);
      directionIcon = Icons.arrow_downward;
    }

    final typeIcon = record.type == 'video' ? Icons.videocam : Icons.call;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zSurfaceOverlay,
            ),
            child: Icon(
              typeIcon,
              size: 20,
              color: isMissed ? context.zError : context.zAccent,
            ),
          ),
          const SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.peerName,
                      style: ZeroTypography.bodyBold(context).copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.xs),
                    Icon(
                      directionIcon,
                      size: 12,
                      color: directionColor,
                    ),
                    if (isRejected) ...[
                      const SizedBox(width: ZeroSpacing.xs),
                      Text(
                        isZh ? '已拒绝' : 'Rejected',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zWarning,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isMissed && record.durationSeconds == 0)
                      Text(
                        isZh ? '未接听' : 'Missed',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zError,
                          fontSize: 11,
                        ),
                      )
                    else
                      Text(
                        record.durationFormatted,
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      _timeAgo(record.timestamp, isZh),
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 11,
                        color: context.zTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.zFrostWhite,
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
            ),
            child: Text(
              '🔒',
              style: TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    this.active = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? context.zSurfaceOverlay : context.zSurface,
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: active ? context.zAccent : context.zTextTertiary,
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(
              fontWeight: FontWeight.w500,
              color: context.zTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _IncomingButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            label,
            style: ZeroTypography.bodyBold(context).copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}