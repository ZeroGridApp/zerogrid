import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<int> _expandedFaqIndices = {};
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _includeLogs = false;
  bool _feedbackSubmitted = false;
  String _feedbackCategory = 'bug';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleFaq(int index) {
    setState(() {
      if (_expandedFaqIndices.contains(index)) {
        _expandedFaqIndices.remove(index);
      } else {
        _expandedFaqIndices.add(index);
      }
    });
  }

  void _showGuideDetail(String zhTitle, String enTitle, String zhContent,
      String enContent) {
    final isZh = ZeroTheme.isZh(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: ZeroSpacing.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.screenHorizontal),
                  child: Text(
                    isZh ? zhTitle : enTitle,
                    style: ZeroTypography.title(context),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.screenHorizontal,
                    ),
                    child: Text(
                      isZh ? zhContent : enContent,
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextSecondary,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.xxl),
              ],
            );
          },
        );
      },
    );
  }

  void _submitFeedback() {
    setState(() {
      _feedbackSubmitted = true;
    });
  }

  void _resetFeedback() {
    setState(() {
      _feedbackSubmitted = false;
      _subjectController.clear();
      _descriptionController.clear();
      _includeLogs = false;
      _feedbackCategory = 'bug';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '帮助与反馈' : 'Help & Feedback'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.screenHorizontal),
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.zAccent,
              indicatorWeight: 1.5,
              labelColor: context.zTextPrimary,
              unselectedLabelColor: context.zTextTertiary,
              labelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: isZh ? '常见问题' : 'FAQ'),
                Tab(text: isZh ? '使用指南' : 'Guides'),
                Tab(text: isZh ? '意见反馈' : 'Feedback'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(isZh),
          _buildGuidesTab(isZh),
          _buildFeedbackTab(isZh),
        ],
      ),
    );
  }

  Widget _buildFaqTab(bool isZh) {
    final faqs = _faqData(isZh);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom,
      ),
      itemCount: faqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: ZeroSpacing.sm),
      itemBuilder: (context, index) {
        final faq = faqs[index];
        final isExpanded = _expandedFaqIndices.contains(index);

        return ZeroCard(
          onTap: () => _toggleFaq(index),
          padding: EdgeInsets.zero,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: context.zTextPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: context.zTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ZeroSpacing.md,
                      0,
                      ZeroSpacing.md,
                      ZeroSpacing.md,
                    ),
                    child: Text(
                      faq.answer,
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextSecondary,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidesTab(bool isZh) {
    final guides = _guideData(isZh);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom,
      ),
      itemCount: guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: ZeroSpacing.sm),
      itemBuilder: (context, index) {
        final guide = guides[index];
        return ZeroCard(
          onTap: () => _showGuideDetail(
            guide.zhTitle,
            guide.enTitle,
            guide.zhContent,
            guide.enContent,
          ),
          padding: EdgeInsets.all(ZeroSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.zAccent.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  guide.icon,
                  size: 22,
                  color: context.zAccent,
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: ZeroTypography.bodyBold(context).copyWith(
                        color: context.zTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guide.subtitle,
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? '了解更多' : 'Read more',
                style: ZeroTypography.caption(context).copyWith(
                  color: context.zAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.zAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTab(bool isZh) {
    if (_feedbackSubmitted) {
      return _buildSuccessState(isZh);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.screenBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '分享你的想法' : 'Share your thoughts',
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            isZh ? '我们很乐意听到你的反馈' : 'We\'d love to hear your feedback',
            style: ZeroTypography.body(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            isZh ? '类别' : 'Category',
            style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ZeroCard(
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: 2,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _feedbackCategory,
                isExpanded: true,
                dropdownColor: context.zSurface,
                style: ZeroTypography.body(context).copyWith(
                  color: context.zTextPrimary,
                  fontSize: 14,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.zTextTertiary,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'bug',
                    child: Text(isZh ? '问题反馈' : 'Bug Report'),
                  ),
                  DropdownMenuItem(
                    value: 'feature',
                    child: Text(isZh ? '功能建议' : 'Feature Request'),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text(isZh ? '一般反馈' : 'General Feedback'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _feedbackCategory = v);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '主题' : 'Subject',
            style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
            ),
            child: TextField(
              controller: _subjectController,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: isZh ? '简短描述你的问题' : 'Briefly describe your issue',
                hintStyle: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ZeroSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '描述' : 'Description',
            style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: isZh
                    ? '请详细描述你的问题或建议...'
                    : 'Please describe your issue or suggestion in detail...',
                hintStyle: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ZeroSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          ZeroCard(
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: ZeroSpacing.md - 6,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  size: 20,
                  color: context.zTextSecondary,
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Text(
                    isZh ? '包含日志' : 'Include logs',
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zTextPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _includeLogs,
                  onChanged: (v) {
                    setState(() => _includeLogs = v);
                  },
                  activeColor: context.zAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          ZeroCard(
            onTap: () {},
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: ZeroSpacing.md - 6,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: context.zTextSecondary,
                ),
                const SizedBox(width: ZeroSpacing.sm),
                Text(
                  isZh ? '附加截图' : 'Attach screenshot',
                  style: ZeroTypography.body(context).copyWith(
                    color: context.zTextPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 20,
                  color: context.zTextTertiary,
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submitFeedback,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(ZeroSpacing.buttonRadius),
                  gradient: LinearGradient(
                    colors: [context.zAccent, context.zCeladon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isZh ? '提交反馈' : 'Submit Feedback',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.zBg,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isZh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.zSuccess.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: context.zSuccess,
              ),
            ),
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              isZh ? '感谢！你的反馈让 Zero 变得更好。' : 'Thank you! Your feedback helps make Zero better.',
              style: ZeroTypography.headline(context).copyWith(
                color: context.zTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              isZh ? '我们会尽快处理你的反馈。' : 'We will review your feedback as soon as possible.',
              style: ZeroTypography.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ZeroSpacing.xl),
            SizedBox(
              width: 200,
              child: GestureDetector(
                onTap: _resetFeedback,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ZeroSpacing.buttonRadius),
                    border: Border.all(
                      color: context.zAccentMuted.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isZh ? '提交更多反馈' : 'Submit More Feedback',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.zAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FaqItemData> _faqData(bool isZh) {
    return [
      _FaqItemData(
        question: isZh
            ? 'Zero 和其他通讯软件有什么不同？'
            : 'How is Zero different from other messengers?',
        answer: isZh
            ? 'Zero 完全去中心化，没有中心服务器。每条消息使用 Double Ratchet 算法端到端加密。你的身份（ZeroID）是自主的，由只有你控制的 BIP39 助记词生成。'
            : 'Zero is fully decentralized with no central servers. Every message is end-to-end encrypted using the Double Ratchet algorithm. Your identity (ZeroID) is self-sovereign, derived from a BIP39 mnemonic that only you control.',
      ),
      _FaqItemData(
        question: isZh ? 'ZERO 代币有什么用？' : 'What is ZERO token used for?',
        answer: isZh
            ? 'ZERO 是 Zero 生态的原生效用代币：1) 所有操作的 Gas 费，2) 节点质押收益，3) DAO 治理投票，4) ZeroPay 和 ZeroMarket 的支付货币，5) ZeroDNS 域名注册。'
            : 'ZERO is the native utility token of the Zero ecosystem: 1) Gas fees for all operations, 2) Staking for node rewards, 3) DAO governance voting, 4) Payment currency in ZeroPay and ZeroMarket, 5) Domain registration on ZeroDNS.',
      ),
      _FaqItemData(
        question: isZh ? '如何备份我的身份？' : 'How do I backup my identity?',
        answer: isZh
            ? '你的身份由 12 个 BIP39 助记词保护。前往 设置 → 隐私与安全 → 显示恢复助记词。按顺序写下这 12 个词，离线安全保存。永远不要与任何人分享。'
            : 'Your identity is secured by a 12-word BIP39 mnemonic phrase. Go to Settings → Privacy & Security → Show Recovery Phrase. Write down these 12 words in order and store them safely offline. Never share them with anyone.',
      ),
      _FaqItemData(
        question:
            isZh ? '多链寄生架构如何工作？' : 'How does multi-chain parasitic architecture work?',
        answer: isZh
            ? 'Zero 目前没有自己的 L1。ZERO 以代币形式存在于以太坊(ERC20)、BSC(BEP20)、Solana(SPL)、TRON(TRC20)上。ZeroBridge 跨链聚合交易，将 5000 万操作打包为 5 万笔链上交易，Gas 费相比直接上链降低 ~99.9%。'
            : 'Zero doesn\'t have its own L1 yet. Instead, ZERO exists as tokens on Ethereum (ERC20), BSC (BEP20), Solana (SPL), and TRON (TRC20). ZeroBridge aggregates transactions across all chains, batching 50M operations into just 50K on-chain transactions. This reduces gas fees by ~99.9% compared to direct on-chain operations.',
      ),
      _FaqItemData(
        question: isZh ? '如何运行 ZeroNode？' : 'How do I run a ZeroNode?',
        answer: isZh
            ? '前往 设置 → ZeroNode → 部署节点 打开配置向导。你需要质押至少 10,000 ZERO 代币。系统要求：4 核 CPU、8GB RAM、100GB SSD、稳定的网络连接。部署后将获得网络奖励。'
            : 'Go to Settings → ZeroNode → Deploy Node to open the setup wizard. You need to stake at least 10,000 ZERO tokens. System requirements: 4-core CPU, 8GB RAM, 100GB SSD, stable internet connection. You will earn network rewards after deployment.',
      ),
      _FaqItemData(
        question: isZh ? 'Zero 是开源的嗎？' : 'Is Zero open source?',
        answer: isZh
            ? '是的！Zero 完全开源，使用 MIT 许可。核心协议（Rust）和客户端（Flutter）代码均在我们的 GitHub 上。欢迎社区贡献。'
            : 'Yes! Zero is fully open source under the MIT license. Core protocol (Rust) and client app (Flutter) are available on our GitHub. Community contributions are welcome.',
      ),
      _FaqItemData(
        question: isZh ? '如何创建群聊？' : 'How to create a group chat?',
        answer: isZh
            ? '在聊天列表页面点击右上角的 "+" 按钮，选择"创建群聊"。你可以设置群名称、头像以及邀请码。所有群聊消息均通过端到端加密保护。成员可通过受邀码或直接邀请加入。'
            : 'On the chat list page, tap the "+" button in the top right and select "Create Group". You can set a group name, avatar, and invite code. All group messages are protected with end-to-end encryption. Members can join via invite code or direct invitation.',
      ),
      _FaqItemData(
        question: isZh ? 'ZeroBridge 支持哪些链？' : 'What chains does ZeroBridge support?',
        answer: isZh
            ? 'ZeroBridge 目前支持以下区块链：Ethereum (ETH)、BNB Smart Chain (BSC)、Solana (SOL)、TRON (TRX) 和 Bitcoin (BTC)。我们的桥接引擎将跨链交易批量聚合，显著降低 Gas 费用。更多链正在集成中。'
            : 'ZeroBridge currently supports the following blockchains: Ethereum (ETH), BNB Smart Chain (BSC), Solana (SOL), TRON (TRX), and Bitcoin (BTC). Our bridge engine batches cross-chain transactions to significantly reduce gas fees. More chains are being integrated.',
      ),
    ];
  }

  List<_GuideData> _guideData(bool isZh) {
    return [
      _GuideData(
        icon: Icons.rocket_launch_rounded,
        title: isZh ? '新手指南' : 'Getting Started',
        subtitle: isZh
            ? '设置你的 ZeroID，完成第一笔交易'
            : 'Set up your ZeroID, make your first transaction',
        zhTitle: '新手指南',
        enTitle: 'Getting Started',
        zhContent: '欢迎来到 Zero！以下是快速入门步骤：\n\n'
            '1. 创建 ZeroID：打开应用，跟随引导创建你的去中心化身份。系统会生成 12 个 BIP39 助记词，请务必安全备份。\n\n'
            '2. 设置显示名称和个人资料：在设置页面自定义你的名称、头像和简介。\n\n'
            '3. 获取 ZERO 代币：通过 ZeroBridge 跨链桥从支持的链上获取 ZERO 代币，或在去中心化交易所购买。\n\n'
            '4. 安全设置：启用安全锁、设置隐私选项。\n\n'
            '5. 开始聊天：搜索好友的 ZeroID 或 DID 添加联系人，开始端到端加密聊天。\n\n'
            '6. 探索更多功能：尝试 ZeroPay 支付、DASN 存储、DAO 投票等高级功能。',
        enContent: 'Welcome to Zero! Here are the quick start steps:\n\n'
            '1. Create ZeroID: Open the app and follow the guide to create your decentralized identity. 12 BIP39 mnemonic words will be generated — back them up securely.\n\n'
            '2. Set display name and profile: Customize your name, avatar, and bio in Settings.\n\n'
            '3. Get ZERO tokens: Bridge ZERO tokens from supported chains via ZeroBridge, or purchase on DEX.\n\n'
            '4. Security setup: Enable security lock, configure privacy options.\n\n'
            '5. Start chatting: Search for friends by ZeroID or DID to add contacts and begin E2EE chats.\n\n'
            '6. Explore more: Try ZeroPay payments, DASN storage, DAO voting, and other advanced features.',
      ),
      _GuideData(
        icon: Icons.shield_rounded,
        title: isZh ? '保护钱包' : 'Secure Your Wallet',
        subtitle: isZh ? '助记词保管最佳实践' : 'Best practices for seed phrase storage',
        zhTitle: '保护钱包',
        enTitle: 'Secure Your Wallet',
        zhContent: '你的 ZeroID 安全完全取决于助记词的保管。请遵循以下最佳实践：\n\n'
            '1. 离线备份：将助记词写在纸上或使用专用的硬件设备，不要截图或拍照保存在联网设备中。\n\n'
            '2. 多份备份：制作 2-3 份备份，存放在不同地点，防止自然灾害或意外损坏。\n\n'
            '3. 永不分享：不要将助记词告诉任何人，包括客服或社区管理员。Zero 团队永远不会要求你提供助记词。\n\n'
            '4. 使用强密码：为应用设置安全锁密码。\n\n'
            '5. 定期检查：确保备份完好，字迹清晰可辨。\n\n'
            '6. 警惕钓鱼：只从官方渠道下载应用，不要点击可疑链接。',
        enContent: 'Your ZeroID security depends entirely on seed phrase storage. Follow these best practices:\n\n'
            '1. Offline backup: Write down your seed phrase on paper or use a dedicated hardware device. Never screenshot or photograph it and store on internet-connected devices.\n\n'
            '2. Multiple copies: Make 2-3 copies stored in different locations to protect against natural disasters or accidental damage.\n\n'
            '3. Never share: Never share your seed phrase with anyone, including customer support or community admins. The Zero team will never ask for your seed phrase.\n\n'
            '4. Strong passcode: Set a security lock passcode for the app.\n\n'
            '5. Regular checks: Ensure backups remain intact and legible.\n\n'
            '6. Beware of phishing: Only download the app from official sources and avoid clicking suspicious links.',
      ),
      _GuideData(
        icon: Icons.payments_rounded,
        title: isZh ? 'ZeroPay 指南' : 'ZeroPay Guide',
        subtitle: isZh
            ? '如何在聊天中收发 ZERO'
            : 'How to send/receive ZERO in chat',
        zhTitle: 'ZeroPay 指南',
        enTitle: 'ZeroPay Guide',
        zhContent: 'ZeroPay 让你在聊天中直接收发 ZERO 代币：\n\n'
            '1. 打开任意聊天窗口，点击消息输入框旁的 "+" 按钮。\n\n'
            '2. 选择 "ZeroPay" 支付选项。\n\n'
            '3. 输入发送金额（ZERO）。\n\n'
            '4. 添加备注（可选），确认交易。\n\n'
            '5. 交易将通过 ZeroBridge 跨链聚合，批量上链以节省 Gas 费用。\n\n'
            '6. 你可以在聊天记录中查看所有支付历史。\n\n'
            '提示：大额交易建议等待更多交易打包以节省 Gas 费。',
        enContent: 'ZeroPay lets you send and receive ZERO tokens directly in chat:\n\n'
            '1. Open any chat window and tap the "+" button next to the message input.\n\n'
            '2. Select the "ZeroPay" payment option.\n\n'
            '3. Enter the amount to send (ZERO).\n\n'
            '4. Add a note (optional) and confirm the transaction.\n\n'
            '5. Transactions are batched via ZeroBridge cross-chain aggregation to save on gas fees.\n\n'
            '6. View all payment history in your chat records.\n\n'
            'Tip: For large transactions, waiting for more transactions to batch can save on gas.',
      ),
      _GuideData(
        icon: Icons.cloud_rounded,
        title: isZh ? 'DASN 存储' : 'DASN Storage',
        subtitle: isZh
            ? '在去中心化网络上加密存储文件'
            : 'Encrypt and store files on decentralized network',
        zhTitle: 'DASN 存储',
        enTitle: 'DASN Storage',
        zhContent: 'DASN（去中心化匿名存储网络）是 Zero 的去中心化文件存储方案：\n\n'
            '1. 在聊天中点击 "+" → 选择"文件" → "上传到 DASN"。\n\n'
            '2. 文件在上传前会使用你的私钥进行端到端加密。\n\n'
            '3. 文件被分片并分布式存储在多个节点上，确保高可用性。\n\n'
            '4. 通过内容标识符（CID）访问文件，只有持有解密密钥的人可以查看内容。\n\n'
            '5. 你可以设置文件的存储时间和访问权限。\n\n'
            '6. 存储费用以 ZERO 代币支付。\n\n'
            '优势：去中心化、抗审查、端到端加密、无单点故障。',
        enContent: 'DASN (Decentralized Anonymous Storage Network) is Zero\'s decentralized file storage solution:\n\n'
            '1. In chat, tap "+" → select "File" → "Upload to DASN".\n\n'
            '2. Files are encrypted end-to-end with your private key before upload.\n\n'
            '3. Files are sharded and distributed across multiple nodes for high availability.\n\n'
            '4. Access files via Content Identifier (CID); only those with the decryption key can view the content.\n\n'
            '5. Set file storage duration and access permissions.\n\n'
            '6. Storage fees are paid in ZERO tokens.\n\n'
            'Advantages: Decentralized, censorship-resistant, E2E encrypted, no single point of failure.',
      ),
      _GuideData(
        icon: Icons.how_to_vote_rounded,
        title: isZh ? 'DAO 治理' : 'DAO Governance',
        subtitle: isZh
            ? '如何创建提案和投票'
            : 'How to create proposals and vote',
        zhTitle: 'DAO 治理',
        enTitle: 'DAO Governance',
        zhContent: '参与 Zero DAO 治理：\n\n'
            '1. 访问 DAO 页面查看当前活跃的提案。\n\n'
            '2. 投票权与你的 ZERO 代币持有量成正比（1 ZERO = 1 票）。\n\n'
            '3. 创建提案需要持有至少 10,000 ZERO 代币。\n\n'
            '4. 提案类型包括：协议升级、参数调整、资金分配、生态发展等。\n\n'
            '5. 投票期为 7 天，需要达到法定人数才能通过。\n\n'
            '6. 通过质押 ZERO 代币可获得额外投票权重。\n\n'
            '7. 所有投票记录在链上，完全透明可追溯。',
        enContent: 'Participate in Zero DAO governance:\n\n'
            '1. Visit the DAO page to view currently active proposals.\n\n'
            '2. Voting power is proportional to your ZERO token holdings (1 ZERO = 1 vote).\n\n'
            '3. Creating a proposal requires holding at least 10,000 ZERO tokens.\n\n'
            '4. Proposal types include: protocol upgrades, parameter adjustments, fund allocation, ecosystem development, etc.\n\n'
            '5. Voting period is 7 days, requiring quorum to pass.\n\n'
            '6. Staking ZERO tokens grants additional voting weight.\n\n'
            '7. All voting records are on-chain, fully transparent and traceable.',
      ),
      _GuideData(
        icon: Icons.swap_horiz_rounded,
        title: isZh ? '跨链桥接' : 'Cross-chain Bridge',
        subtitle: isZh
            ? '逐步教你如何跨链转移代币'
            : 'Bridge tokens between chains step by step',
        zhTitle: '跨链桥接',
        enTitle: 'Cross-chain Bridge',
        zhContent: '使用 ZeroBridge 跨链转移代币：\n\n'
            '1. 打开 ZeroBridge 页面（钱包 → 跨链桥）。\n\n'
            '2. 选择源链（如 Ethereum）和目标链（如 BSC）。\n\n'
            '3. 输入要转移的代币数量。\n\n'
            '4. 系统会显示预估 Gas 费和到账时间。\n\n'
            '5. 确认交易，需在源链上支付 Gas 费。\n\n'
            '6. ZeroBridge 会将你的交易与其他交易打包，批量提交到目标链。\n\n'
            '7. 交易完成后，代币会出现在你的目标链钱包中。\n\n'
            '支持链：ETH、BSC、SOL、TRX、BTC 等。\n\n'
            '注：跨链桥交易可能需要几分钟到几十分钟，取决于目标链的确认速度。',
        enContent: 'Bridge tokens between chains using ZeroBridge:\n\n'
            '1. Open the ZeroBridge page (Wallet → Cross-chain Bridge).\n\n'
            '2. Select source chain (e.g. Ethereum) and destination chain (e.g. BSC).\n\n'
            '3. Enter the token amount to transfer.\n\n'
            '4. The system displays estimated gas fees and arrival time.\n\n'
            '5. Confirm the transaction, paying gas fees on the source chain.\n\n'
            '6. ZeroBridge batches your transaction with others and submits them to the destination chain.\n\n'
            '7. Once completed, tokens appear in your destination chain wallet.\n\n'
            'Supported chains: ETH, BSC, SOL, TRX, BTC, and more.\n\n'
            'Note: Bridge transactions may take several minutes to tens of minutes depending on destination chain confirmation speed.',
      ),
    ];
  }
}

class _FaqItemData {
  final String question;
  final String answer;

  const _FaqItemData({
    required this.question,
    required this.answer,
  });
}

class _GuideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String zhTitle;
  final String enTitle;
  final String zhContent;
  final String enContent;

  const _GuideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.zhTitle,
    required this.enTitle,
    required this.zhContent,
    required this.enContent,
  });
}