import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/chat/group_chat_service.dart';
import '../../services/crypto/group_e2ee_service.dart';
import '../../widgets/zero_card.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final int memberCount;
  final String groupId;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.memberCount,
    this.groupId = 'group_001',
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showAttachments = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late final AnimationController _recordPulse;

  late List<_GroupMessage> _messages;
  final _e2ee = GroupE2EEService();
  final _groupService = GroupChatService();
  late final String _currentUserId;

  late List<GroupMember> _members;

  @override
  void initState() {
    super.initState();
    _recordPulse =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _currentUserId = 'you';
    _members = _groupService.getMembers(widget.groupId);
    _e2ee.createGroup(
      'group-demo',
      ['alice', 'bob', 'charlie', _currentUserId],
    );

    _messages = [
      _GroupMessage(
        text:
            'Group chat is E2E encrypted · Sender Key v1 · ${widget.memberCount} members',
        type: GroupMsgType.system,
        time: '10:00',
      ),
      _GroupMessage(
        text: 'GM everyone! 今天有什么新进展？',
        type: GroupMsgType.text,
        senderName: 'Alice',
        senderColorIndex: 0,
        time: '10:01',
      ),
      _GroupMessage(
        text: '早！昨晚把 mesh 网络层的 bug 修好了，今天可以开始测试跨设备消息中继',
        type: GroupMsgType.text,
        senderName: 'Bob',
        senderColorIndex: 1,
        time: '10:02',
      ),
      _GroupMessage(
        text: 'Awesome! I also finished the BLE integration. Let me share the test results.',
        type: GroupMsgType.text,
        senderName: 'Charlie',
        senderColorIndex: 2,
        time: '10:03',
      ),
      _GroupMessage(
        type: GroupMsgType.image,
        senderName: 'Charlie',
        senderColorIndex: 2,
        time: '10:03',
        imageLabel: 'ble_test_results.png',
      ),
      _GroupMessage(
        text: 'Great work everyone! Let me review the code and push the update.',
        type: GroupMsgType.text,
        isMe: true,
        time: '10:04',
      ),
      _GroupMessage(
        text: '对了，加密层的审计报告已经出来了，我转发到群里',
        type: GroupMsgType.text,
        senderName: 'Alice',
        senderColorIndex: 0,
        time: '10:05',
      ),
      _GroupMessage(
        type: GroupMsgType.file,
        senderName: 'Alice',
        senderColorIndex: 0,
        time: '10:05',
        fileName: 'Crypto_Audit_Report_v1.2.pdf',
        fileSize: '3.1 MB',
      ),
      _GroupMessage(
        text: 'Perfect timing! Let\'s schedule a meeting to go over the results.',
        type: GroupMsgType.text,
        senderName: 'Bob',
        senderColorIndex: 1,
        time: '10:06',
      ),
      _GroupMessage(
        text: '好的，我下午 3 点有空，大家呢？',
        type: GroupMsgType.text,
        isMe: true,
        time: '10:07',
      ),
      _GroupMessage(
        text: '3pm works for me!',
        type: GroupMsgType.text,
        senderName: 'Charlie',
        senderColorIndex: 2,
        time: '10:08',
      ),
      _GroupMessage(
        text: '没问题，3 点见 👋',
        type: GroupMsgType.text,
        senderName: 'Alice',
        senderColorIndex: 0,
        time: '10:09',
      ),
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
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final encrypted =
        _e2ee.encryptGroupMessage('group-demo', _currentUserId, text);
    _e2ee.decryptGroupMessage('group-demo', encrypted);

    setState(() {
      _messages.add(_GroupMessage(
        text: text,
        type: GroupMsgType.text,
        isMe: true,
        time:
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      ));
    });
    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _pickAndSendImage() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final now = DateTime.now();
        setState(() {
          _messages.add(_GroupMessage(
            type: GroupMsgType.image,
            isMe: true,
            time:
                '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            imageLabel: file.name,
            dataBase64: reader.result as String?,
          ));
          _showAttachments = false;
        });
        _scrollToBottom();
      });
      reader.readAsDataUrl(file);
    });
  }

  void _sendImageFromCamera() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment')
      ..click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final now = DateTime.now();
        setState(() {
          _messages.add(_GroupMessage(
            type: GroupMsgType.image,
            isMe: true,
            time:
                '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            imageLabel: file.name,
            dataBase64: reader.result as String?,
          ));
          _showAttachments = false;
        });
        _scrollToBottom();
      });
      reader.readAsDataUrl(file);
    });
  }

  void _pickAndSendFile() {
    final input = html.FileUploadInputElement()..click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final now = DateTime.now();
        final sizeStr = _formatFileSize(file.size ?? 0);
        setState(() {
          _messages.add(_GroupMessage(
            type: GroupMsgType.file,
            isMe: true,
            time:
                '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            fileName: file.name,
            fileSize: sizeStr,
            dataBase64: reader.result as String?,
          ));
          _showAttachments = false;
        });
        _scrollToBottom();
      });
      reader.readAsDataUrl(file);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _sendLocation() {
    final isZh = ZeroTheme.isZh(context);
    setState(() {
      _messages.add(_GroupMessage(
        type: GroupMsgType.location,
        isMe: true,
        time:
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        locationLabel: isZh ? '当前位置 · 现在' : 'Current Location · Now',
      ));
      _showAttachments = false;
    });
    _scrollToBottom();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
    _recordPulse.repeat(reverse: true);
  }

  void _stopRecording() {
    final isZh = ZeroTheme.isZh(context);
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordPulse.stop();
      _recordPulse.reset();
      final dur = _recordingSeconds;
      _messages.add(_GroupMessage(
        type: GroupMsgType.voice,
        isMe: true,
        time:
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        voiceDuration: '0:${dur.toString().padLeft(2, '0')}',
      ));
      _recordingSeconds = 0;
    });
    _scrollToBottom();
  }

  void _showMentionPicker() {
    final isZh = ZeroTheme.isZh(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: context.zSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.zDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
                child: Row(
                  children: [
                    Text(
                      isZh ? '@群成员' : '@Mention',
                      style: ZeroTypography.title(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.xs,
                  ),
                  itemCount: _members.length,
                  itemBuilder: (ctx, index) {
                    final member = _members[index];
                    final colors = _memberColorsFromIndex(member.colorIndex);
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          member.initial,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: ZeroTypography.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.zTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isZh ? member.roleLabelZh : member.roleLabelEn,
                        style: ZeroTypography.caption(context),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _insertMention(member.name);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: ZeroSpacing.lg + MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos < 0) {
      final newText = '$text@$name ';
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(offset: newText.length);
    } else {
      final before = text.substring(0, cursorPos);
      final after = text.substring(cursorPos);
      final newText = '$before@$name $after';
      _controller.text = newText;
      final newOffset = cursorPos + name.length + 2;
      _controller.selection = TextSelection.collapsed(offset: newOffset);
    }
    _focusNode.requestFocus();
  }

  void _showMemberPanel() {
    final isZh = ZeroTheme.isZh(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: context.zSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: context.zDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.screenHorizontal,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isZh
                                ? '群成员 (${_members.length})'
                                : 'Members (${_members.length})',
                            style: ZeroTypography.title(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ZeroSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.screenHorizontal,
                      ),
                      itemCount: _members.length,
                      itemBuilder: (ctx, index) {
                        final member = _members[index];
                        final colors =
                            _memberColorsFromIndex(member.colorIndex);
                        return Padding(
                          padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
                          child: ZeroCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: ZeroSpacing.md,
                                vertical: ZeroSpacing.xs,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  member.initial,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(
                                member.name,
                                style: ZeroTypography.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.zTextPrimary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: member
                                      .badgeColor(context)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: member
                                        .badgeColor(context)
                                        .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  isZh
                                      ? member.roleLabelZh
                                      : member.roleLabelEn,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: member.badgeColor(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  List<Color> _memberColorsFromIndex(int index) {
    final palettes = [
      [context.zAccent, context.zCeladon],
      [context.zCeladon, context.zSuccess],
      [context.zAccent, context.zWarning],
      [context.zWarning, context.zCeladon],
      [context.zCeladon, context.zAccent],
    ];
    final p = palettes[index % palettes.length];
    return [p[0], p[1]];
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: GestureDetector(
          onTap: _showMemberPanel,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.zAccent.withOpacity(0.3),
                      context.zCeladon.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: context.zFrostWhiteStrong,
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.groupName[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.zAccent,
                  ),
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.zTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMemberPanel,
                    child: Text(
                      '${widget.memberCount} ${isZh ? '位成员' : 'members'}',
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: context.zSuccess,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isZh ? 'Sender Key v1' : 'Sender Key v1',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zSuccess,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined, color: context.zTextSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: context.zTextSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: context.zTextSecondary),
            onPressed: () {},
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                  vertical: ZeroSpacing.md,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _GroupMessageBubble(
                  message: _messages[index],
                  memberColors: (int i) => _memberColorsFromIndex(i),
                ),
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
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.md,
        vertical: ZeroSpacing.sm,
      ),
      color: context.zSurface,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _recordPulse,
            builder: (_, child) => Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    context.zError.withOpacity(0.3 + _recordPulse.value * 0.7),
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.sm),
          Text(
            '${isZh ? '录音中' : 'Recording'} ${_recordingSeconds}s',
            style: ZeroTypography.caption(context).copyWith(
              color: context.zError,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.zError,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isZh ? '发送' : 'Send',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBar() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(
          top: BorderSide(color: context.zDivider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AttachButton(
            icon: Icons.camera_alt_outlined,
            label: isZh ? '拍照' : 'Camera',
            onTap: _sendImageFromCamera,
          ),
          _AttachButton(
            icon: Icons.image_outlined,
            label: isZh ? '相册' : 'Photo',
            onTap: _pickAndSendImage,
          ),
          _AttachButton(
            icon: Icons.insert_drive_file_outlined,
            label: isZh ? '文件' : 'File',
            onTap: _pickAndSendFile,
          ),
          _AttachButton(
            icon: Icons.location_on_outlined,
            label: isZh ? '位置' : 'Location',
            onTap: _sendLocation,
          ),
          _AttachButton(
            icon: Icons.gif_box_outlined,
            label: isZh ? 'GIF' : 'GIF',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        ZeroSpacing.sm,
        ZeroSpacing.sm,
        ZeroSpacing.sm,
        ZeroSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(
          top: BorderSide(color: context.zDivider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _showAttachments = !_showAttachments),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.zBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _showAttachments ? Icons.close : Icons.add_rounded,
                size: 22,
                color: context.zTextSecondary,
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.xs),
          GestureDetector(
            onTap: _showMentionPicker,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.zBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.alternate_email_rounded,
                size: 22,
                color: context.zAccent,
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.xs),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.zBg,
                borderRadius:
                    BorderRadius.circular(ZeroSpacing.inputRadius),
                border: Border.all(
                  color: context.zFrostWhiteStrong,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: isZh ? '输入消息...' : 'Type a message...',
                  hintStyle: ZeroTypography.body(context).copyWith(
                    color: context.zTextTertiary,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.md,
                  ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zBg,
                ),
                child: Icon(
                  Icons.mic_none_rounded,
                  size: 22,
                  color: context.zTextSecondary,
                ),
              ),
            )
          else
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
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: context.zBg,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum GroupMsgType { text, image, voice, file, location, system }

class _GroupMessage {
  final String text;
  final GroupMsgType type;
  final bool isMe;
  final String time;
  final String? senderName;
  final int? senderColorIndex;
  final String? imageLabel;
  final String? fileName;
  final String? fileSize;
  final String? voiceDuration;
  final String? locationLabel;
  final String? dataBase64;

  const _GroupMessage({
    this.text = '',
    required this.type,
    this.isMe = false,
    required this.time,
    this.senderName,
    this.senderColorIndex,
    this.imageLabel,
    this.fileName,
    this.fileSize,
    this.voiceDuration,
    this.locationLabel,
    this.dataBase64,
  });
}

class _GroupMessageBubble extends StatelessWidget {
  final _GroupMessage message;
  final List<Color> Function(int) memberColors;

  const _GroupMessageBubble({
    required this.message,
    required this.memberColors,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    if (message.type == GroupMsgType.system) {
      return _buildSystemMessage(context, isZh);
    }

    final isMe = message.isMe;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final colors = isMe
        ? [context.zAccent, context.zCeladon]
        : memberColors(message.senderColorIndex ?? 0);
    final senderName = isMe
        ? (isZh ? '你' : 'You')
        : (message.senderName ?? '?');
    final senderInitial = senderName[0].toUpperCase();

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: align,
        children: [
          _buildSenderRow(context, isMe, senderInitial, senderName, colors),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                SizedBox(width: 32),
                SizedBox(width: ZeroSpacing.sm),
              ],
              if (isMe) const Spacer(),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? context.zSurfaceOverlay : context.zSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft:
                          isMe ? Radius.circular(16) : Radius.circular(4),
                      bottomRight:
                          isMe ? Radius.circular(4) : Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? context.zAccent.withOpacity(0.08)
                          : context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildMessageContent(context),
                ),
              ),
              if (isMe) ...[
                SizedBox(width: ZeroSpacing.sm),
                SizedBox(width: ZeroSpacing.sm),
              ],
              if (!isMe) const Spacer(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 48,
              right: isMe ? 8 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.check,
                    size: 12,
                    color: context.zSuccess.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderRow(
    BuildContext context,
    bool isMe,
    String initial,
    String name,
    List<Color> colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMe) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors[0], colors[1]],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.zBg,
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.sm),
        ],
        Text(
          name,
          style: ZeroTypography.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: colors[0],
          ),
        ),
        if (isMe) ...[
          SizedBox(width: ZeroSpacing.sm),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors[0], colors[1]],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.zBg,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMessage(BuildContext context, bool isZh) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.md,
            vertical: ZeroSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.zFrostWhite,
            borderRadius:
                BorderRadius.circular(ZeroSpacing.chipRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 10,
                color: context.zSuccess.withOpacity(0.6),
              ),
              SizedBox(width: 4),
              Text(
                message.text,
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zSuccess.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case GroupMsgType.text:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.md,
            vertical: ZeroSpacing.md - 4,
          ),
          child: Text(
            message.text,
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextPrimary,
            ),
          ),
        );
      case GroupMsgType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.zBg,
                image: message.dataBase64 != null
                    ? DecorationImage(
                        image: MemoryImage(
                          base64Decode(
                            message.dataBase64!
                                .replaceFirst(RegExp(r'^data:[^;]+;base64,'), ''),
                          ),
                        ),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: NetworkImage(
                          'https://picsum.photos/seed/group${message.time.hashCode}/400/300',
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (message.imageLabel != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.md,
                  vertical: ZeroSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image,
                      size: 14,
                      color: context.zTextTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        message.imageLabel!,
                        style: ZeroTypography.caption(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case GroupMsgType.voice:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.md,
            vertical: ZeroSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zAccent.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: context.zAccent,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: context.zDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.zAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                message.voiceDuration ?? '0:00',
                style: ZeroTypography.caption(context),
              ),
            ],
          ),
        );
      case GroupMsgType.file:
        return Padding(
          padding: EdgeInsets.all(ZeroSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.zCeladon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 20,
                  color: context.zCeladon,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'file',
                    style: ZeroTypography.body(context).copyWith(
                      fontSize: 13,
                      color: context.zTextPrimary,
                    ),
                  ),
                  Text(
                    '${message.fileSize ?? '0'} · E2EE',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              SizedBox(width: ZeroSpacing.md),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zAccent.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.download,
                  size: 16,
                  color: context.zAccent,
                ),
              ),
            ],
          ),
        );
      case GroupMsgType.location:
        return SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: context.zBg,
                  gradient: LinearGradient(
                    colors: [
                      context.zCeladon.withOpacity(0.2),
                      context.zAccent.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on,
                    size: 32,
                    color: context.zAccent.withOpacity(0.5),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.md,
                  vertical: ZeroSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 12,
                      color: context.zAccent,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        message.locationLabel ?? '',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zTextSecondary,
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
      case GroupMsgType.system:
        return const SizedBox.shrink();
    }
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.zBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: 22, color: context.zAccent),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}