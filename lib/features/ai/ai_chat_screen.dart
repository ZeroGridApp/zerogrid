import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/ai/zero_ai_service.dart';
import '../../widgets/zero_card.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_AIMessage> _messages = [];
  final _aiService = ZeroAIService();
  bool _thinking = false;

  late final AnimationController _dotController;

  List<String> _getQuickPrompts(bool isZh) {
    return isZh
        ? [
            '加密是如何工作的？',
            '支持哪些钱包？',
            '我的隐私如何被保护？',
            '如何转账代币？',
          ]
        : [
            'How does encryption work?',
            'Which wallets are supported?',
            'How is my privacy protected?',
            'How to transfer tokens?',
          ];
  }

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_AIMessage(role: 'user', content: text));
      _thinking = true;
    });
    _controller.clear();

    final query = text;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(_AIMessage(
          role: 'zeroai',
          content: _aiService.generateResponse(query),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showQuickPrompts = _messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.aiAssistant),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: context.zAccentGradient,
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: context.zBg,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: context.zTextSecondary,
              size: 20,
            ),
            tooltip: l10n.clearConversation,
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showQuickPrompts) _buildQuickPrompts(),
          if (!showQuickPrompts)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(ZeroSpacing.md),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_thinking && i == _messages.length) {
                    return _buildThinking();
                  }
                  return _buildBubble(_messages[i]);
                },
              ),
            ),
          if (_thinking && showQuickPrompts)
            Expanded(
              child: Center(
                child: _buildThinking(),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    final isZh = ZeroTheme.isZh(context);
    final quickPrompts = _getQuickPrompts(isZh);
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => context.zAccentGradient
                    .createShader(bounds),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Text(
                isZh ? '有什么可以帮你的？' : 'How can I help you?',
                style: ZeroTypography.headline(context),
              ),
              SizedBox(height: ZeroSpacing.xs),
              Text(
                isZh
                    ? '我是 ZeroAI，了解加密、钱包、隐私保护等一切零界相关问题'
                    : 'I am ZeroAI, knowledgeable about crypto, wallets, privacy protection, and all things Zero',
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ZeroSpacing.xl),
              Wrap(
                spacing: ZeroSpacing.sm,
                runSpacing: ZeroSpacing.sm,
                alignment: WrapAlignment.center,
                children: quickPrompts.map((p) => GestureDetector(
                  onTap: () => _sendMessage(p),
                  child: ZeroCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.sm + 2,
                    ),
                    borderRadius: ZeroSpacing.chipRadius + 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _promptIcon(p, isZh),
                        SizedBox(width: ZeroSpacing.sm),
                        Text(
                          p,
                          style: ZeroTypography.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.zTextPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptIcon(String prompt, bool isZh) {
    IconData icon;
    Color color;
    if (prompt.contains('加密') || prompt.toLowerCase().contains('encrypt')) {
      icon = Icons.lock_outline;
      color = context.zAccent;
    } else if (prompt.contains('钱包') || prompt.toLowerCase().contains('wallet')) {
      icon = Icons.account_balance_wallet_outlined;
      color = context.zCeladon;
    } else if (prompt.contains('隐私') || prompt.toLowerCase().contains('privacy')) {
      icon = Icons.shield_outlined;
      color = const Color(0xFFA0B0C0);
    } else {
      icon = Icons.swap_horiz_rounded;
      color = const Color(0xFFC0A060);
    }
    return Icon(icon, size: 18, color: color);
  }

  Widget _buildThinking() {
    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.zAccentGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              'AI',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.zBg,
              ),
            ),
          ),
          const SizedBox(width: ZeroSpacing.sm),
          _AnimatedThinkingDots(controller: _dotController),
        ],
      ),
    );
  }

  Widget _buildBubble(_AIMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.zAccentGradient,
              ),
              alignment: Alignment.center,
              child: Text(
                'AI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.zBg,
                ),
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
          ],
          if (isUser) Spacer(),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.md,
                vertical: ZeroSpacing.md - 2,
              ),
              decoration: BoxDecoration(
                color: isUser ? context.zSurfaceOverlay : context.zSurface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isUser
                      ? Radius.circular(16)
                      : Radius.circular(4),
                  bottomRight: isUser
                      ? Radius.circular(4)
                      : Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser
                      ? context.zFrostWhiteStrong
                      : context.zAccent.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
              child: _buildMessageContent(msg.content, isUser),
            ),
          ),
          if (isUser) const SizedBox(width: ZeroSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String content, bool isUser) {
    if (isUser) {
      return Text(
        content,
        style: ZeroTypography.body(context).copyWith(
          color: context.zTextPrimary,
        ),
      );
    }

    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('**')) {
        final parts = line.split('**');
        final spans = <InlineSpan>[];
        for (int j = 0; j < parts.length; j++) {
          if (j % 2 == 1) {
            spans.add(TextSpan(
              text: parts[j],
              style: ZeroTypography.body(context).copyWith(
                color: context.zAccent,
                fontWeight: FontWeight.w600,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: parts[j],
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
              ),
            ));
          }
        }
        widgets.add(RichText(text: TextSpan(children: spans)));
      } else if (line.startsWith('|')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: ZeroTypography.monoSmall(context).copyWith(
                color: context.zTextSecondary,
                fontSize: 11,
              ),
            ),
          ),
        );
      } else if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Text(
          line,
          style: line.startsWith('  ') || line.startsWith('·')
              ? ZeroTypography.body(context).copyWith(
                  color: context.zTextSecondary,
                  fontSize: 14,
                )
              : ZeroTypography.body(context).copyWith(
                  color: context.zTextPrimary,
                ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        ZeroSpacing.md,
        ZeroSpacing.sm,
        ZeroSpacing.md,
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
          Expanded(
            child: TextField(
              controller: _controller,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.aiPlaceholder,
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
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: ZeroSpacing.sm),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.zAccentGradient,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: context.zBg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedThinkingDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedThinkingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.2;
        return AnimatedBuilder(
          animation: controller,
          builder: (_, child) {
            final t = (controller.value - delay) % 1.0;
            final scale = 0.4 + 0.6 * _easeInOut(t < 0 ? t + 1.0 : t);
            final opacity = 0.3 + 0.7 * _easeInOut(t < 0 ? t + 1.0 : t);
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.zAccent.withOpacity(opacity),
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        );
      }),
    );
  }

  double _easeInOut(double t) {
    return t < 0.5
        ? 2.0 * t * t
        : -1.0 + (4.0 - 2.0 * t) * t;
  }
}

class _AIMessage {
  final String role;
  final String content;
  const _AIMessage({required this.role, required this.content});
}