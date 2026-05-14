import 'dart:math';
import 'package:intl/intl.dart';

class CipherService {
  static final CipherService _instance = CipherService._();
  static CipherService get instance => _instance;

  CipherService._();

  static const _wordList = [
    'ZERO', 'CRYPTO', 'BLOCK', 'CHAIN', 'SHARE', 'SECRET', 'PRIVACY',
    'WALLET', 'SIGNAL', 'ENCRYPT', 'DECRYPT', 'PUBLIC', 'PRIVATE',
    'KEY', 'CODE', 'CIPHER', 'CRYPT', 'HASH', 'SALT', 'TOKEN',
    'NODE', 'PEER', 'NETWORK', 'DHT', 'HELLO', 'WORLD', 'BRAVE',
    'SMART', 'CONTRACT', 'ADDRESS', 'BALANCE', 'TRANSACT', 'MINER',
    'VALIDATE', 'CONSENSUS', 'ALGORITHM', 'PROTOCOL', 'BYTES', 'SIGN',
    'VERIFY', 'AUTHENTIC', 'GUESS', 'CHECK', 'SOLVE', 'PUZZLE',
    'DAILY', 'CHALLENGE', 'REWARD', 'POINT', 'STREAK', 'SCORE',
    'BLACK', 'WHITE', 'GRAY', 'GREEN', 'YELLOW', 'RIGHT', 'WRONG',
    'PLACE', 'LETTER', 'ALPHA', 'NUMBER', 'SHIFT', 'XOR', 'AES',
    'RSA', 'ECDH', 'BIP39', 'SEED', 'PHRASE', 'MNEMONIC', 'DERIVE',
    'BITCOIN', 'ETHEREUM', 'ZEROCORE', 'ZERONODE', 'ZEROWALLET',
    'BRIDGE', 'RELAY', 'STORAGE', 'BOOTSTRAP', 'DISTRIBUTE', 'DECENTRAL',
    'ANONYMOUS', 'CONFIDEN', 'INTEGRITY', 'AVAILABL', 'SECURITY',
  ];

  List<String> get wordList => _wordList.where((w) => w.length == 5).toList();

  String get todaysWord {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final rng = Random(seed);
    final fiveLetterWords = wordList;
    final index = rng.nextInt(fiveLetterWords.length);
    return fiveLetterWords[index];
  }

  String get dateKey {
    final today = DateTime.now();
    return DateFormat('yyyyMMdd').format(today);
  }

  List<CipherGuessResult> checkGuess(String guess, String target) {
    guess = guess.toUpperCase();
    target = target.toUpperCase();

    if (guess.length != target.length) {
      return [];
    }

    List<CipherGuessResult> result = [];
    List<bool> targetMatched = List.filled(target.length, false);
    List<bool> guessMatched = List.filled(guess.length, false);

    for (int i = 0; i < guess.length; i++) {
      if (guess[i] == target[i]) {
        result.add(CipherGuessResult(guess[i], LetterStatus.correct));
        targetMatched[i] = true;
        guessMatched[i] = true;
      }
    }

    for (int i = 0; i < guess.length; i++) {
      if (guessMatched[i]) continue;

      bool found = false;
      for (int j = 0; j < target.length; j++) {
        if (!targetMatched[j] && guess[i] == target[j]) {
          result.add(CipherGuessResult(guess[i], LetterStatus.wrongPosition));
          targetMatched[j] = true;
          guessMatched[i] = true;
          found = true;
          break;
        }
      }

      if (!found) {
        result.add(CipherGuessResult(guess[i], LetterStatus.incorrect));
      }
    }

    return result;
  }

  bool isWin(List<CipherGuessResult> results) {
    return results.every((r) => r.status == LetterStatus.correct);
  }

  CipherStats loadStats(Map<String, dynamic> storage) {
    final played = storage['cipher_played'] as int? ?? 0;
    final won = storage['cipher_won'] as int? ?? 0;
    final currentStreak = storage['cipher_streak'] as int? ?? 0;
    final maxStreak = storage['cipher_max_streak'] as int? ?? 0;
    final guessDistribution = Map<int, int>.from(
      storage['cipher_distribution'] as Map? ?? {},
    );

    return CipherStats(
      played: played,
      won: won,
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      guessDistribution: guessDistribution,
    );
  }

  void saveStats(
    Map<String, dynamic> storage,
    bool won,
    int guessCount,
  ) {
    var stats = loadStats(storage);

    stats = stats.copyWith(
      played: stats.played + 1,
    );

    if (won) {
      final newDistribution = Map<int, int>.from(stats.guessDistribution);
      newDistribution[guessCount] = (newDistribution[guessCount] ?? 0) + 1;

      stats = stats.copyWith(
        won: stats.won + 1,
        currentStreak: stats.currentStreak + 1,
        maxStreak: max(stats.maxStreak, stats.currentStreak + 1),
        guessDistribution: newDistribution,
      );
    } else {
      stats = stats.copyWith(
        currentStreak: 0,
      );
    }

    storage['cipher_played'] = stats.played;
    storage['cipher_won'] = stats.won;
    storage['cipher_streak'] = stats.currentStreak;
    storage['cipher_max_streak'] = stats.maxStreak;
    storage['cipher_distribution'] = stats.guessDistribution;
    storage['cipher_last_played'] = dateKey;

    if (won) {
      storage['cipher_last_date_${dateKey}'] = guessCount;
    }
  }

  bool get alreadyPlayedToday {
    return false;
  }

  int? get lastGuessCount {
    return null;
  }

  double get winPercentage {
    return 0;
  }

  String generateShareText(
    int guessCount,
    List<List<LetterStatus>> grid,
  ) {
    final emojis = grid.map((row) {
      return row.map((status) {
        switch (status) {
          case LetterStatus.correct:
            return '🟩';
          case LetterStatus.wrongPosition:
            return '🟨';
          case LetterStatus.incorrect:
          case LetterStatus.unused:
            return '⬛';
        }
      }).join('');
    }).join('\n');

    return 'ZeroGrid Cipher $dateKey $guessCount/6\n\n$emojis\n\nPlay at ZeroGrid: https://zerogrid.xyz';
  }
}

enum LetterStatus {
  unused,
  incorrect,
  wrongPosition,
  correct,
}

class CipherGuessResult {
  final String letter;
  final LetterStatus status;

  CipherGuessResult(this.letter, this.status);
}

class CipherStats {
  final int played;
  final int won;
  final int currentStreak;
  final int maxStreak;
  final Map<int, int> guessDistribution;

  CipherStats({
    required this.played,
    required this.won,
    required this.currentStreak,
    required this.maxStreak,
    required this.guessDistribution,
  });

  CipherStats copyWith({
    int? played,
    int? won,
    int? currentStreak,
    int? maxStreak,
    Map<int, int>? guessDistribution,
  }) {
    return CipherStats(
      played: played ?? this.played,
      won: won ?? this.won,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      guessDistribution: guessDistribution ?? this.guessDistribution,
    );
  }

  double get winRate => played == 0 ? 0 : won / played * 100;
}
