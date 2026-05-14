import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import 'cipher_screen.dart';
import 'game_detail_screen.dart';

class GamesArcadeScreen extends StatelessWidget {
  const GamesArcadeScreen({super.key});

  static const _games = [
    _GameInfo(
      id: 'cipher',
      emoji: '🔐',
      name: 'ZeroGrid Cipher',
      nameZh: '每日密码',
      desc: 'New daily challenge! Guess the secret word',
      descZh: '每日全新挑战！猜出加密单词',
      plays: 'NEW',
      gradientColors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    ),
    _GameInfo(
      id: 'puzzle',
      emoji: '🧩',
      name: 'Zero Puzzle',
      nameZh: '零界拼图',
      desc: 'Slide tiles to solve the puzzle',
      descZh: '滑动拼图，还原顺序',
      plays: '12.4K',
      gradientColors: [Color(0xFFB8A57A), Color(0xFFF0D89C)],
    ),
    _GameInfo(
      id: 'monopoly',
      emoji: '🎲',
      name: 'Blockchain Monopoly',
      nameZh: '区块链大富翁',
      desc: 'Roll dice, buy properties, win big',
      descZh: '掷骰子，买地皮，赢大奖',
      plays: '8.7K',
      gradientColors: [Color(0xFF7AAC9E), Color(0xFFB8E8D0)],
    ),
    _GameInfo(
      id: 'rps',
      emoji: '✂️',
      name: 'RPS Duel',
      nameZh: '猜拳对决',
      desc: 'Rock Paper Scissors showdown',
      descZh: '石头剪刀布巅峰对决',
      plays: '15.2K',
      gradientColors: [Color(0xFFC08060), Color(0xFFF0B090)],
    ),
    _GameInfo(
      id: 'slots',
      emoji: '🎰',
      name: 'Lucky Spin',
      nameZh: '幸运老虎机',
      desc: 'Spin the reels, hit the jackpot',
      descZh: '转动转盘，赢取大奖',
      plays: '22.1K',
      gradientColors: [Color(0xFF9B88C0), Color(0xFFD0B8F0)],
    ),
    _GameInfo(
      id: 'darts',
      emoji: '🎯',
      name: 'Crypto Darts',
      nameZh: '加密飞镖',
      desc: 'Aim, throw, score big',
      descZh: '瞄准投掷，勇夺高分',
      plays: '6.3K',
      gradientColors: [Color(0xFFC08090), Color(0xFFF0B0C0)],
    ),
    _GameInfo(
      id: 'tfe',
      emoji: '🔢',
      name: '2048 Zero',
      nameZh: '数字滑动',
      desc: 'Merge tiles to reach 2048',
      descZh: '合并数字，达成2048',
      plays: '18.9K',
      gradientColors: [Color(0xFF80A0C0), Color(0xFFB8D0F0)],
    ),
  ];

  static const _comingSoon = [
    _ComingSoonInfo(emoji: '🃏', name: 'Poker', nameZh: '扑克'),
    _ComingSoonInfo(emoji: '♟️', name: 'Chess', nameZh: '国际象棋'),
    _ComingSoonInfo(emoji: '🏎️', name: 'Racing', nameZh: '竞速赛车'),
  ];

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isZh ? '🎮 零界游戏厅' : '🎮 ZeroGrid Arcade',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenTop,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZh ? '精选游戏' : 'Featured Games',
              style: ZeroTypography.headline(context),
            ),
            const SizedBox(height: ZeroSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: ZeroSpacing.md,
                crossAxisSpacing: ZeroSpacing.md,
                childAspectRatio: 0.82,
              ),
              itemCount: _games.length,
              itemBuilder: (context, index) => _GameCard(
                game: _games[index],
                isZh: isZh,
              ),
            ),
            const SizedBox(height: ZeroSpacing.xl),
            Text(
              isZh ? '即将上线' : 'Coming Soon',
              style: ZeroTypography.headline(context),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Row(
              children: _comingSoon.map((g) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: g != _comingSoon.last ? ZeroSpacing.md : 0,
                  ),
                  child: _ComingSoonCard(info: g, isZh: isZh),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameInfo {
  final String id;
  final String emoji;
  final String name;
  final String nameZh;
  final String desc;
  final String descZh;
  final String plays;
  final List<Color> gradientColors;

  const _GameInfo({
    required this.id,
    required this.emoji,
    required this.name,
    required this.nameZh,
    required this.desc,
    required this.descZh,
    required this.plays,
    required this.gradientColors,
  });
}

class _ComingSoonInfo {
  final String emoji;
  final String name;
  final String nameZh;

  const _ComingSoonInfo({
    required this.emoji,
    required this.name,
    required this.nameZh,
  });
}

class _GameCard extends StatelessWidget {
  final _GameInfo game;
  final bool isZh;

  const _GameCard({required this.game, required this.isZh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (game.id == 'cipher') {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const CipherScreen(),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => GameDetailScreen(
                gameId: game.id,
                gameName: isZh ? game.nameZh : game.name,
                gameEmoji: game.emoji,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(
            color: context.zFrostWhiteStrong,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(ZeroSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: game.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: game.gradientColors.first.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  game.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? game.nameZh : game.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.zTextPrimary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              isZh ? game.descZh : game.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ZeroTypography.caption(context).copyWith(
                fontSize: 11,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: ZeroSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                gradient: context.zAccentGradient,
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius - 4),
              ),
              child: Text(
                isZh ? '开始游戏' : 'Play',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.zBg,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.zAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${game.plays} ${isZh ? '次游玩' : 'plays'}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final _ComingSoonInfo info;
  final bool isZh;

  const _ComingSoonCard({required this.info, required this.isZh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.zSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
        border: Border.all(
          color: context.zFrostWhiteStrong.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zFrostWhiteStrong,
                ),
                child: Center(
                  child: Text(
                    info.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.zWarning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isZh ? '即将' : 'Soon',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            isZh ? info.nameZh : info.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.zTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}