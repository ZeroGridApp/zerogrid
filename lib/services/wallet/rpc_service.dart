import 'dart:math';

class TxHistoryItem {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final String symbol;
  final DateTime timestamp;
  final String status;
  final double fee;

  const TxHistoryItem({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.symbol,
    required this.timestamp,
    required this.status,
    required this.fee,
  });
}

class ChainConfig {
  final String chainId;
  final String symbol;
  final int decimals;

  const ChainConfig({
    required this.chainId,
    required this.symbol,
    required this.decimals,
  });
}

class RpcService {
  static final RpcService _instance = RpcService._();
  factory RpcService() => _instance;
  RpcService._();

  final _random = Random();
  final _recentTxCache = <String, List<TxHistoryItem>>{};

  static const _chains = {
    'eth': ChainConfig(chainId: 'eth', symbol: 'ETH', decimals: 18),
    'bsc': ChainConfig(chainId: 'bsc', symbol: 'BNB', decimals: 18),
    'btc': ChainConfig(chainId: 'btc', symbol: 'BTC', decimals: 8),
    'trx': ChainConfig(chainId: 'trx', symbol: 'TRX', decimals: 6),
    'sol': ChainConfig(chainId: 'sol', symbol: 'SOL', decimals: 9),
  };

  static const _stableCoins = {
    'usdt': ChainConfig(chainId: 'usdt', symbol: 'USDT', decimals: 6),
    'usdc': ChainConfig(chainId: 'usdc', symbol: 'USDC', decimals: 6),
  };

  ChainConfig? getChainConfig(String chainId) => _chains[chainId.toLowerCase()];

  Future<double> getBalance(String chainId, String address) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    if (!_chains.containsKey(normalized)) {
      throw RpcException('Unsupported chain: $chainId');
    }

    return 0.0;
  }

  Future<double> getTokenBalance(String chainId, String token, String address) async {
    await _simulateNetworkDelay();

    if (!_stableCoins.containsKey(token.toLowerCase())) {
      throw RpcException('Unsupported token: $token');
    }

    return 0.0;
  }

  Future<double> getUsdPrice(String chainId) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    if (!_chains.containsKey(normalized)) {
      throw RpcException('Unsupported chain: $chainId');
    }

    return 0.0;
  }

  Future<List<TxHistoryItem>> getTransactions(String chainId, String address) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    if (!_chains.containsKey(normalized)) {
      throw RpcException('Unsupported chain: $chainId');
    }

    return [];
  }

  Future<String> broadcastTransaction(String chainId, String signedTx) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    if (!_chains.containsKey(normalized)) {
      throw RpcException('Unsupported chain: $chainId');
    }

    final success = _random.nextDouble() > 0.05;
    if (!success) {
      throw RpcException('Transaction rejected by network. Please try again.');
    }

    final hashBytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final hash = hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '0x$hash';
  }

  Future<double> estimateFee(String chainId, String from, String to, double amount) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    switch (normalized) {
      case 'eth':
        return 0.0021;
      case 'bsc':
        return 0.0005;
      case 'btc':
        return 0.00015;
      case 'trx':
        return 2.5;
      case 'sol':
        return 0.000005;
      default:
        throw RpcException('Unsupported chain: $chainId');
    }
  }

  Future<Map<String, double>> getGasEstimate(String chainId) async {
    await _simulateNetworkDelay();

    final normalized = chainId.toLowerCase();
    switch (normalized) {
      case 'eth':
        return {'gasPrice': 25.0, 'gasLimit': 21000};
      case 'bsc':
        return {'gasPrice': 3.0, 'gasLimit': 21000};
      case 'sol':
        return {'gasPrice': 0.000001, 'gasLimit': 200000};
      default:
        return {'gasPrice': 0.0, 'gasLimit': 0};
    }
  }

  Future<void> _simulateNetworkDelay() async {
    final delay = 300 + _random.nextInt(500);
    await Future.delayed(Duration(milliseconds: delay));
  }

  List<TxHistoryItem> _generateTransactionHistory(ChainConfig chain, String address) {
    final now = DateTime.now();
    final txs = <TxHistoryItem>[];

    final senders = [
      '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1',
      '0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B',
      '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
      '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
      '7xKXtg2CW87d97V3H3m1qW8nGzBkR5o6pLoN2j9sM4eX',
      'TF5Bn4cJCT6G3h3nPK7gNBsFvQXk6zMpPb',
    ];

    final recipients = [
      '0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7',
      '0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE',
      '0xBc5ec8D6bB3A8a1D6E3D7E8A9eF3b3A9274E2F1D',
      '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
      'TQzG1vMaVK9xLo5hKZqYKCbH8sNVjFnBw3',
      '8sL2kC4rF7pQ9wD1xN5bV6mJ3zA0yH8gR4tU2nE6kM9',
    ];

    for (var i = 0; i < 8; i++) {
      final isOutgoing = _random.nextBool();
      final amount = _generateRandomAmount(chain);
      final daysAgo = i * 3 + _random.nextInt(2);
      final statusRoll = _random.nextDouble();
      final status = statusRoll > 0.9
          ? 'failed'
          : statusRoll > 0.8
              ? 'pending'
              : 'confirmed';
      final fee = _generateMockFee(chain);

      final hashBytes = List<int>.generate(32, (_) => _random.nextInt(256));
      final hash = '0x${hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

      txs.add(TxHistoryItem(
        hash: hash,
        from: isOutgoing ? address : senders[i % senders.length],
        to: isOutgoing ? recipients[i % recipients.length] : address,
        amount: amount,
        symbol: chain.symbol,
        timestamp: now.subtract(Duration(days: daysAgo, hours: _random.nextInt(24))),
        status: status,
        fee: fee,
      ));
    }

    txs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return txs;
  }

  double _generateRandomAmount(ChainConfig chain) {
    switch (chain.chainId) {
      case 'eth':
        return (0.01 + _random.nextDouble() * 0.5 * 1000).roundToDouble() / 1000;
      case 'bsc':
        return (0.1 + _random.nextDouble() * 5.0 * 100).roundToDouble() / 100;
      case 'btc':
        return (0.001 + _random.nextDouble() * 0.01 * 100000).roundToDouble() / 100000;
      case 'trx':
        return (100 + _random.nextInt(5000)).toDouble();
      case 'sol':
        return (0.1 + _random.nextDouble() * 3.0 * 100).roundToDouble() / 100;
      default:
        return 0.0;
    }
  }

  double _generateMockFee(ChainConfig chain) {
    switch (chain.chainId) {
      case 'eth':
        return 0.0021;
      case 'bsc':
        return 0.0005;
      case 'btc':
        return 0.00015;
      case 'trx':
        return 2.5;
      case 'sol':
        return 0.000005;
      default:
        return 0.0;
    }
  }

  void clearCache() {
    _recentTxCache.clear();
  }
}

class RpcException implements Exception {
  final String message;
  const RpcException(this.message);

  @override
  String toString() => 'RpcException: $message';
}