import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/wallet/bip44_wallet.dart';
import '../../services/wallet/pay_service.dart';
import '../../services/onion/onion_chat_service.dart';
import '../wallet/pay_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String peerName;

  const ChatScreen({super.key, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showAttachments = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  late final AnimationController _recordPulse;

  late List<_Message> _messages;
  final _onionChat = OnionChatService();

  @override
  void initState() {
    super.initState();
    _recordPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _messages = [
      _Message(text: AppLocalizations.of(context).encryptedMessage, type: MsgType.system, time: '10:00'),
      _Message(text: _onionChat.hasCircuit ? '🧅 ${_onionChat.activeCircuit!.nodePath.join(' → ')}' : '🧅 Onion circuit pending...', type: MsgType.system, time: '10:00'),
      _Message(text: 'GM! 今天有什么新进展？', type: MsgType.text, isMe: false, time: '10:01'),
      _Message(text: '很好，加密层已经通过审计了 🎉', type: MsgType.text, isMe: true, time: '10:02'),
      _Message(type: MsgType.image, isMe: false, time: '10:02', imageLabel: 'encryption_audit.png'),
      _Message(text: '太好了！那我们下一步就可以开始集成多链钱包了', type: MsgType.text, isMe: false, time: '10:03'),
      _Message(text: '对，BTC/ETH/BSC/TRX/SOL 五链并行，一个助记词全搞定', type: MsgType.text, isMe: true, time: '10:04'),
      _Message(type: MsgType.file, isMe: true, time: '10:04', fileName: 'Zero_Whitepaper_v2.pdf', fileSize: '2.4 MB'),
      _Message(text: '靠谱，Zero 越来越完整了', type: MsgType.text, isMe: false, time: '10:05'),
      _Message(type: MsgType.voice, isMe: false, time: '10:05', voiceDuration: '0:18'),
      _Message(type: MsgType.location, isMe: false, time: '10:06', locationLabel: 'Crypto Café · 1.2km'),
    ];
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recordPulse.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final payService = ZeroPayService();
    final payCommand = payService.parsePayCommand(text);

    if (payCommand != null) {
      _controller.clear();
      _focusNode.requestFocus();
      _handlePayCommand(payCommand);
      return;
    }

    setState(() {
      final routed = _onionChat.sendMessage(text);
      _messages.add(_Message(
        text: text,
        type: MsgType.text,
        isMe: true,
        time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        onionRoute: routed.result.success ? routed.routeSummary : null,
      ));
    });
    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  Future<void> _handlePayCommand(PayCommand payCommand) async {
    final bip44 = Bip44Wallet();
    bip44.initWithMnemonic('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');
    final wallets = bip44.deriveAllWallets();
    String fromAddress = '';
    if (wallets.isNotEmpty) {
      fromAddress = wallets.first.address;
    }
    final result = await ZeroPayDialog.show(context, command: payCommand, fromAddress: fromAddress);
    if (result == null) return;

    final now = DateTime.now();
    setState(() {
      _messages.add(_Message(
        type: MsgType.pay,
        isMe: true,
        time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        payResult: result,
        payCommand: payCommand,
      ));
    });
    _scrollToBottom();
  }

  void _pickImageFromDevice({required bool fromCamera}) {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    if (fromCamera) {
      input.setAttribute('capture', 'environment');
    }
    input.click();
    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((e) {
        final dataUrl = reader.result as String;
        setState(() {
          _messages.add(_Message(
            type: MsgType.image,
            isMe: true,
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            imageLabel: file.name,
            base64Data: dataUrl,
          ));
          _showAttachments = false;
        });
        _scrollToBottom();
      });
    });
  }

  void _sendRealLocation() {
    html.window.navigator.geolocation.getCurrentPosition().then((pos) {
      final lat = pos.coords!.latitude!.toStringAsFixed(4);
      final lng = pos.coords!.longitude!.toStringAsFixed(4);
      setState(() {
        _messages.add(_Message(
          type: MsgType.location,
          isMe: true,
          time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          locationLabel: '📍 $lat, $lng\n${_getCityHint(pos.coords!.latitude!.toDouble(), pos.coords!.longitude!.toDouble())}',
        ));
        _showAttachments = false;
      });
      _scrollToBottom();
    }).catchError((_) {
      final isZh = ZeroTheme.isZh(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请允许位置权限' : 'Please allow location access')),
      );
    });
  }

  String _getCityHint(double lat, double lng) {
    if (lat > 35 && lat < 42 && lng > 116 && lng < 118) return 'Nearby: Beijing, China';
    if (lat > 30 && lat < 32 && lng > 121 && lng < 122) return 'Nearby: Shanghai, China';
    if (lat > 22 && lat < 23 && lng > 113 && lng < 115) return 'Nearby: Shenzhen, China';
    if (lat > 40 && lat < 41 && lng > -74.1 && lng < -73.5) return 'Nearby: New York, USA';
    if (lat > 51 && lat < 52 && lng > -0.2 && lng < 0.1) return 'Nearby: London, UK';
    if (lat > 35 && lat < 36 && lng > 139 && lng < 140) return 'Nearby: Tokyo, Japan';
    if (lat > 37 && lat < 38 && lng > 126 && lng < 127) return 'Nearby: Seoul, Korea';
    if (lat > 48 && lat < 49 && lng > 2 && lng < 3) return 'Nearby: Paris, France';
    return 'Nearby area';
  }

  void _pickFile() {
    final input = html.FileUploadInputElement();
    input.accept = '*';
    input.click();
    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((e) {
        final dataUrl = reader.result as String;
        setState(() {
          _messages.add(_Message(
            type: MsgType.file,
            isMe: true,
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            fileName: file.name,
            fileSize: _formatFileSize(file.size!),
            base64Data: dataUrl,
          ));
          _showAttachments = false;
        });
        _scrollToBottom();
      });
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showGifPicker() {
    final isZh = ZeroTheme.isZh(context);
    setState(() => _showAttachments = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _GifPickerSheet(
        isZh: isZh,
        onSelect: (emoji) {
          Navigator.pop(ctx);
          setState(() {
            _messages.add(_Message(
              type: MsgType.gif,
              isMe: true,
              time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              imageLabel: emoji,
            ));
          });
          _scrollToBottom();
        },
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordPulse.repeat(reverse: true);
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _recordPulse.stop();
      _recordPulse.reset();
      final dur = _recordingSeconds;
      _messages.add(_Message(
        type: MsgType.voice,
        isMe: true,
        time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        voiceDuration: '0:${dur.toString().padLeft(2, '0')}',
      ));
      _recordingSeconds = 0;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [context.zAccent.withOpacity(0.3), context.zCeladon.withOpacity(0.3)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.peerName[0].toUpperCase(),
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: context.zAccent),
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.zTextPrimary)),
                Text(l10n.e2eeOnline, style: ZeroTypography.caption(context).copyWith(color: context.zSuccess, fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.call_outlined, color: context.zTextSecondary), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam_outlined, color: context.zTextSecondary), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_horiz, color: context.zTextSecondary), onPressed: () {}),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
          setState(() => _showAttachments = false);
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal, vertical: ZeroSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _MessageBubble(message: _messages[index], peerName: widget.peerName),
              ),
            ),
            if (_isRecording) _buildRecordingBar(),
            if (_showAttachments) _buildAttachmentBar(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
      color: context.zSurface,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _recordPulse,
            builder: (_, child) => Container(
              width: 12, height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.zError.withOpacity(0.3 + _recordPulse.value * 0.7)),
            ),
          ),
          SizedBox(width: ZeroSpacing.sm),
          Text('${AppLocalizations.of(context).recording} ${_recordingSeconds}s', style: ZeroTypography.caption(context).copyWith(color: context.zError)),
          Spacer(),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: 6),
              decoration: BoxDecoration(color: context.zError, borderRadius: BorderRadius.circular(8)),
              child: Text(AppLocalizations.of(context).recordingSend, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBar() {
    return Container(
      padding: EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(color: context.zSurface, border: Border(top: BorderSide(color: context.zDivider, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AttachButton(icon: Icons.camera_alt_outlined, label: AppLocalizations.of(context).attachCamera, onTap: () => _pickImageFromDevice(fromCamera: true)),
          _AttachButton(icon: Icons.image_outlined, label: AppLocalizations.of(context).attachPhoto, onTap: () => _pickImageFromDevice(fromCamera: false)),
          _AttachButton(icon: Icons.insert_drive_file_outlined, label: AppLocalizations.of(context).attachFile, onTap: _pickFile),
          _AttachButton(icon: Icons.location_on_outlined, label: AppLocalizations.of(context).attachLocation, onTap: _sendRealLocation),
          _AttachButton(icon: Icons.gif_box_outlined, label: AppLocalizations.of(context).attachGIF, onTap: _showGifPicker),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final text = _controller.text;
    final showHint = text.trim().isNotEmpty && text.trim().startsWith('/');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHint) _buildCommandHint(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildCommandHint() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md + ZeroSpacing.sm, vertical: ZeroSpacing.xs),
      decoration: BoxDecoration(
        color: context.zBg,
        border: Border(top: BorderSide(color: context.zDivider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow('/pay <amount> <token> [to <address>] — Send crypto'),
          SizedBox(height: 2),
          _hintRow('/request <amount> <token> — Request payment'),
        ],
      ),
    );
  }

  Widget _hintRow(String text) {
    return Row(
      children: [
        Icon(Icons.terminal, size: 10, color: context.zAccent.withOpacity(0.5)),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            color: context.zTextTertiary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(ZeroSpacing.sm, ZeroSpacing.sm, ZeroSpacing.sm, ZeroSpacing.lg),
      decoration: BoxDecoration(color: context.zSurface, border: Border(top: BorderSide(color: context.zDivider, width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAttachments = !_showAttachments),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: context.zBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(
                _showAttachments ? Icons.close : Icons.add_rounded,
                size: 22, color: context.zTextSecondary,
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.xs),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.zBg,
                borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).messagePlaceholder,
                  hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
                  contentPadding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.xs),
          if (_controller.text.isEmpty)
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.zBg),
                child: Icon(Icons.mic_none_rounded, size: 22, color: context.zTextSecondary),
              ),
            )
          else
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [context.zAccent, context.zCeladon], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Icon(Icons.arrow_upward_rounded, size: 20, color: context.zBg),
              ),
            ),
        ],
      ),
    );
  }
}

