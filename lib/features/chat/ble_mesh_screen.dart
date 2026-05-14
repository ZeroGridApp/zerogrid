import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/ble/ble_service.dart';
import '../../widgets/zero_card.dart';

class BLEMeshScreen extends StatefulWidget {
  const BLEMeshScreen({super.key});

  @override
  State<BLEMeshScreen> createState() => _BLEMeshScreenState();
}

class _BLEMeshScreenState extends State<BLEMeshScreen>
    with SingleTickerProviderStateMixin {
  final _ble = BLEService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<BLEDevice> _devices = [];
  List<BLEMessage> _messages = [];
  bool _scanning = false;

  late final AnimationController _radarController;
  late final AnimationController _pulseController;
  BLEDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ble.deviceStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
    _ble.messageStream.listen((msg) {
      if (mounted) setState(() => _messages = [..._messages, msg]);
    });
  }

  Future<void> _toggleScan() async {
    if (_scanning) {
      await _ble.stopScanning();
    } else {
      await _ble.startScanning();
    }
    setState(() => _scanning = !_scanning);
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final targetId =
        _selectedDevice?.zeroId ?? _devices.firstOrNull?.zeroId ?? 'Z3K7M2N8XP';
    _ble.sendMessage(targetId, text);
    _msgController.clear();
  }

  void _showDeviceDetail(_BLEDevice device) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeviceDetailSheet(
        device: device,
        onConnect: () {
          setState(() {
            device.connected = true;
            _selectedDevice = device;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.bleDeviceConnected} ${device.displayName}'),
              backgroundColor: context.zSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  int _rssiToBars(int rssi) {
    if (rssi > -50) return 4;
    if (rssi > -65) return 3;
    if (rssi > -75) return 2;
    if (rssi > -85) return 1;
    return 0;
  }

  Color _rssiColor(int rssi) {
    if (rssi > -55) return context.zSuccess;
    if (rssi > -70) return context.zAccent;
    if (rssi > -80) return context.zWarning;
    return context.zTextTertiary;
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              l10n.bleTitle,
              style: ZeroTypography.title(context).copyWith(
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _scanning
                    ? context.zAccentGlow
                    : context.zCeladonGlow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _scanning ? l10n.bleScanningLabel : l10n.bleOfflineLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: _scanning ? context.zAccent : context.zCeladon,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedDevice != null)
            Container(
              margin: EdgeInsets.only(right: ZeroSpacing.sm),
              padding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.zSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                border: Border.all(
                  color: context.zSuccess.withOpacity(0.3),
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
                  SizedBox(width: 6),
                  Text(
                    _selectedDevice!.displayName,
                    style: ZeroTypography.caption(context).copyWith(
                      color: context.zSuccess,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: _scanning
                ? Icon(Icons.bluetooth_connected,
                    color: context.zAccent)
                : Icon(Icons.bluetooth_disabled,
                    color: context.zTextTertiary),
            onPressed: _toggleScan,
            tooltip: _scanning ? (isZh ? '停止扫描' : 'Stop scanning') : (isZh ? '开始扫描' : 'Start scanning'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDeviceSection(),
          Container(
            height: 0.5,
            color: context.zDivider,
          ),
          Expanded(child: _buildMessageSection()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    final l10n = AppLocalizations.of(context);
    final deviceCount = _devices.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _scanning || deviceCount > 0 ? 140 : 200,
      padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.md, ZeroSpacing.md, ZeroSpacing.md, ZeroSpacing.sm),
      child: _scanning && deviceCount == 0
          ? _buildScanningState()
          : deviceCount == 0
              ? _buildEmptyState()
              : _buildDeviceList(deviceCount),
    );
  }

  Widget _buildScanningState() {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _pulseController]),
      builder: (_, __) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _RadarPainter(
                    rotation: _radarController.value * 2 * pi,
                    pulse: _pulseController.value,
                    color: context.zAccent,
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.md),
              Text(
                l10n.bleScanning,
                style: ZeroTypography.body(context).copyWith(
                  color: context.zAccent.withOpacity(0.7),
                ),
              ),
              SizedBox(height: ZeroSpacing.xs),
              Text(
                l10n.bleScanningAuto,
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zTextTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 48,
            color: context.zTextDisabled.withOpacity(0.5),
          ),
          SizedBox(height: ZeroSpacing.md),
          Text(
            l10n.bleNoDevices,
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            l10n.bleNoDevicesHint,
            style: ZeroTypography.caption(context).copyWith(
              color: context.zTextDisabled,
            ),
          ),
          SizedBox(height: ZeroSpacing.md),
          GestureDetector(
            onTap: _toggleScan,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.zAccentMuted.withOpacity(0.4),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth, size: 16, color: context.zAccent),
                  SizedBox(width: ZeroSpacing.sm),
                  Text(
                    l10n.bleStartScan,
                    style: TextStyle(
                      fontFamily: 'Inter',
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
    );
  }

  Widget _buildDeviceList(int deviceCount) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scanning
                          ? context.zAccent
                              .withOpacity(0.4 + _pulseController.value * 0.6)
                          : context.zTextDisabled,
                    ),
                  );
                },
              ),
              SizedBox(width: ZeroSpacing.sm),
              Text(
                '${l10n.bleDiscovered} ($deviceCount)',
                style: ZeroTypography.caption(context).copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: context.zTextTertiary,
                ),
              ),
              Spacer(),
              if (_scanning)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: context.zAccent.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: deviceCount,
            separatorBuilder: (_, __) =>
                const SizedBox(width: ZeroSpacing.sm),
            itemBuilder: (_, i) {
              final d = _devices[i];
              final bars = _rssiToBars(d.rssi);
              final rssiColor = _rssiColor(d.rssi);
              final isConnected = d.connected;

              return GestureDetector(
                onTap: () => _showDeviceDetail(d),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 150,
                  padding: EdgeInsets.all(ZeroSpacing.md - 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? context.zSurfaceRaised
                        : context.zSurface,
                    borderRadius:
                        BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                    border: Border.all(
                      color: isConnected
                          ? context.zSuccess.withOpacity(0.3)
                          : context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                    boxShadow: isConnected
                        ? [
                            BoxShadow(
                              color: context.zSuccess.withOpacity(0.08),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? context.zSuccess.withOpacity(0.1)
                                  : context.zFrostWhite,
                            ),
                          ),
                          Icon(
                            isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            size: 22,
                            color: isConnected
                                ? context.zSuccess
                                : context.zAccent.withOpacity(0.6),
                          ),
                          if (isConnected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.zSuccess,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 8,
                                  color: context.zBg,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        d.displayName,
                        style: ZeroTypography.bodyBold(context).copyWith(
                          fontSize: 13,
                          color: isConnected
                              ? context.zSuccess
                              : context.zTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 3,
                            height: 6.0 + index * 4.0,
                            margin: EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: index < bars
                                  ? rssiColor
                                  : context.zTextDisabled.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${d.rssi} dBm',
                        style: ZeroTypography.monoSmall(context).copyWith(
                          color: rssiColor,
                          fontSize: 10,
                        ),
                      ),
                      if (d.zeroId != null)
                        Text(
                          d.zeroId!,
                          style: ZeroTypography.monoSmall(context).copyWith(
                            color: context.zAccent.withOpacity(0.5),
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!isConnected)
                        Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.bleTapConnect,
                            style: ZeroTypography.caption(context).copyWith(
                              fontSize: 9,
                              color: context.zTextDisabled,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    final l10n = AppLocalizations.of(context);

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: context.zTextDisabled.withOpacity(0.5),
            ),
            SizedBox(height: ZeroSpacing.md),
            Text(
              _selectedDevice != null
                  ? l10n.bleStartChat
                  : l10n.bleNoMessages,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            Text(
              l10n.bleEncryptedHint,
              style: ZeroTypography.caption(context).copyWith(
                color: context.zTextDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(ZeroSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMe = msg.senderId == 'Z8P2K5W1RT';

        return Padding(
          padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.zAccent.withOpacity(0.15),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.bluetooth,
                      size: 14, color: context.zAccent),
                ),
                SizedBox(width: ZeroSpacing.sm),
              ],
              Flexible(
                child: ZeroCard(
                  padding: EdgeInsets.all(ZeroSpacing.md - 4),
                  borderRadius: ZeroSpacing.cardRadiusSm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.bleTitle,
                            style: ZeroTypography.caption(context).copyWith(
                              fontSize: 9,
                              color: context.zAccent,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (msg.delivered)
                            Icon(Icons.check,
                                size: 10, color: context.zSuccess)
                          else
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: context.zWarning,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                SizedBox(width: ZeroSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.zCeladon.withOpacity(0.3),
                        context.zAccent.withOpacity(0.3),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isZh ? '我' : 'Me',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.zAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          ZeroSpacing.md, ZeroSpacing.sm, ZeroSpacing.md, ZeroSpacing.lg),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(
          top: BorderSide(color: context.zDivider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: ZeroTypography.body(context),
              cursorColor: context.zAccent,
              decoration: InputDecoration(
                hintText: _selectedDevice != null
                    ? l10n.messagePlaceholder
                    : l10n.bleMessageHint,
                hintStyle: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.zBg,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.md,
                  vertical: ZeroSpacing.md - 4,
                ),
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.sm),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.zAccent, context.zCeladon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.send_rounded,
                  size: 18, color: context.zBg),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final Color color;

  const _RadarPainter({
    required this.rotation,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * 0.3 * i * (0.8 + pulse * 0.2),
        ringPaint,
      );
    }

    final centerDotPaint = Paint()
      ..color = color.withOpacity(0.4 + pulse * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3, centerDotPaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: rotation - pi / 6,
        endAngle: rotation + pi / 6,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.9, sweepPaint);

    final linePaint = Paint()
      ..color = color.withOpacity(0.2 + pulse * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawLine(const Offset(0, 0), Offset(radius * 0.85, 0), linePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}

class _DeviceDetailSheet extends StatelessWidget {
  final BLEDevice device;
  final VoidCallback onConnect;

  const _DeviceDetailSheet({
    required this.device,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.zSurfaceRaised,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ZeroSpacing.cardRadius),
          topRight: Radius.circular(ZeroSpacing.cardRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        ZeroSpacing.lg,
        ZeroSpacing.lg,
        ZeroSpacing.lg,
        ZeroSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.zFrostWhiteStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: ZeroSpacing.lg),
          Container(
            width: 72,
            height: 72,
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
            child: Icon(Icons.bluetooth,
                size: 32, color: context.zAccent),
          ),
          SizedBox(height: ZeroSpacing.md),
          Text(
            device.displayName,
            style: ZeroTypography.headline(context),
          ),
          SizedBox(height: ZeroSpacing.xs),
          if (device.zeroId != null)
            Text(
              device.zeroId!,
              style: ZeroTypography.mono(context).copyWith(
                color: context.zAccent,
              ),
            ),
          SizedBox(height: ZeroSpacing.lg),
          _detailRow(context, l10n.bleDeviceId, device.deviceId),
          SizedBox(height: ZeroSpacing.sm),
          _detailRow(context, l10n.bleSignal, '${device.rssi} dBm'),
          SizedBox(height: ZeroSpacing.sm),
          _detailRow(context, l10n.bleStatus,
              device.connected ? l10n.bleConnected : l10n.bleDisconnected),
          SizedBox(height: ZeroSpacing.sm),
          _detailRow(context, l10n.bleZeroId,
              device.zeroId ?? (isZh ? '未认证' : 'Not authenticated')),
          SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: device.connected ? null : onConnect,
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: ZeroSpacing.md + 2),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(ZeroSpacing.buttonRadius),
                  gradient: device.connected
                      ? null
                      : LinearGradient(
                          colors: [context.zAccent, context.zCeladon],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: device.connected
                      ? context.zSurfaceOverlay
                      : null,
                  border: device.connected
                      ? Border.all(
                          color: context.zFrostWhiteStrong, width: 0.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  device.connected ? l10n.bleAlreadyConnected : l10n.bleConnect,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: device.connected
                        ? context.zSuccess
                        : context.zBg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            color: context.zTextTertiary,
          ),
        ),
        Text(
          value,
          style: ZeroTypography.monoSmall(context).copyWith(
            color: context.zTextSecondary,
          ),
        ),
      ],
    );
  }
}