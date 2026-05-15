class TransactionRecord {
  final String id;
  final String txHash;
  final String type;
  final String status;
  final String chainId;
  final String chainName;
  final String token;
  final double amount;
  final double usdValue;
  final String fromAddress;
  final String toAddress;
  final String? toName;
  final double fee;
  final double feeUsd;
  final String? memo;
  final DateTime timestamp;
  final int? blockNumber;
  final int confirmations;

  const TransactionRecord({
    required this.id,
    required this.txHash,
    required this.type,
    required this.status,
    required this.chainId,
    required this.chainName,
    required this.token,
    required this.amount,
    required this.usdValue,
    required this.fromAddress,
    required this.toAddress,
    this.toName,
    required this.fee,
    required this.feeUsd,
    this.memo,
    required this.timestamp,
    this.blockNumber,
    this.confirmations = 12,
  });
}

class TransactionSummary {
  final double totalSent;
  final double totalReceived;
  final double totalFees;
  final int transactionCount;
  final String mostUsedChain;
  final String mostUsedToken;

  const TransactionSummary({
    required this.totalSent,
    required this.totalReceived,
    required this.totalFees,
    required this.transactionCount,
    required this.mostUsedChain,
    required this.mostUsedToken,
  });
}

class ZeroTransactionHistoryService {
  static final ZeroTransactionHistoryService _instance = ZeroTransactionHistoryService._();
  factory ZeroTransactionHistoryService() => _instance;
  ZeroTransactionHistoryService._();

  final List<TransactionRecord> _transactions = [];

  List<TransactionRecord> getAllTransactions() {
    final sorted = List<TransactionRecord>.from(_transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  List<TransactionRecord> getSentTransactions() {
    return _transactions
        .where((t) => t.type == 'sent')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionRecord> getReceivedTransactions() {
    return _transactions
        .where((t) => t.type == 'received')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionRecord> getTransactionsByChain(String chainId) {
    return _transactions
        .where((t) => t.chainId == chainId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  TransactionRecord? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TransactionRecord> searchTransactions(String query) {
    final q = query.toLowerCase();
    return _transactions.where((t) {
      return t.token.toLowerCase().contains(q) ||
          (t.memo?.toLowerCase().contains(q) ?? false) ||
          t.fromAddress.toLowerCase().contains(q) ||
          t.toAddress.toLowerCase().contains(q) ||
          (t.toName?.toLowerCase().contains(q) ?? false);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  TransactionSummary getSummary() {
    if (_transactions.isEmpty) {
      return const TransactionSummary(
        totalSent: 0,
        totalReceived: 0,
        totalFees: 0,
        transactionCount: 0,
        mostUsedChain: '',
        mostUsedToken: '',
      );
    }

    double totalSent = 0;
    double totalReceived = 0;
    double totalFees = 0;
    final chainCount = <String, int>{};
    final tokenCount = <String, int>{};

    for (final t in _transactions) {
      if (t.type == 'sent') {
        totalSent += t.usdValue;
      }
      if (t.type == 'received') {
        totalReceived += t.usdValue;
      }
      totalFees += t.feeUsd;
      chainCount[t.chainId] = (chainCount[t.chainId] ?? 0) + 1;
      tokenCount[t.token] = (tokenCount[t.token] ?? 0) + 1;
    }

    String mostUsedChain = _transactions.first.chainId;
    int maxChain = 0;
    chainCount.forEach((chain, count) {
      if (count > maxChain) {
        maxChain = count;
        mostUsedChain = chain;
      }
    });

    String mostUsedToken = _transactions.first.token;
    int maxToken = 0;
    tokenCount.forEach((token, count) {
      if (count > maxToken) {
        maxToken = count;
        mostUsedToken = token;
      }
    });

    return TransactionSummary(
      totalSent: (totalSent * 100).roundToDouble() / 100,
      totalReceived: (totalReceived * 100).roundToDouble() / 100,
      totalFees: (totalFees * 100).roundToDouble() / 100,
      transactionCount: _transactions.length,
      mostUsedChain: mostUsedChain,
      mostUsedToken: mostUsedToken,
    );
  }

  void addTransaction(TransactionRecord tx) {
    _transactions.insert(0, tx);
  }

  String formatAddress(String addr) {
    if (addr.length <= 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }
}