class _GifPickerSheet extends StatefulWidget {
  final bool isZh;
  final void Function(String) onSelect;

  const _GifPickerSheet({required this.isZh, required this.onSelect});

  @override
  State<_GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<_GifPickerSheet> {
  final _searchController = TextEditingController();

  static const _emojis = [
    '👍', '😂', '🔥', '💯', '🎉', '❤️', '🚀', '👋', '🙏',
    '😍', '🤩', '🥳', '💪', '✨', '🌟', '💖', '🎊', '😎', '👏', '🙌',
  ];

  List<String> get _filteredEmojis {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _emojis;
    return _emojis.where((e) => _emojiName(e).toLowerCase().contains(query)).toList();
  }

  String _emojiName(String emoji) {
    switch (emoji) {
      case '👍': return 'thumbs up';
      case '😂': return 'laugh';
      case '🔥': return 'fire';
      case '💯': return '100';
      case '🎉': return 'party';
      case '❤️': return 'heart';
      case '🚀': return 'rocket';
      case '👋': return 'wave';
      case '🙏': return 'pray';
      case '😍': return 'heart eyes';
      case '🤩': return 'star eyes';
      case '🥳': return 'celebrate';
      case '💪': return 'strong';
      case '✨': return 'sparkle';
      case '🌟': return 'star';
      case '💖': return 'sparkle heart';
      case '🎊': return 'confetti';
      case '😎': return 'cool';
      case '👏': return 'clap';
      case '🙌': return 'raised hands';
      default: return '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEmojis;
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isZh ? '选择 GIF' : 'Choose a GIF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.zTextPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.isZh ? '搜索表情...' : 'Search emoji...',
              hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary, fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: context.zTextTertiary),
              filled: true,
              fillColor: context.zBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.isZh ? '没有找到表情' : 'No emojis found',
                      style: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => widget.onSelect(filtered[i]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.zBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(filtered[i], style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

enum MsgType { text, image, voice, file, location, system, pay, gif }

class _Message {
  final String text;
  final MsgType type;
  final bool isMe;
  final String time;
  final String? imageLabel;
  final String? fileName;
  final String? fileSize;
  final String? voiceDuration;
  final String? locationLabel;
  final PaymentResult? payResult;
  final PayCommand? payCommand;
  final String? onionRoute;
  final String? base64Data;

  const _Message({
    this.text = '',
    required this.type,
    this.isMe = true,
    required this.time,
    this.imageLabel,
    this.fileName,
    this.fileSize,
    this.voiceDuration,
    this.locationLabel,
    this.payResult,
    this.payCommand,
    this.onionRoute,
    this.base64Data,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final String peerName;

  const _MessageBubble({required this.message, required this.peerName});

  @override
  Widget build(BuildContext context) {
    if (message.type == MsgType.system) return _buildSystemMessage(context);
    if (message.type == MsgType.pay) return _buildPayCard(context);

    final isMe = message.isMe;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMe)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(peerName, style: ZeroTypography.caption(context).copyWith(fontWeight: FontWeight.w600, fontSize: 10)),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe ? context.zSurfaceOverlay : context.zSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
              ),
              border: Border.all(color: isMe ? context.zAccent.withOpacity(0.08) : context.zFrostWhiteStrong, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildMessageContent(context, isMe),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.time, style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(Icons.check, size: 12, color: context.zSuccess.withOpacity(0.6)),
                ],
              ],
            ),
          ),
          if (message.onionRoute != null)
            Padding(
              padding: EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_rounded, size: 10, color: context.zAccent.withOpacity(0.6)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      message.onionRoute!,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 8,
                        color: context.zAccent.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.xs),
          decoration: BoxDecoration(color: context.zFrostWhite, borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 10, color: context.zSuccess.withOpacity(0.6)),
              SizedBox(width: 4),
              Text(message.text, style: ZeroTypography.caption(context).copyWith(color: context.zSuccess.withOpacity(0.6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayCard(BuildContext context) {
    final result = message.payResult;
    final command = message.payCommand;

    if (result == null || command == null) return const SizedBox.shrink();

    final isPay = command.action == 'pay';
    final isSuccess = result.success;
    final token = (command.token ?? command.chainId ?? 'ETH').toUpperCase();
    final amount = command.amount;
    final chainId = command.chainId ?? 'eth';

    final chainIcon = _chainIcon(chainId);
    final chainName = _chainName(chainId);
    final txHash = result.txHash ?? '';
    final txShort = txHash.isNotEmpty ? '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 6)}' : '';
    final title = isPay ? (isSuccess ? '💰 Payment Sent' : '❌ Payment Failed') : (isSuccess ? '📥 Payment Requested' : '❌ Request Failed');

    final timestampStr = '${result.timestamp.hour.toString().padLeft(2, '0')}:${result.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuccess ? context.zSuccess.withOpacity(0.3) : context.zError.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSuccess ? context.zSuccess : context.zError).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isSuccess
                        ? [context.zSuccess, context.zCeladon]
                        : [context.zError, context.zError.withOpacity(0.6)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(ZeroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.zTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (isSuccess)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.zSuccess.withOpacity(0.15),
                              ),
                              child: Icon(Icons.check_circle, size: 16, color: context.zSuccess),
                            )
                          else
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.zError.withOpacity(0.15),
                              ),
                              child: Icon(Icons.error_outline, size: 14, color: context.zError),
                            ),
                        ],
                      ),
                      SizedBox(height: ZeroSpacing.sm),
                      Text(
                        '${amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 4)} $token',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.zTextPrimary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      SizedBox(height: ZeroSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.zBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(chainIcon, style: const TextStyle(fontSize: 14)),
                            SizedBox(width: 4),
                            Text(
                              chainName,
                              style: ZeroTypography.caption(context).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (txShort.isNotEmpty) ...[
                        SizedBox(height: ZeroSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 12, color: context.zTextTertiary),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                txShort,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  color: context.zTextTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) ...[
                        SizedBox(height: ZeroSpacing.xs),
                        Text(
                          result.errorMessage!,
                          style: ZeroTypography.caption(context).copyWith(color: context.zError, fontSize: 10),
                        ),
                      ],
                      SizedBox(height: ZeroSpacing.xs),
                      Text(
                        timestampStr,
                        style: ZeroTypography.caption(context).copyWith(fontSize: 10, color: context.zTextTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _chainIcon(String chainId) {
    switch (chainId.toLowerCase()) {
      case 'eth':
        return '⟠';
      case 'btc':
        return '₿';
      case 'bsc':
        return '🔶';
      case 'trx':
        return '⬡';
      case 'sol':
        return '◎';
      default:
        return '🔗';
    }
  }

  String _chainName(String chainId) {
    switch (chainId.toLowerCase()) {
      case 'eth':
        return 'Ethereum';
      case 'btc':
        return 'Bitcoin';
      case 'bsc':
        return 'BSC';
      case 'trx':
        return 'Tron';
      case 'sol':
        return 'Solana';
      default:
        return chainId.toUpperCase();
    }
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    switch (message.type) {
      case MsgType.text:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 4),
          child: Text(message.text, style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary)),
        );
      case MsgType.image:
        if (message.base64Data != null) {
          final bytes = base64Decode(message.base64Data!.split(',').last);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, width: double.infinity, height: 180),
              ),
              if (message.imageLabel != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.image, size: 14, color: context.zTextTertiary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(message.imageLabel!, style: ZeroTypography.caption(context), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.zBg,
                image: DecorationImage(image: NetworkImage('https://picsum.photos/seed/zero/400/300'), fit: BoxFit.cover),
              ),
            ),
            if (message.imageLabel != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.image, size: 14, color: context.zTextTertiary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(message.imageLabel!, style: ZeroTypography.caption(context), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
          ],
        );
      case MsgType.voice:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.zAccent.withOpacity(0.15)),
                child: Icon(Icons.play_arrow_rounded, size: 18, color: context.zAccent),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(decoration: BoxDecoration(color: context.zAccent, borderRadius: BorderRadius.circular(2))),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(message.voiceDuration ?? '0:00', style: ZeroTypography.caption(context)),
            ],
          ),
        );
      case MsgType.file:
        return Padding(
          padding: EdgeInsets.all(ZeroSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: context.zCeladon.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.insert_drive_file_outlined, size: 20, color: context.zCeladon),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.fileName ?? 'file', style: ZeroTypography.body(context).copyWith(fontSize: 13, color: context.zTextPrimary)),
                  Text('${message.fileSize ?? '0'} · E2EE', style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
                ],
              ),
              SizedBox(width: ZeroSpacing.md),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.zAccent.withOpacity(0.1)),
                child: Icon(Icons.download, size: 16, color: context.zAccent),
              ),
            ],
          ),
        );
      case MsgType.location:
        return SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: context.zBg,
                  gradient: LinearGradient(colors: [context.zCeladon.withOpacity(0.2), context.zAccent.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Center(
                  child: Icon(Icons.location_on, size: 36, color: context.zAccent.withOpacity(0.5)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.near_me, size: 12, color: context.zAccent),
                    SizedBox(width: 4),
                    Expanded(child: Text(message.locationLabel ?? '', style: ZeroTypography.caption(context).copyWith(color: context.zTextSecondary), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ],
          ),
        );
      case MsgType.gif:
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [context.zCeladon.withOpacity(0.15), context.zAccent.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.imageLabel ?? '🎞️', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                child: const Text('GIF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      case MsgType.system:
        return const SizedBox.shrink();
      case MsgType.pay:
        return const SizedBox.shrink();
    }
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: context.zBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.zFrostWhiteStrong, width: 0.5)),
            child: Icon(icon, size: 22, color: context.zAccent),
          ),
          const SizedBox(height: 4),
          Text(label, style: ZeroTypography.caption(context).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}