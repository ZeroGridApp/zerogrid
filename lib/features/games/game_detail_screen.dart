import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;
  final String gameName;
  final String gameEmoji;

  const GameDetailScreen({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.gameEmoji,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with TickerProviderStateMixin {
  final Random _rng = Random();

  int _score = 0;
  int _highScore = 0;

  late List<int> _puzzleTiles;
  int _moveCount = 0;
  bool _puzzleWon = false;

  int _playerPos = 0;
  int _balance = 100;
  int _diceValue = 1;
  bool _isRolling = false;
  String _spaceEvent = '';

  int _playerRpsScore = 0;
  int _aiRpsScore = 0;
  int _rpsRound = 1;
  int? _playerChoice;
  int? _aiChoice;
  String _rpsResult = '';
  bool _rpsMatchOver = false;

  List<int> _slotReels = [0, 0, 0];
  bool _isSpinning = false;
  int _slotBalance = 500;
  String _slotResult = '';

  int _dartsTotal = 0;
  int _dartsRound = 1;
  int _dartsThrows = 0;
  int _lastDartScore = 0;
  bool _dartsGameOver = false;

  late List<List<int>> _tfeGrid;
  int _tfeScore = 0;
  bool _tfeWon = false;
  bool _tfeGameOver = false;

  bool _puzzleAnimating = false;
  int _winParticleCount = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    switch (widget.gameId) {
      case 'puzzle':
        _puzzleTiles = List.generate(16, (i) => i);
        _shufflePuzzle();
        break;
      case 'monopoly':
        _playerPos = 0;
        _balance = 100;
        _diceValue = 1;
        _spaceEvent = '';
        break;
      case 'rps':
        _playerRpsScore = 0;
        _aiRpsScore = 0;
        _rpsRound = 1;
        _playerChoice = null;
        _aiChoice = null;
        _rpsResult = '';
        _rpsMatchOver = false;
        break;
      case 'slots':
        _slotReels = [0, 0, 0];
        _isSpinning = false;
        _slotBalance = 500;
        _slotResult = '';
        break;
      case 'darts':
        _dartsTotal = 0;
        _dartsRound = 1;
        _dartsThrows = 0;
        _lastDartScore = 0;
        _dartsGameOver = false;
        break;
      case 'tfe':
        _tfeGrid = List.generate(4, (_) => List.filled(4, 0));
        _tfeScore = 0;
        _tfeWon = false;
        _tfeGameOver = false;
        _spawnTfeTile();
        _spawnTfeTile();
        break;
    }
    _score = 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateHighScore() {
    if (_score > _highScore) {
      setState(() => _highScore = _score);
    }
  }

  void _showShareDialog() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
        ),
        title: Text(
          isZh ? '分享成绩' : 'Share Score',
          style: ZeroTypography.title(context),
        ),
        content: Text(
          isZh
              ? '我在 ${widget.gameEmoji} ${widget.gameName} 中获得了 $_score 分！'
              : 'I scored $_score points in ${widget.gameEmoji} ${widget.gameName}!',
          style: ZeroTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isZh ? '关闭' : 'Close',
              style: TextStyle(color: context.zAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
        ),
        title: Text(
          isZh ? '排行榜' : 'Leaderboard',
          style: ZeroTypography.title(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < 3 ? context.zAccent : context.zFrostWhiteStrong,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: i < 3 ? context.zBg : context.zTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Text(
                      'ZeroPlayer${_rng.nextInt(9000) + 1000}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.zTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_rng.nextInt(500) + _score + (5 - i) * 50}',
                    style: ZeroTypography.monoSmall(context).copyWith(
                      color: context.zAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isZh ? '关闭' : 'Close',
              style: TextStyle(color: context.zAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.zTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.gameEmoji} ${widget.gameName}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: context.zTextPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ZeroSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_score',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.zAccent,
                  ),
                ),
                Text(
                  '${isZh ? '最高' : 'Best'} $_highScore',
                  style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildGameArea(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    switch (widget.gameId) {
      case 'puzzle':
        return _buildPuzzle();
      case 'monopoly':
        return _buildMonopoly();
      case 'rps':
        return _buildRps();
      case 'slots':
        return _buildSlots();
      case 'darts':
        return _buildDarts();
      case 'tfe':
        return _buildTfe();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    final isZh = ZeroTheme.isZh(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
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
            child: GestureDetector(
              onTap: _showShareDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                  border: Border.all(
                    color: context.zAccentMuted.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, size: 18, color: context.zAccent),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      isZh ? '分享成绩' : 'Share Score',
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
          ),
          const SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: _showLeaderboard,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                decoration: BoxDecoration(
                  gradient: context.zAccentGradient,
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard_rounded, size: 18, color: context.zBg),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      isZh ? '排行榜' : 'Leaderboard',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.zBg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzle() {
    final isZh = ZeroTheme.isZh(context);
    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isZh ? '步数' : 'Moves'}: $_moveCount',
                style: ZeroTypography.mono(context),
              ),
              GestureDetector(
                onTap: _puzzleWon ? _resetPuzzle : _shufflePuzzle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    border: Border.all(
                      color: context.zAccentMuted.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _puzzleWon
                        ? (isZh ? '再来一局' : 'Play Again')
                        : (isZh ? '打乱' : 'Shuffle'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.zAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Expanded(
            child: _puzzleWon ? _buildPuzzleWinEffect() : _buildPuzzleGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleWinEffect() {
    final isZh = ZeroTheme.isZh(context);
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(20, (i) {
                  final angle = (i / 20) * 2 * pi;
                  final radius = 60.0 + _rng.nextDouble() * 40;
                  final dx = cos(angle) * radius;
                  final dy = sin(angle) * radius;
                  final size = 6.0 + _rng.nextDouble() * 10;
                  final colors = [
                    context.zAccent,
                    context.zCeladon,
                    context.zWarning,
                    context.zSuccess,
                  ];
                  return AnimatedPositioned(
                    duration: Duration(milliseconds: 800 + i * 60),
                    curve: Curves.easeOutCubic,
                    left: dx,
                    top: dy,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[i % colors.length],
                      ),
                    ),
                  );
                }),
                const Text('🎉', style: TextStyle(fontSize: 64)),
              ],
            ),
            const SizedBox(height: ZeroSpacing.lg),
            Text(
              isZh ? '拼图完成！' : 'Puzzle Complete!',
              style: ZeroTypography.headline(context).copyWith(
                color: context.zAccent,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              isZh ? '共用了 $_moveCount 步' : 'Completed in $_moveCount moves',
              style: ZeroTypography.body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = (constraints.maxWidth - 12) / 4;
        return Center(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxWidth,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.zFrostWhiteStrong,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(16, (i) {
                final value = _puzzleTiles[i];
                if (value == 0) {
                  return SizedBox(width: tileSize, height: tileSize);
                }
                final isAdjacent = _isAdjacentToEmpty(i);
                final darkRatio = value / 15.0;
                final tileColor = Color.lerp(
                  context.zAccent,
                  context.zCeladon,
                  darkRatio,
                )!;
                return GestureDetector(
                  onTap: isAdjacent ? () => _moveTile(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: tileSize,
                    height: tileSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tileColor,
                          tileColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      boxShadow: [
                        BoxShadow(
                          color: tileColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: value > 9 ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: context.zBg,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  bool _isAdjacentToEmpty(int index) {
    final emptyIndex = _puzzleTiles.indexOf(0);
    final row = index ~/ 4;
    final col = index % 4;
    final emptyRow = emptyIndex ~/ 4;
    final emptyCol = emptyIndex % 4;
    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void _moveTile(int index) {
    final emptyIndex = _puzzleTiles.indexOf(0);
    setState(() {
      final temp = _puzzleTiles[index];
      _puzzleTiles[index] = 0;
      _puzzleTiles[emptyIndex] = temp;
      _moveCount++;
      _checkPuzzleWin();
    });
  }

  void _checkPuzzleWin() {
    final solved = List.generate(15, (i) => i + 1)..add(0);
    if (_listEquals(_puzzleTiles, solved)) {
      setState(() {
        _puzzleWon = true;
        _score = max(1000 - _moveCount * 10, 100);
      });
      _updateHighScore();
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _shufflePuzzle() {
    final tiles = List.generate(15, (i) => i + 1)..add(0);
    for (var i = 0; i < 200; i++) {
      final emptyIndex = tiles.indexOf(0);
      final row = emptyIndex ~/ 4;
      final col = emptyIndex % 4;
      final neighbors = <int>[];
      if (row > 0) neighbors.add(emptyIndex - 4);
      if (row < 3) neighbors.add(emptyIndex + 4);
      if (col > 0) neighbors.add(emptyIndex - 1);
      if (col < 3) neighbors.add(emptyIndex + 1);
      final swap = neighbors[_rng.nextInt(neighbors.length)];
      final temp = tiles[swap];
      tiles[swap] = 0;
      tiles[emptyIndex] = temp;
    }
    setState(() {
      _puzzleTiles = tiles;
      _moveCount = 0;
      _puzzleWon = false;
      _score = 0;
    });
  }

  void _resetPuzzle() {
    _shufflePuzzle();
  }

  Widget _buildMonopoly() {
    final isZh = ZeroTheme.isZh(context);
    final spaceNames = [
      {'name': 'Start', 'nameZh': '起点', 'emoji': '🚀', 'color': context.zAccent},
      {'name': '+5 ZERO', 'nameZh': '+5 ZERO', 'emoji': '💰', 'color': context.zSuccess},
      {'name': 'Chance', 'nameZh': '机会卡', 'emoji': '🎴', 'color': context.zWarning},
      {'name': '-3 ZERO', 'nameZh': '-3 ZERO', 'emoji': '💸', 'color': context.zError},
      {'name': 'Free Park', 'nameZh': '免费停车', 'emoji': '🅿️', 'color': Color(0xFF6BAFDB)},
      {'name': 'Go Jail', 'nameZh': '入狱', 'emoji': '🔒', 'color': Color(0xFFE8A040)},
      {'name': 'Community', 'nameZh': '社区福利', 'emoji': '🎁', 'color': Color(0xFF9B88C0)},
      {'name': '+8 ZERO', 'nameZh': '+8 ZERO', 'emoji': '💎', 'color': context.zSuccess},
    ];

    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isZh ? '余额' : 'Balance'}: $_balance ZERO',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _balance >= 0 ? context.zSuccess : context.zError,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('🎲 $_diceValue', style: ZeroTypography.mono(context).copyWith(fontSize: 20)),
                    if (_spaceEvent.isNotEmpty)
                      Text(
                        _spaceEvent,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.zAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final cellW = size / 3;
                final cellH = (size - 80) / 3;
                return Stack(
                  children: [
                    ...List.generate(8, (i) {
                      double left, top;
                      if (i == 0) { left = 0; top = 0; }
                      else if (i <= 2) { left = cellW * i; top = 0; }
                      else if (i == 3) { left = size - cellW; top = 0; }
                      else if (i == 4) { left = size - cellW; top = cellH; }
                      else if (i == 5) { left = size - cellW; top = cellH * 2; }
                      else if (i == 6) { left = cellW; top = cellH * 2; }
                      else { left = 0; top = cellH * 2; }

                      return Positioned(
                        left: left,
                        top: top,
                        width: cellW,
                        height: cellH,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _playerPos == i
                                ? (spaceNames[i]['color'] as Color).withOpacity(0.2)
                                : context.zFrostWhiteStrong,
                            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                            border: _playerPos == i
                                ? Border.all(
                                    color: spaceNames[i]['color'] as Color,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                spaceNames[i]['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isZh
                                    ? spaceNames[i]['nameZh'] as String
                                    : spaceNames[i]['name'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: context.zTextSecondary,
                                ),
                              ),
                              if (_playerPos == i)
                                const Text('🧑', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      left: cellW,
                      top: cellH,
                      width: cellW,
                      height: cellH,
                      child: Center(
                        child: Text(
                          '🎲',
                          style: TextStyle(fontSize: _isRolling ? 48 : 36),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          GestureDetector(
            onTap: _isRolling ? null : _rollDice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
              decoration: BoxDecoration(
                gradient: _isRolling ? null : context.zAccentGradient,
                color: _isRolling ? context.zFrostWhiteStrong : null,
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
              ),
              child: Text(
                _isRolling
                    ? (isZh ? '掷骰中...' : 'Rolling...')
                    : (isZh ? '🎲 掷骰子' : '🎲 Roll Dice'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isRolling ? context.zTextTertiary : context.zBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rollDice() async {
    setState(() => _isRolling = true);
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() => _diceValue = _rng.nextInt(6) + 1);
    }
    final roll = _rng.nextInt(6) + 1;
    setState(() {
      _diceValue = roll;
      _isRolling = false;
      _playerPos = (_playerPos + roll) % 8;
    });
    _applyMonopolyEvent();
  }

  void _applyMonopolyEvent() {
    final events = [
      () {
        _score += 5;
        _spaceEvent = '+5 ZERO';
      },
      () {
        _balance += 5;
        _score += 5;
        _spaceEvent = '+5 ZERO';
      },
      () {
        final bonus = _rng.nextInt(10) + 1;
        _balance += bonus;
        _score += bonus;
        _spaceEvent = '+$bonus ZERO (Chance)';
      },
      () {
        _balance -= 3;
        _score += 1;
        _spaceEvent = '-3 ZERO';
      },
      () {
        _score += 2;
        _spaceEvent = 'Free Parking';
      },
      () {
        _balance -= 5;
        _score -= 2;
        _spaceEvent = 'Go to Jail! -5';
      },
      () {
        final bonus = _rng.nextInt(8) + 3;
        _balance += bonus;
        _score += bonus;
        _spaceEvent = '+$bonus ZERO (Community)';
      },
      () {
        _balance += 8;
        _score += 8;
        _spaceEvent = '+8 ZERO';
      },
    ];
    events[_playerPos]();
    _updateHighScore();
    setState(() {});
  }

  Widget _buildRps() {
    final isZh = ZeroTheme.isZh(context);
    final choices = [
      {'emoji': '🪨', 'name': 'Rock', 'nameZh': '石头'},
      {'emoji': '📄', 'name': 'Paper', 'nameZh': '布'},
      {'emoji': '✂️', 'name': 'Scissors', 'nameZh': '剪刀'},
    ];

    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('🧑 ${isZh ? '你' : 'You'}', style: ZeroTypography.bodyBold(context)),
                    const SizedBox(height: 4),
                    Text(
                      '$_playerRpsScore',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.zAccent,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${isZh ? '第' : 'Round'} $_rpsRound',
                      style: ZeroTypography.caption(context),
                    ),
                    Text(
                      isZh ? '三局两胜' : 'Best of 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.zWarning,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('🤖 ZeroAI', style: ZeroTypography.bodyBold(context)),
                    const SizedBox(height: 4),
                    Text(
                      '$_aiRpsScore',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.zCeladon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          if (_rpsMatchOver)
            _buildRpsMatchOver(isZh)
          else ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_rpsResult.isNotEmpty) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_rpsResult),
                        children: [
                          Text(
                            _rpsResult,
                            style: ZeroTypography.displayMedium(context).copyWith(
                              color: _rpsResult.contains('Win') || _rpsResult.contains('赢')
                                  ? context.zSuccess
                                  : _rpsResult.contains('Lose') || _rpsResult.contains('输')
                                      ? context.zError
                                      : context.zWarning,
                            ),
                          ),
                          const SizedBox(height: ZeroSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                choices[_playerChoice ?? 0]['emoji']!,
                                style: const TextStyle(fontSize: 40),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
                                child: Text('VS', style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF888888),
                                )),
                              ),
                              Text(
                                choices[_aiChoice ?? 0]['emoji']!,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ZeroSpacing.xl),
                  ],
                  Text(
                    isZh ? '选择你的手势' : 'Choose your move',
                    style: ZeroTypography.body(context),
                  ),
                  const SizedBox(height: ZeroSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) {
                      return GestureDetector(
                        onTap: () => _playRps(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.zAccent.withOpacity(0.15),
                                context.zCeladon.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                            border: Border.all(
                              color: context.zAccentMuted.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                choices[i]['emoji']!,
                                style: const TextStyle(fontSize: 36),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isZh ? choices[i]['nameZh']! : choices[i]['name']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.zTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRpsMatchOver(bool isZh) {
    final playerWon = _playerRpsScore > _aiRpsScore;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              playerWon ? '🏆' : '😔',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              playerWon
                  ? (isZh ? '你赢了！' : 'You Win!')
                  : (isZh ? 'ZeroAI 赢了' : 'ZeroAI Wins!'),
              style: ZeroTypography.headline(context).copyWith(
                color: playerWon ? context.zSuccess : context.zError,
              ),
            ),
            const SizedBox(height: ZeroSpacing.lg),
            GestureDetector(
              onTap: () {
                setState(() {
                  _playerRpsScore = 0;
                  _aiRpsScore = 0;
                  _rpsRound = 1;
                  _rpsMatchOver = false;
                  _rpsResult = '';
                  _playerChoice = null;
                  _aiChoice = null;
                  _score = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.xl,
                  vertical: ZeroSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: context.zAccentGradient,
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                ),
                child: Text(
                  isZh ? '再来一局' : 'Play Again',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.zBg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playRps(int playerChoice) {
    final aiChoice = _rng.nextInt(3);
    String result;
    if (playerChoice == aiChoice) {
      result = 'Draw 🤝';
    } else if ((playerChoice == 0 && aiChoice == 2) ||
        (playerChoice == 1 && aiChoice == 0) ||
        (playerChoice == 2 && aiChoice == 1)) {
      result = 'You Win! 🎉';
    } else {
      result = 'You Lose! 💔';
    }

    setState(() {
      _playerChoice = playerChoice;
      _aiChoice = aiChoice;
      _rpsResult = result;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        if (result.contains('Win')) {
          _playerRpsScore++;
          _score += 100;
        } else if (result.contains('Lose')) {
          _aiRpsScore++;
        } else {
          _score += 30;
        }

        if (_playerRpsScore >= 2 || _aiRpsScore >= 2) {
          _rpsMatchOver = true;
          if (_playerRpsScore >= 2) _score += 200;
        } else {
          _rpsRound++;
        }
        _updateHighScore();
      });
    });
  }

  Widget _buildSlots() {
    final isZh = ZeroTheme.isZh(context);
    const emojis = ['🍒', '🍋', '🍊', '🍇', '💎', '7️⃣', '🔔', '⭐'];

    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Text(
            '${isZh ? '余额' : 'Balance'}: $_slotBalance ZERO',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.zAccent,
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(ZeroSpacing.lg),
                decoration: BoxDecoration(
                  color: context.zSurface,
                  borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                  border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: context.zAccentGlow.withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            key: ValueKey(_isSpinning ? 'spin_${_rng.nextInt(100)}' : 'slot_${_slotReels[i]}_$i'),
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  context.zAccent.withOpacity(0.1),
                                  context.zCeladon.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: context.zAccentMuted.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _isSpinning
                                    ? emojis[_rng.nextInt(emojis.length)]
                                    : emojis[_slotReels[i]],
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_slotResult.isNotEmpty) ...[
                      const SizedBox(height: ZeroSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.md,
                          vertical: ZeroSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _slotResult.contains('BIG') || _slotResult.contains('大')
                              ? context.zSuccess.withOpacity(0.15)
                              : _slotResult.contains('SMALL') || _slotResult.contains('小')
                                  ? context.zWarning.withOpacity(0.15)
                                  : context.zFrostWhiteStrong,
                          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                        ),
                        child: Text(
                          _slotResult,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _slotResult.contains('BIG') || _slotResult.contains('大')
                                ? context.zSuccess
                                : _slotResult.contains('SMALL') || _slotResult.contains('小')
                                    ? context.zWarning
                                    : context.zTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          GestureDetector(
            onTap: _isSpinning ? null : _spinSlots,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
              decoration: BoxDecoration(
                gradient: _isSpinning ? null : context.zAccentGradient,
                color: _isSpinning ? context.zFrostWhiteStrong : null,
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                boxShadow: _isSpinning
                    ? null
                    : [
                        BoxShadow(
                          color: context.zAccentGlow.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                _isSpinning
                    ? (isZh ? '🎰 旋转中...' : '🎰 Spinning...')
                    : (isZh ? '🎰 SPIN' : '🎰 SPIN'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _isSpinning ? context.zTextTertiary : context.zBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _spinSlots() async {
    setState(() {
      _isSpinning = true;
      _slotBalance -= 10;
      _slotResult = '';
    });

    for (var i = 0; i < 12; i++) {
      await Future.delayed(Duration(milliseconds: 60 + i * 20));
      setState(() {});
    }

    final r1 = _rng.nextInt(8);
    final r2 = _rng.nextInt(8);
    final r3 = _rng.nextInt(8);
    final isZh = ZeroTheme.isZh(context);

    String result;
    int winAmount = 0;
    if (r1 == r2 && r2 == r3) {
      result = isZh ? '🎉 大奖！' : '🎉 BIG WIN!';
      winAmount = 100;
    } else if (r1 == r2 || r2 == r3 || r1 == r3) {
      result = isZh ? '👍 小奖！' : '👍 SMALL WIN!';
      winAmount = 20;
    } else {
      result = isZh ? '😅 再试一次' : '😅 TRY AGAIN';
    }

    setState(() {
      _slotReels = [r1, r2, r3];
      _isSpinning = false;
      _slotBalance += winAmount;
      _score += winAmount;
      _slotResult = result;
    });
    _updateHighScore();
  }

  Widget _buildDarts() {
    final isZh = ZeroTheme.isZh(context);
    final outerColors = [context.zAccent, context.zCeladon, context.zAccent, context.zCeladon];
    final multipliers = ['1x', '2x', '3x', '5x'];

    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isZh ? '第' : 'Round'} $_dartsRound/5',
                style: ZeroTypography.bodyBold(context),
              ),
              Text(
                '${isZh ? '飞镖' : 'Dart'} ${_dartsThrows + 1}/3',
                style: ZeroTypography.body(context),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Expanded(
            child: _dartsGameOver
                ? _buildDartsGameOver(isZh)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ...List.generate(4, (i) {
                              final radius = 50.0 + i * 28.0;
                              return Container(
                                width: radius * 2,
                                height: radius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: outerColors[i].withOpacity(0.12),
                                  border: Border.all(
                                    color: outerColors[i].withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: i == 3
                                      ? Text(
                                          multipliers[i],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: outerColors[i],
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _lastDartScore > 0
                                    ? context.zAccent
                                    : Colors.transparent,
                              ),
                            ),
                            const Text('🎯', style: TextStyle(fontSize: 28)),
                          ],
                        ),
                        const SizedBox(height: ZeroSpacing.md),
                        if (_lastDartScore > 0)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '+$_lastDartScore',
                              key: ValueKey(_lastDartScore),
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: context.zAccent,
                              ),
                            ),
                          ),
                        const SizedBox(height: ZeroSpacing.sm),
                        Text(
                          '${isZh ? '总分' : 'Total'}: $_dartsTotal',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: context.zTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (!_dartsGameOver)
            GestureDetector(
              onTap: _throwDart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
                decoration: BoxDecoration(
                  gradient: context.zAccentGradient,
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                ),
                child: Text(
                  isZh ? '🎯 投掷飞镖' : '🎯 Throw Dart',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.zBg,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDartsGameOver(bool isZh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '游戏结束！' : 'Game Over!',
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            '${isZh ? '总分' : 'Final Score'}: $_dartsTotal',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: context.zAccent,
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          GestureDetector(
            onTap: () {
              setState(() {
                _dartsTotal = 0;
                _dartsRound = 1;
                _dartsThrows = 0;
                _lastDartScore = 0;
                _dartsGameOver = false;
                _score = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.xl,
                vertical: ZeroSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: context.zAccentGradient,
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
              ),
              child: Text(
                isZh ? '再来一局' : 'Play Again',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.zBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _throwDart() {
    final multipliers = [1, 2, 3, 5];
    final weights = [0.45, 0.30, 0.18, 0.07];
    final r = _rng.nextDouble();
    double cumulative = 0;
    int multiIndex = 0;
    for (var i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (r <= cumulative) {
        multiIndex = i;
        break;
      }
    }
    final multiplier = multipliers[multiIndex];
    final baseScore = _rng.nextInt(15) + 5;
    final dartScore = baseScore * multiplier;

    setState(() {
      _lastDartScore = dartScore;
      _dartsTotal += dartScore;
      _score += dartScore;
      _dartsThrows++;

      if (_dartsThrows >= 3) {
        _dartsThrows = 0;
        _dartsRound++;
        if (_dartsRound > 5) {
          _dartsGameOver = true;
          _score += _dartsTotal ~/ 2;
        }
      }
    });
    _updateHighScore();
  }

  Widget _buildTfe() {
    final isZh = ZeroTheme.isZh(context);
    return Padding(
      padding: const EdgeInsets.all(ZeroSpacing.screenHorizontal),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isZh ? '分数' : 'Score'}: $_tfeScore',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.zAccent,
                ),
              ),
              Row(
                children: [
                  if (_tfeWon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.zSuccess.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      ),
                      child: Text(
                        isZh ? '🎉 胜利！' : '🎉 You Win!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.zSuccess,
                        ),
                      ),
                    ),
                  const SizedBox(width: ZeroSpacing.sm),
                  GestureDetector(
                    onTap: _resetTfe,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.md,
                        vertical: ZeroSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                        border: Border.all(
                          color: context.zAccentMuted.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        isZh ? '新游戏' : 'New Game',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.zAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Expanded(
            child: _tfeGameOver
                ? _buildTfeGameOver(isZh)
                : GestureDetector(
                    onPanEnd: _handleTfeSwipe,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tileSize = (constraints.maxWidth - 12) / 4;
                        return Container(
                          width: constraints.maxWidth,
                          height: constraints.maxWidth,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.zFrostWhiteStrong,
                            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                          ),
                          child: Column(
                            children: List.generate(4, (r) {
                              return Row(
                                children: List.generate(4, (c) {
                                  final value = _tfeGrid[r][c];
                                  return Container(
                                    width: tileSize,
                                    height: tileSize,
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _tfeTileColor(value, context),
                                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                                    ),
                                    child: Center(
                                      child: value > 0
                                          ? Text(
                                              '$value',
                                              style: TextStyle(
                                                fontFamily: 'JetBrainsMono',
                                                fontSize: value > 512 ? 14 : (value > 64 ? 18 : 22),
                                                fontWeight: FontWeight.w700,
                                                color: value > 4 ? context.zBg : context.zTextPrimary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _tfeTileColor(int value, BuildContext context) {
    if (value == 0) return context.zSurface.withOpacity(0.4);
    final colors = <int, Color>{
      2: context.zAccent.withOpacity(0.2),
      4: context.zAccent.withOpacity(0.35),
      8: context.zAccent.withOpacity(0.55),
      16: context.zCeladon.withOpacity(0.5),
      32: context.zCeladon.withOpacity(0.65),
      64: context.zCeladon.withOpacity(0.8),
      128: context.zWarning.withOpacity(0.6),
      256: context.zWarning.withOpacity(0.75),
      512: context.zWarning.withOpacity(0.9),
      1024: context.zSuccess.withOpacity(0.7),
      2048: context.zSuccess,
      4096: const Color(0xFFFFD700),
      8192: const Color(0xFFFFA500),
    };
    return colors[value] ?? const Color(0xFFFF4500);
  }

  Widget _buildTfeGameOver(bool isZh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('😵', style: const TextStyle(fontSize: 72)),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            isZh ? '游戏结束！' : 'Game Over!',
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            '${isZh ? '最终分数' : 'Final Score'}: $_tfeScore',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: context.zAccent,
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          GestureDetector(
            onTap: _resetTfe,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.xl,
                vertical: ZeroSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: context.zAccentGradient,
                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
              ),
              child: Text(
                isZh ? '再来一局' : 'Try Again',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.zBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTfeSwipe(DragEndDetails details) {
    if (_tfeGameOver) return;
    final dx = details.primaryVelocity ?? 0;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _moveTfeRight();
      } else {
        _moveTfeLeft();
      }
    } else {
      if (dy > 0) {
        _moveTfeDown();
      } else {
        _moveTfeUp();
      }
    }
  }

  void _moveTfeLeft() {
    if (_processTfeMove(true, false)) return;
  }

  void _moveTfeRight() {
    if (_processTfeMove(true, true)) return;
  }

  void _moveTfeUp() {
    if (_processTfeMove(false, false)) return;
  }

  void _moveTfeDown() {
    if (_processTfeMove(false, true)) return;
  }

  bool _processTfeMove(bool isRow, bool reverse) {
    var moved = false;
    final oldGrid = _tfeGrid.map((r) => List<int>.from(r)).toList();

    for (var i = 0; i < 4; i++) {
      List<int> line = List.generate(4, (j) {
        return isRow ? _tfeGrid[i][j] : _tfeGrid[j][i];
      });

      if (reverse) line = line.reversed.toList();

      final compressed = line.where((v) => v != 0).toList();
      final merged = <int>[];
      var skip = false;
      for (var j = 0; j < compressed.length; j++) {
        if (skip) { skip = false; continue; }
        if (j < compressed.length - 1 && compressed[j] == compressed[j + 1]) {
          final newVal = compressed[j] * 2;
          merged.add(newVal);
          _tfeScore += newVal;
          _score += newVal;
          if (newVal >= 2048 && !_tfeWon) {
            _tfeWon = true;
          }
          skip = true;
        } else {
          merged.add(compressed[j]);
        }
      }

      while (merged.length < 4) {
        merged.add(0);
      }

      if (reverse) merged.setAll(0, merged.reversed.toList());

      for (var j = 0; j < 4; j++) {
        final target = isRow ? _tfeGrid[i][j] : _tfeGrid[j][i];
        final source = merged[j];
        if (target != source) moved = true;
        if (isRow) {
          _tfeGrid[i][j] = source;
        } else {
          _tfeGrid[j][i] = source;
        }
      }
    }

    if (moved) {
      _spawnTfeTile();
      _score = _tfeScore;
      _updateHighScore();
      if (_isTfeGameOver()) {
        _tfeGameOver = true;
      }
    }

    setState(() {});
    return false;
  }

  void _spawnTfeTile() {
    final empty = <int>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_tfeGrid[r][c] == 0) empty.add(r * 4 + c);
      }
    }
    if (empty.isEmpty) return;
    final idx = empty[_rng.nextInt(empty.length)];
    _tfeGrid[idx ~/ 4][idx % 4] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _isTfeGameOver() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_tfeGrid[r][c] == 0) return false;
        if (c < 3 && _tfeGrid[r][c] == _tfeGrid[r][c + 1]) return false;
        if (r < 3 && _tfeGrid[r][c] == _tfeGrid[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _resetTfe() {
    setState(() {
      _tfeGrid = List.generate(4, (_) => List.filled(4, 0));
      _tfeScore = 0;
      _score = 0;
      _tfeWon = false;
      _tfeGameOver = false;
      _spawnTfeTile();
      _spawnTfeTile();
    });
  }
}