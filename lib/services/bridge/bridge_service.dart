import 'dart:math';
import 'package:flutter/material.dart';

class BridgeChain {
  final String id;
  final String name;
  final String symbol;
  final String icon;
  final Color color;
  final bool isZeroChain;

  const BridgeChain({
    required this.id,
    required this.name,
    required this.symbol,
    required this.icon,
    required this.color,
    this.isZeroChain = false,
  });
}

class BridgeAsset {
  final String id;
  final String symbol;
  final String name;
  final String icon;
  final double balance;
  final double usdValue;
  final String chainId;

  const BridgeAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.icon,
    required this.balance,
    required this.usdValue,
    required this.chainId,
  });
}

class BridgeTransaction {
  final String id;
  final String type;
  final String fromChain;
  final String toChain;
  final String asset;
  final double amount;
  final String status;
  final String txHash;
  final DateTime timestamp;
  final double fee;

  const BridgeTransaction({
    required this.id,
    required this.type,
    required this.fromChain,
    required this.toChain,
    required this.asset,
    required this.amount,
    required this.status,
    required this.txHash,
    required this.timestamp,
    required this.fee,
  });
}

class ZeroBridgeService {
  static final ZeroBridgeService _instance = ZeroBridgeService._();
  factory ZeroBridgeService() => _instance;
  ZeroBridgeService._();

  final _random = Random();
  final List<BridgeChain> _chains = [];
  final List<BridgeAsset> _assets = [];
  final List<BridgeTransaction> _transactions = [];
  bool _seeded = false;

  List<BridgeChain> getSupportedChains() {
    return List.unmodifiable(_chains);
  }

  List<BridgeAsset> getAssets(String chainId) {
    return _assets.where((a) => a.chainId == chainId).toList();
  }

