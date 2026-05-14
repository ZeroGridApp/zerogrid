import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  late final List<_ChangelogVersion> _versions;

  @override
  void initState() {
    super.initState();
    _versions = _buildVersions();
  }

  List<_ChangelogVersion> _buildVersions() {
    return [
      _ChangelogVersion(
        version: 'v0.6.0',
        codename: 'Infrastructure',
        codenameZh: '基建',
        date: 'May 2026',
        dateZh: '2026年5月',
        features: [
          _ChangelogFeature(emoji: '\u{1f3d7}\u{fe0f}', text: 'ZeroNode deployment wizard, P2P topology, monitoring', textZh: 'ZeroNode 部署向导，P2P 拓扑，节点监控'),
          _ChangelogFeature(emoji: '\u{1f4ca}', text: 'ZERO Tokenomics dashboard with staking calculator', textZh: 'ZERO 代币经济仪表盘，含质押计算器'),
          _ChangelogFeature(emoji: '\u{1f504}', text: 'ZET renamed to ZERO across entire ecosystem', textZh: 'ZET 全面更名为 ZERO'),
          _ChangelogFeature(emoji: '\u{1f510}', text: 'Rust ZeroCore: BIP39 + X3DH + DoubleRatchet', textZh: 'Rust ZeroCore：BIP39 + X3DH + DoubleRatchet'),
        ],
      ),
      _ChangelogVersion(
        version: 'v0.5.0',
        codename: 'Polish',
        codenameZh: '抛光',
        date: 'May 2026',
        dateZh: '2026年5月',
        features: [
          _ChangelogFeature(emoji: '\u{1f680}', text: 'Onboarding flow (4-page walkthrough)', textZh: '引导流程（4页新手指南）'),
          _ChangelogFeature(emoji: '\u{1f512}', text: 'PIN lock screen with 30s lockout', textZh: 'PIN 码锁屏，含30秒锁定机制'),
          _ChangelogFeature(emoji: '\u{2699}\u{fe0f}', text: 'Enhanced settings: Notifications, Data & Storage, Open Source Licenses', textZh: '增强设置：通知、数据与存储、开源许可'),
          _ChangelogFeature(emoji: '\u{1f4cc}', text: 'Contacts: Pin/Favorite/Block with swipe actions', textZh: '联系人：置顶/收藏/屏蔽，支持滑动操作'),
        ],
      ),
      _ChangelogVersion(
        version: 'v0.4.0',
        codename: 'Expansion',
        codenameZh: '扩张',
        date: 'May 2026',
        dateZh: '2026年5月',
        features: [
          _ChangelogFeature(emoji: '\u{1f465}', text: 'Group Chat with E2EE, member panel, @mentions', textZh: '群聊功能，端到端加密，成员面板，@提及'),
          _ChangelogFeature(emoji: '\u{1f50d}', text: 'Global Search: contacts, groups, transactions', textZh: '全局搜索：联系人、群组、交易记录'),
          _ChangelogFeature(emoji: '\u{1f4cb}', text: 'Transaction History with filters, detail view', textZh: '交易历史，支持筛选和详情查看'),
          _ChangelogFeature(emoji: '\u{1f3db}\u{fe0f}', text: 'ZeroDAO: proposals, treasury, member voting', textZh: 'ZeroDAO：提案、金库、成员投票'),
          _ChangelogFeature(emoji: '\u{1f309}', text: 'ZeroBridge: ETH/BSC/SOL/TRX cross-chain', textZh: 'ZeroBridge：ETH/BSC/SOL/TRX 跨链桥'),
        ],
      ),
      _ChangelogVersion(
        version: 'v0.3.0',
        codename: 'Growth',
        codenameZh: '生长',
        date: 'April 2026',
        dateZh: '2026年4月',
        features: [
          _ChangelogFeature(emoji: '\u{1f6d2}', text: 'ZeroMarket with image upload, address book, delivery management', textZh: 'ZeroMarket 商城：图片上传、地址簿、配送管理'),
          _ChangelogFeature(emoji: '\u{1f511}', text: 'ZeroID OAuth: third-party app login', textZh: 'ZeroID OAuth：第三方应用登录'),
          _ChangelogFeature(emoji: '\u{1f4ce}', text: 'Chat attachments: camera, photo, file, location, GIF', textZh: '聊天附件：相机、照片、文件、位置、GIF'),
          _ChangelogFeature(emoji: '\u{1f4e1}', text: 'ZeroFeed decentralized social feed', textZh: 'ZeroFeed 去中心化社交动态'),
          _ChangelogFeature(emoji: '\u{1f5c4}\u{fe0f}', text: 'ZeroStore 2.0: encrypted storage, sharing, progress', textZh: 'ZeroStore 2.0：加密存储、共享、进度追踪'),
        ],
      ),
      _ChangelogVersion(
        version: 'v0.2.0',
        codename: 'Bloom',
        codenameZh: '绽放',
        date: 'March 2026',
        dateZh: '2026年3月',
        features: [
          _ChangelogFeature(emoji: '\u{1f310}', text: 'ZeroChain block explorer', textZh: 'ZeroChain 区块浏览器'),
          _ChangelogFeature(emoji: '\u{1f4de}', text: 'Voice & Video calls with call history', textZh: '语音/视频通话，含通话记录'),
          _ChangelogFeature(emoji: '\u{1f3ae}', text: 'Games Arcade (6 playable mini-games)', textZh: '游戏大厅（6款可玩迷你游戏）'),
          _ChangelogFeature(emoji: '\u{1f30d}', text: 'Full Chinese-English bilingual support', textZh: '完整中英文双语支持'),
          _ChangelogFeature(emoji: '\u{1f3a8}', text: '4 themes: Ink, Paper, Celadon, Amber', textZh: '四款主题：水墨、宣纸、霜月、翠竹'),
        ],
      ),
      _ChangelogVersion(
        version: 'v0.1.0',
        codename: 'Genesis',
        codenameZh: '创世',
        date: 'February 2026',
        dateZh: '2026年2月',
        features: [
          _ChangelogFeature(emoji: '\u{1f4ac}', text: 'ZeroChat with Double Ratchet E2EE', textZh: 'ZeroChat 聊天，Double Ratchet 端到端加密'),
          _ChangelogFeature(emoji: '\u{1f4b0}', text: 'ZeroPay: /pay command in chat', textZh: 'ZeroPay：聊天内 /pay 转账指令'),
          _ChangelogFeature(emoji: '\u{1f516}', text: 'ZeroID: BIP39 mnemonic identity', textZh: 'ZeroID：BIP39 助记词身份系统'),
          _ChangelogFeature(emoji: '\u{1f48e}', text: 'Multi-chain wallet (ETH, BSC, SOL, TRX, BTC)', textZh: '多链钱包（ETH、BSC、SOL、TRX、BTC）'),
          _ChangelogFeature(emoji: '\u{1f310}', text: 'ZeroDNS .zero domain registration', textZh: 'ZeroDNS .zero 域名注册'),
          _ChangelogFeature(emoji: '\u{1f9c5}', text: 'Onion routing with 3-hop circuits', textZh: '洋葱路由，3跳电路'),
        ],
      ),
    ];
  }

  Color _versionColor(String version) {
    switch (version) {
      case 'v0.1.0':
        return const Color(0xFF4A90D9);
      case 'v0.2.0':
        return context.zCeladon;
      case 'v0.3.0':
        return context.zWarning;
      case 'v0.4.0':
        return const Color(0xFF7B6FDE);
      case 'v0.5.0':
        return const Color(0xFFE070A0);
      case 'v0.6.0':
        return context.zAccent;
      default:
        return context.zAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '更新日志' : "What's New"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              isZh ? 'Zero 的进化之路' : 'The evolution of Zero',
              style: ZeroTypography.headline(context),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh ? '从创世到基建，每一步都值得铭记' : 'From Genesis to Infrastructure, every step matters',
              style: ZeroTypography.body(context),
            ),
            const SizedBox(height: ZeroSpacing.xl),
            ...List.generate(_versions.length, (i) {
              final version = _versions[i];
              final isLast = i == _versions.length - 1;
              return _buildTimelineEntry(context, i, version, isLast);
            }),
            const SizedBox(height: ZeroSpacing.md),
            _buildComingSoon(context),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEntry(
    BuildContext context,
    int index,
    _ChangelogVersion version,
    bool isLast,
  ) {
    final isZh = ZeroTheme.isZh(context);
    final color = _versionColor(version.version);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: ZeroSpacing.md + 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: context.zBg, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: context.zDivider,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: ZeroSpacing.lg),
              child: ZeroCard(
                padding: EdgeInsets.all(ZeroSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.sm + 2,
                            vertical: ZeroSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                          ),
                          child: Text(
                            version.version,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: ZeroSpacing.sm),
                        Text(
                          isZh ? version.codenameZh : version.codename,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isZh ? version.dateZh : version.date,
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: ZeroSpacing.sm + 2),
                    ...version.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              f.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: ZeroSpacing.xs),
                          Expanded(
                            child: Text(
                              isZh ? f.textZh : f.text,
                              style: ZeroTypography.body(context).copyWith(
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    final teasers = [
      _ChangelogFeature(
        emoji: '\u{1f9f1}',
        text: 'Rust wasm-pack integration for ZeroCore mobile bindings',
        textZh: 'Rust wasm-pack 集成，ZeroCore 移动端绑定',
      ),
      _ChangelogFeature(
        emoji: '\u{26d3}\u{fe0f}',
        text: 'ZeroChain L1 testnet launch with validator onboarding',
        textZh: 'ZeroChain L1 测试网上线，验证者入驻',
      ),
      _ChangelogFeature(
        emoji: '\u{1f389}',
        text: 'ZERO token TGE + community airdrop',
        textZh: 'ZERO 代币 TGE + 社区空投',
      ),
    ];

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.zAccent.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? '即将到来' : 'Coming Soon',
                style: ZeroTypography.title(context).copyWith(
                  color: context.zAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          ...teasers.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    t.emoji,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: ZeroSpacing.xs),
                Expanded(
                  child: Text(
                    isZh ? t.textZh : t.text,
                    style: ZeroTypography.body(context).copyWith(
                      fontSize: 14,
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ChangelogVersion {
  final String version;
  final String codename;
  final String codenameZh;
  final String date;
  final String dateZh;
  final List<_ChangelogFeature> features;

  const _ChangelogVersion({
    required this.version,
    required this.codename,
    required this.codenameZh,
    required this.date,
    required this.dateZh,
    required this.features,
  });
}

class _ChangelogFeature {
  final String emoji;
  final String text;
  final String textZh;

  const _ChangelogFeature({
    required this.emoji,
    required this.text,
    required this.textZh,
  });
}