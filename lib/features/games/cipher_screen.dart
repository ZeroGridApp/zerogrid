import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/games/cipher_service.dart';

class CipherScreen extends StatefulWidget {
  const CipherScreen({super.key});

  @override
  State<CipherScreen> createState() => _CipherScreenState();
}

class _CipherScreenState extends State<CipherScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxGuesses = 6;
  static const int _wordLength = 5;

  final CipherService _service = CipherService.instance;

  late String _targetWord;
  List<List<String>> _guesses = [];
  List<List<LetterStatus>> _guessResults = [];
  int _currentGuessIndex = 0;
  String _currentInput = '';
  bool _gameOver = false;
  bool _won = false;
  String _message = '';
  bool _messageError = false;
  bool _invalidShake = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final Map<String, dynamic> _storage = {};

  @override
  void initState() {
    super.initState();
    _targetWord = _service.todaysWord;
    _guesses = List.generate(_maxGuesses, (_) => []);
    _guessResults = List.generate(_maxGuesses, (_) => []);
    _checkExistingProgress();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        setState(() => _invalidShake = false);
      }
    });
  }

  void _checkExistingProgress() {
    final lastDate = _storage['cipher_last_played'] as String?;
    if (lastDate == _service.dateKey) {
      _gameOver = true;
      final lastResult = _storage['cipher_last_date_${_service.dateKey}'];
      if (lastResult != null) {
        _won = true;
        _message = '你已解出今日密码';
        _messageError = false;
      } else {
        _message = '今日挑战已结束，明天再来';
        _messageError = false;
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_gameOver) return;

    setState(() {
      _message = '';
      _messageError = false;

      if (key == 'ENTER') {
        _submitGuess();
      } else if (key == '⌫') {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      } else {
        if (_currentInput.length < _wordLength) {
          _currentInput += key;
        }
      }
    });
  }

  void _submitGuess() {
    if (_currentInput.length != _wordLength) {
      setState(() {
        _message = '需要输入5个字母';
        _messageError = true;
      });
      _triggerShake();
      return;
    }

    final result = _service.checkGuess(_currentInput, _targetWord);

    setState(() {
      _guesses[_currentGuessIndex] = _currentInput.split('');
      _guessResults[_currentGuessIndex] =
          result.map((r) => r.status).toList();
      _currentGuessIndex++;
      _currentInput = '';

      if (_service.isWin(result)) {
        _gameOver = true;
        _won = true;
        _message = '🎉 破解成功！';
        _messageError = false;
        _service.saveStats(_storage, true, _currentGuessIndex);
      } else if (_currentGuessIndex >= _maxGuesses) {
        _gameOver = true;
        _won = false;
        _message = '密码是：$_targetWord';
        _messageError = true;
        _service.saveStats(_storage, false, _currentGuessIndex);
      }
    });
  }

  void _triggerShake() {
    setState(() => _invalidShake = true);
    _shakeController.forward(from: 0);
  }

  Color _getTileColor(LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
        return const Color(0xFF538D4E);
      case LetterStatus.wrongPosition:
        return const Color(0xFFB59F3B);
      case LetterStatus.incorrect:
        return const Color(0xFF3A3A3C);
      default:
        return context.zSurface;
    }
  }

  Color _getKeyColor(String key) {
    bool isCorrect = false;
    bool isWrongPos = false;
    bool isIncorrect = false;

    for (int i = 0; i < _currentGuessIndex; i++) {
      for (int j = 0; j < _guesses[i].length; j++) {
        if (_guesses[i][j].toUpperCase() == key) {
          if (_guessResults[i][j] == LetterStatus.correct) {
            isCorrect = true;
          } else if (_guessResults[i][j] == LetterStatus.wrongPosition) {
            isWrongPos = true;
          } else if (_guessResults[i][j] == LetterStatus.incorrect) {
            isIncorrect = true;
          }
        }
      }
    }

    if (isCorrect) return const Color(0xFF538D4E);
    if (isWrongPos) return const Color(0xFFB59F3B);
    if (isIncorrect) return const Color(0xFF3A3A3C);
    return context.zFrostWhiteStrong;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: ZeroSpacing.sm),
            Text(
              'ZeroGrid Cipher',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: context.zTextSecondary),
            onPressed: _showStatsPopup,
            tooltip: isZh ? '统计' : 'Stats',
          ),
          IconButton(
            icon: Icon(Icons.help_outline_rounded,
                color: context.zTextSecondary),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.md,
                  vertical: ZeroSpacing.sm + 2,
                ),
                margin: const EdgeInsets.fromLTRB(
                  ZeroSpacing.screenHorizontal,
                  0,
                  ZeroSpacing.screenHorizontal,
                  ZeroSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _messageError
                      ? const Color(0xFFFF4444).withOpacity(0.15)
                      : const Color(0xFF538D4E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: _messageError
                        ? const Color(0xFFFF4444).withOpacity(0.3)
                        : const Color(0xFF538D4E).withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _messageError
                        ? const Color(0xFFFF4444)
                        : const Color(0xFF538D4E),
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.screenHorizontal,
                  ),
                  child: _buildGrid(),
                ),
              ),
            ),
            if (_gameOver && _won)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                  vertical: ZeroSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showStatsPopup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: ZeroSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: context.zAccentGradient,
                            borderRadius: BorderRadius.circular(
                                ZeroSpacing.buttonRadius),
                          ),
                          child: Text(
                            isZh ? '📊 查看统计' : '📊 View Stats',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.zBg,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: _shareResult,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: ZeroSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1DA1F2),
                                Color(0xFF0D8BD9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                                ZeroSpacing.buttonRadius),
                          ),
                          child: Text(
                            isZh ? '📤 分享战绩' : '📤 Share',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.zBg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: ZeroSpacing.sm),
            _buildKeyboard(isZh),
          ],
          ),
        ),
      );
  }

  Widget _buildGrid() {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_maxGuesses, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final isShakingRow = _invalidShake && row == _currentGuessIndex;
                final offset = isShakingRow ? _shakeAnimation.value : 0.0;
                return Transform.translate(
                  offset: Offset(
                    isShakingRow
                        ? (row % 2 == 0 ? offset : -offset)
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_wordLength, (col) {
                  String letter = '';
                  LetterStatus status = LetterStatus.unused;

                  if (row < _currentGuessIndex) {
                    letter = _guesses[row].length > col
                        ? _guesses[row][col]
                        : '';
                    status = _guessResults[row].length > col
                        ? _guessResults[row][col]
                        : LetterStatus.unused;
                  } else if (row == _currentGuessIndex) {
                    letter = _currentInput.length > col
                        ? _currentInput[col]
                        : '';
                  }

                  final isFilled = letter.isNotEmpty;
                  final isCurrentRow = row == _currentGuessIndex;
                  final isRevealing = row < _currentGuessIndex;

                  return AnimatedContainer(
                    duration: Duration(
                      milliseconds: isRevealing ? 300 + col * 100 : 150,
                    ),
                    curve: Curves.easeInOut,
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isRevealing
                          ? _getTileColor(status)
                          : isFilled && isCurrentRow
                              ? context.zFrostWhiteStrong
                              : context.zSurface,
                      borderRadius:
                          BorderRadius.circular(ZeroSpacing.chipRadius - 2),
                      border: Border.all(
                        color: isFilled && isCurrentRow && !isRevealing
                            ? context.zTextTertiary.withOpacity(0.6)
                            : context.zFrostWhiteStrong.withOpacity(0.3),
                        width: isFilled && isCurrentRow && !isRevealing
                            ? 1.5
                            : 0.5,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          letter.toUpperCase(),
                          key: ValueKey('$row$col$letter'),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isRevealing && status != LetterStatus.unused
                                ? Colors.white
                                : context.zTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeyboard(bool isZh) {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      decoration: BoxDecoration(
        color: context.zBg,
        border: Border(
          top: BorderSide(
            color: context.zFrostWhiteStrong.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isSpecial = key == 'ENTER' || key == '⌫';
                final width = isSpecial ? 56.0 : 34.0;
                final fontSize = isSpecial ? 11.0 : 16.0;

                return GestureDetector(
                  onTap: () => _onKeyTap(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: width,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSpecial
                          ? context.zFrostWhiteStrong
                          : _getKeyColor(key.toUpperCase()),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: isSpecial || _getKeyColor(key.toUpperCase()) == context.zFrostWhiteStrong
                              ? context.zTextPrimary
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _shareResult() {
    final grid = _guessResults
        .where((r) => r.isNotEmpty)
        .toList();
    final text = _service.generateShareText(_currentGuessIndex, grid);
    showDialog(
      context: context,
      builder: (ctx) {
        final isZh = ZeroTheme.isZh(ctx);
        return AlertDialog(
          backgroundColor: context.zSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          ),
          title: Text(
            isZh ? '📤 分享战绩' : '📤 Share Result',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.zTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(ZeroSpacing.md),
                decoration: BoxDecoration(
                  color: context.zBg,
                  borderRadius:
                      BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: context.zFrostWhiteStrong,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.zTextPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: ZeroSpacing.md),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: ZeroSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: context.zAccentGradient,
                    borderRadius: BorderRadius.circular(
                        ZeroSpacing.buttonRadius),
                  ),
                  child: Text(
                    isZh ? '复制并关闭' : 'Copy & Close',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.zBg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatsPopup() {
    final stats = _service.loadStats(_storage);
    final isZh = ZeroTheme.isZh(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.zSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          ),
          title: Text(
            isZh ? '📊 游戏统计' : '📊 Statistics',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.zTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statsItem(
                    isZh ? '已玩' : 'Played',
                    '${stats.played}',
                  ),
                  _statsItem(
                    isZh ? '胜率' : 'Win %',
                    '${stats.winRate.toStringAsFixed(0)}%',
                  ),
                  _statsItem(
                    isZh ? '连胜' : 'Streak',
                    '${stats.currentStreak}',
                  ),
                  _statsItem(
                    isZh ? '最长连胜' : 'Max Streak',
                    '${stats.maxStreak}',
                  ),
                ],
              ),
              const SizedBox(height: ZeroSpacing.lg),
              Text(
                isZh ? '猜词分布' : 'Guess Distribution',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.zTextSecondary,
                ),
              ),
              const SizedBox(height: ZeroSpacing.sm),
              ...List.generate(6, (i) {
                final count = stats.guessDistribution[i + 1] ?? 0;
                final maxCount = stats.guessDistribution.values.isEmpty
                    ? 1
                    : stats.guessDistribution.values
                        .reduce((a, b) => a > b ? a : b);
                final barWidth = maxCount == 0
                    ? 0.0
                    : count / maxCount * 180.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            color: context.zTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: max(barWidth, count > 0 ? 20 : 4),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? (i + 1 <= _currentGuessIndex && _won
                                  ? const Color(0xFF538D4E)
                                  : context.zFrostWhiteStrong)
                              : context.zFrostWhiteStrong.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: count > 0
                            ? Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: (i + 1 <= _currentGuessIndex &&
                                            _won)
                                        ? Colors.white
                                        : context.zTextSecondary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isZh ? '关闭' : 'Close',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statsItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.zTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showHowToPlay() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.zSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          ),
          title: Text(
            isZh ? '🎮 游戏规则' : '🎮 How to Play',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.zTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleRow('🟩', isZh ? '绿色：字母和位置都正确' : 'Green: Correct letter & position'),
              const SizedBox(height: ZeroSpacing.sm),
              _ruleRow('🟨', isZh ? '黄色：字母正确但位置不对' : 'Yellow: Correct letter, wrong position'),
              const SizedBox(height: ZeroSpacing.sm),
              _ruleRow('⬛', isZh ? '黑色：字母不在此单词中' : 'Black: Letter not in the word'),
              const SizedBox(height: ZeroSpacing.md),
              Container(
                padding: const EdgeInsets.all(ZeroSpacing.md),
                decoration: BoxDecoration(
                  color: context.zBg,
                  borderRadius:
                      BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: context.zAccentMuted.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isZh
                      ? '💡 提示：每天只有一次挑战机会！密码是加密/区块链/Web3相关的英文单词，共5个字母。你有6次猜测机会。'
                      : '💡 Tip: One challenge per day! The password is a 5-letter word related to crypto/blockchain/Web3. You have 6 attempts.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.5,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isZh ? '开始挑战' : 'Let\'s Go',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ruleRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.zTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}