  List<BridgeTransaction> getRecentTransactions() {
    final sorted = List<BridgeTransaction>.from(_transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  BridgeTransaction simulateBridge(
    String fromChainId,
    String toChainId,
    String assetId,
    double amount,
  ) {
    final fromChain = _chains.firstWhere((c) => c.id == fromChainId);
    final toChain = _chains.firstWhere((c) => c.id == toChainId);
    final asset = _assets.firstWhere((a) => a.id == assetId);
    final fee = getBridgeFee(fromChainId, toChainId, asset.usdValue * amount);

    final isFromZero = fromChain.isZeroChain;
    final txType = isFromZero ? 'burn' : 'lock';

    final tx = BridgeTransaction(
      id: 'bridge_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      type: txType,
      fromChain: fromChain.symbol,
      toChain: toChain.symbol,
      asset: asset.symbol,
      amount: amount,
      status: 'pending',
      txHash: '0x${_randomHex(64)}',
      timestamp: DateTime.now(),
      fee: fee,
    );

    _transactions.insert(0, tx);
    return tx;
  }

  double getBridgeFee(String fromChainId, String toChainId, double amountUsd) {
    final baseRate = 0.001 + _random.nextDouble() * 0.004;
    return (amountUsd * baseRate * 100).ceil() / 100;
  }

  BridgeTransaction? confirmTransaction(String txId) {
    final index = _transactions.indexWhere((t) => t.id == txId);
    if (index == -1) return null;

    final oldTx = _transactions[index];
    final newStatus = oldTx.status == 'pending' ? 'confirming' : 'completed';
    final updated = BridgeTransaction(
      id: oldTx.id,
      type: oldTx.type,
      fromChain: oldTx.fromChain,
      toChain: oldTx.toChain,
      asset: oldTx.asset,
      amount: oldTx.amount,
      status: newStatus,
      txHash: oldTx.txHash,
      timestamp: oldTx.timestamp,
      fee: oldTx.fee,
    );
    _transactions[index] = updated;
    return updated;
  }

  double get totalBridgedValue {
    return _transactions
        .where((t) => t.status == 'completed')
        .fold(0.0, (sum, t) => sum + t.amount * (t.fee > 0 ? t.fee / 0.003 : 3200));
  }

  String _randomHex(int length) {
    const chars = '0123456789abcdef';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  void seedBridgeData() {
    if (_seeded) return;
    _seeded = true;

    const ethColor = Color(0xFF627EEA);
    const bscColor = Color(0xFFF0B90B);
    const solColor = Color(0xFF9945FF);
    const trxColor = Color(0xFFFF0013);
    const zeroColor = Color(0xFF6BAF7B);

    _chains.addAll([
      const BridgeChain(id: 'eth', name: 'Ethereum', symbol: 'ETH', icon: '🔷', color: ethColor),
      const BridgeChain(id: 'bsc', name: 'BNB Chain', symbol: 'BSC', icon: '🟡', color: bscColor),
      const BridgeChain(id: 'sol', name: 'Solana', symbol: 'SOL', icon: '🟣', color: solColor),
      const BridgeChain(id: 'trx', name: 'TRON', symbol: 'TRX', icon: '🔴', color: trxColor),
      const BridgeChain(id: 'zero', name: 'ZeroChain', symbol: 'ZERO', icon: '⚪', color: zeroColor, isZeroChain: true),
    ]);

    _assets.addAll([
      const BridgeAsset(id: 'eth_eth', symbol: 'ETH', name: 'Ethereum', icon: '🔷', balance: 1.25, usdValue: 3200, chainId: 'eth'),
      const BridgeAsset(id: 'eth_usdt', symbol: 'USDT', name: 'Tether USD', icon: '💵', balance: 5000, usdValue: 1, chainId: 'eth'),
      const BridgeAsset(id: 'bsc_bnb', symbol: 'BNB', name: 'BNB', icon: '🟡', balance: 2.5, usdValue: 320, chainId: 'bsc'),
      const BridgeAsset(id: 'bsc_busd', symbol: 'BUSD', name: 'Binance USD', icon: '💵', balance: 2000, usdValue: 1, chainId: 'bsc'),
      const BridgeAsset(id: 'sol_sol', symbol: 'SOL', name: 'Solana', icon: '🟣', balance: 2.0, usdValue: 200, chainId: 'sol'),
      const BridgeAsset(id: 'sol_usdc', symbol: 'USDC', name: 'USD Coin', icon: '💵', balance: 1500, usdValue: 1, chainId: 'sol'),
      const BridgeAsset(id: 'trx_trx', symbol: 'TRX', name: 'TRON', icon: '🔴', balance: 1000, usdValue: 0.2, chainId: 'trx'),
      const BridgeAsset(id: 'trx_usdt', symbol: 'USDT', name: 'Tether USD', icon: '💵', balance: 1000, usdValue: 1, chainId: 'trx'),
      const BridgeAsset(id: 'zero_zero', symbol: 'ZERO', name: 'Zero Token', icon: '⚪', balance: 10000, usdValue: 0.5, chainId: 'zero'),
    ]);

    final now = DateTime.now();
    _transactions.addAll([
      BridgeTransaction(
        id: 'bridge_demo_1',
        type: 'lock',
        fromChain: 'ETH',
        toChain: 'BSC',
        asset: 'USDT',
        amount: 500,
        status: 'completed',
        txHash: '0x${_randomHex(64)}',
        timestamp: now.subtract(const Duration(hours: 2)),
        fee: 1.50,
      ),
      BridgeTransaction(
        id: 'bridge_demo_2',
        type: 'burn',
        fromChain: 'ZERO',
        toChain: 'ETH',
        asset: 'ZERO',
        amount: 2000,
        status: 'completed',
        txHash: '0x${_randomHex(64)}',
        timestamp: now.subtract(const Duration(hours: 5)),
        fee: 2.00,
      ),
      BridgeTransaction(
        id: 'bridge_demo_3',
        type: 'lock',
        fromChain: 'SOL',
        toChain: 'ZERO',
        asset: 'USDC',
        amount: 300,
        status: 'confirming',
        txHash: '0x${_randomHex(64)}',
        timestamp: now.subtract(const Duration(minutes: 15)),
        fee: 0.90,
      ),
      BridgeTransaction(
        id: 'bridge_demo_4',
        type: 'lock',
        fromChain: 'ETH',
        toChain: 'TRX',
        asset: 'ETH',
        amount: 0.5,
        status: 'completed',
        txHash: '0x${_randomHex(64)}',
        timestamp: now.subtract(const Duration(days: 1)),
        fee: 4.80,
      ),
      BridgeTransaction(
        id: 'bridge_demo_5',
        type: 'burn',
        fromChain: 'ZERO',
        toChain: 'SOL',
        asset: 'ZERO',
        amount: 5000,
        status: 'pending',
        txHash: '0x${_randomHex(64)}',
        timestamp: now.subtract(const Duration(minutes: 2)),
        fee: 5.00,
      ),
    ]);
  }
}