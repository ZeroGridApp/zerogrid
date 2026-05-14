import 'dart:math';

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
  bool _seeded = false;
  final _random = Random();

  void _ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    seedDemoData();
  }

  void seedDemoData() {
    _transactions.clear();
    final now = DateTime.now().toUtc();

    _transactions.addAll([
      TransactionRecord(
        id: 'tx_001',
        txHash: '0xa3f2b8c1d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2',
        type: 'sent',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'ETH',
        amount: 0.1,
        usdValue: 291.50,
        fromAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toAddress: '0x8Ba1f109551bD432803012645Ac136ddd64DBA72',
        toName: 'Alice',
        fee: 0.0021,
        feeUsd: 6.12,
        memo: 'Payment for design work',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        blockNumber: 19453210,
        confirmations: 2843,
      ),
      TransactionRecord(
        id: 'tx_002',
        txHash: '0xb4c3d9e2f1a0b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4',
        type: 'received',
        status: 'confirmed',
        chainId: 'bsc',
        chainName: 'BSC',
        token: 'USDT',
        amount: 500,
        usdValue: 500.00,
        fromAddress: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Bob',
        fee: 0,
        feeUsd: 0,
        memo: 'Invoice #1188',
        timestamp: now.subtract(const Duration(days: 2, hours: 7)),
        blockNumber: 37289145,
        confirmations: 5621,
      ),
      TransactionRecord(
        id: 'tx_003',
        txHash: 'd8a1f3e5b7c9d2e4f6a8b0c1d3e5f7a9b2c4d6e8f0a1b3c5d7e9f2b4c6d8e0',
        type: 'sent',
        status: 'confirmed',
        chainId: 'btc',
        chainName: 'Bitcoin',
        token: 'BTC',
        amount: 0.05,
        usdValue: 3150.00,
        fromAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        toAddress: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
        toName: 'Charlie',
        fee: 0.00015,
        feeUsd: 9.45,
        memo: 'Lunch split',
        timestamp: now.subtract(const Duration(days: 3, hours: 12)),
        blockNumber: 835219,
        confirmations: 142,
      ),
      TransactionRecord(
        id: 'tx_004',
        txHash: '5KQEHJ1F8zR3yKcPmNvL2wXqB7dT9aU4sG6hJ3mR1pV8nC5xZ2yW4tF7bA9kL3',
        type: 'received',
        status: 'confirmed',
        chainId: 'sol',
        chainName: 'Solana',
        token: 'SOL',
        amount: 10,
        usdValue: 1450.00,
        fromAddress: 'DRpbCBMxVnDK7maPMoGQFix5grYexb3syKkqGraDUqGp',
        toAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        toName: 'Dave',
        fee: 0,
        feeUsd: 0,
        memo: 'NFT purchase refund',
        timestamp: now.subtract(const Duration(days: 4, hours: 1)),
        blockNumber: 245891230,
        confirmations: 3845,
      ),
      TransactionRecord(
        id: 'tx_005',
        txHash: '0xf1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6b7a8f9e0d1c2b3a4f5e6d7c8b9a0',
        type: 'sent',
        status: 'confirmed',
        chainId: 'trx',
        chainName: 'TRON',
        token: 'TRX',
        amount: 2000,
        usdValue: 240.00,
        fromAddress: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
        toAddress: 'TMuA6YqfCeX8EhbfYEg5y7S4DqzSJireY9',
        toName: 'Eve',
        fee: 0.5,
        feeUsd: 0.06,
        memo: 'Project milestone payment',
        timestamp: now.subtract(const Duration(days: 5, hours: 9)),
        blockNumber: 59872341,
        confirmations: 1205,
      ),
      TransactionRecord(
        id: 'tx_006',
        txHash: '0xc1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1',
        type: 'received',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'ETH',
        amount: 0.5,
        usdValue: 1457.50,
        fromAddress: '0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Frank',
        fee: 0,
        feeUsd: 0,
        timestamp: now.subtract(const Duration(days: 6, hours: 16)),
        blockNumber: 19449205,
        confirmations: 3291,
      ),
      TransactionRecord(
        id: 'tx_007',
        txHash: '0xd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
        type: 'sent',
        status: 'pending',
        chainId: 'trx',
        chainName: 'TRON',
        token: 'USDT',
        amount: 100,
        usdValue: 100.00,
        fromAddress: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
        toAddress: 'TYhQCkGqNGh7DHKVgFoG7BqV23RCjVkKAT',
        toName: 'Grace',
        fee: 13.5,
        feeUsd: 1.62,
        memo: 'Dinner reimbursement',
        timestamp: now.subtract(const Duration(hours: 3)),
        blockNumber: null,
        confirmations: 0,
      ),
      TransactionRecord(
        id: 'tx_008',
        txHash: 'a7b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3b5c7d9e1f3a5b7c9d1e3f5a7',
        type: 'received',
        status: 'confirmed',
        chainId: 'btc',
        chainName: 'Bitcoin',
        token: 'BTC',
        amount: 0.02,
        usdValue: 1260.00,
        fromAddress: '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy',
        toAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        toName: 'Henry',
        fee: 0,
        feeUsd: 0,
        timestamp: now.subtract(const Duration(days: 7, hours: 22)),
        blockNumber: 834892,
        confirmations: 218,
      ),
      TransactionRecord(
        id: 'tx_009',
        txHash: '0xe7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7',
        type: 'swap',
        status: 'confirmed',
        chainId: 'bsc',
        chainName: 'BSC',
        token: 'BNB',
        amount: 1.0,
        usdValue: 585.00,
        fromAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toAddress: '0x10ED43C718714eb63d5aA57B78B54704E256024E',
        toName: 'PancakeSwap',
        fee: 0.0008,
        feeUsd: 0.47,
        memo: 'Swap BNB to USDT',
        timestamp: now.subtract(const Duration(days: 8, hours: 5)),
        blockNumber: 37281023,
        confirmations: 7234,
      ),
      TransactionRecord(
        id: 'tx_010',
        txHash: '3mR8pK2xZ7vN5cL1wT9bQ4sG6hJ8mR3pK1xZ5vN7cL2wT9bQ4sG6hJ8mR3pK1x',
        type: 'sent',
        status: 'failed',
        chainId: 'sol',
        chainName: 'Solana',
        token: 'SOL',
        amount: 50,
        usdValue: 7250.00,
        fromAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        toAddress: '9WzDXwBxKkzLSzEEzKjhzHHXQjZdoGzEiDzRNrMq8VAL',
        toName: 'Ivy',
        fee: 0.000005,
        feeUsd: 0.000725,
        memo: 'Rent payment',
        timestamp: now.subtract(const Duration(days: 9, hours: 14)),
        blockNumber: null,
        confirmations: 0,
      ),
      TransactionRecord(
        id: 'tx_011',
        txHash: '0xa8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8',
        type: 'received',
        status: 'confirmed',
        chainId: 'trx',
        chainName: 'TRON',
        token: 'TRX',
        amount: 3000,
        usdValue: 360.00,
        fromAddress: 'TLa2f6VPqDgRE67v1736q7bJ8Ray5wJm7E',
        toAddress: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
        toName: 'Jack',
        fee: 0,
        feeUsd: 0,
        timestamp: now.subtract(const Duration(days: 10, hours: 3)),
        blockNumber: 59865432,
        confirmations: 1380,
      ),
      TransactionRecord(
        id: 'tx_012',
        txHash: '0xf0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0',
        type: 'bridge',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'USDT',
        amount: 200,
        usdValue: 200.00,
        fromAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toAddress: '0x3a23F943181408EAC424116Af7b7790c94Cb97a5',
        toName: 'ETH→BSC Bridge',
        fee: 0.0035,
        feeUsd: 10.20,
        memo: 'Cross-chain transfer to BSC',
        timestamp: now.subtract(const Duration(days: 12, hours: 8)),
        blockNumber: 19443018,
        confirmations: 7892,
      ),
      TransactionRecord(
        id: 'tx_013',
        txHash: '0xb1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1',
        type: 'sent',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'ETH',
        amount: 0.3,
        usdValue: 874.50,
        fromAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toAddress: '0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B',
        toName: 'Kate',
        fee: 0.0028,
        feeUsd: 8.16,
        memo: 'Freelance invoice #42',
        timestamp: now.subtract(const Duration(days: 14, hours: 2)),
        blockNumber: 19437015,
        confirmations: 9567,
      ),
      TransactionRecord(
        id: 'tx_014',
        txHash: '0xc3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
        type: 'received',
        status: 'confirmed',
        chainId: 'bsc',
        chainName: 'BSC',
        token: 'BNB',
        amount: 1.5,
        usdValue: 877.50,
        fromAddress: '0x8894E0a0c962CB723c1976a4421c95949bE2D4E3',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Leo',
        fee: 0,
        feeUsd: 0,
        timestamp: now.subtract(const Duration(days: 16, hours: 11)),
        blockNumber: 37262189,
        confirmations: 11028,
      ),
      TransactionRecord(
        id: 'tx_015',
        txHash: '4pK2xZ7vN5cL1wT9bQ4sG6hJ8mR3pK1xZ5vN7cL2wT9bQ4sG6hJ8mR3pK1xZ5v',
        type: 'sent',
        status: 'pending',
        chainId: 'sol',
        chainName: 'Solana',
        token: 'SOL',
        amount: 15,
        usdValue: 2175.00,
        fromAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        toAddress: 'H4qUjGNuYDyWmBDfVJkLWQzVNZHq8QqJxDaHVHpMTM6',
        toName: 'Unknown',
        fee: 0.000005,
        feeUsd: 0.000725,
        memo: 'Gaming tournament entry',
        timestamp: now.subtract(const Duration(hours: 1)),
        blockNumber: null,
        confirmations: 2,
      ),
      TransactionRecord(
        id: 'tx_016',
        txHash: '0xd5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5',
        type: 'received',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'ETH',
        amount: 0.15,
        usdValue: 437.25,
        fromAddress: '0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Mia',
        fee: 0,
        feeUsd: 0,
        memo: 'Refund for overpayment',
        timestamp: now.subtract(const Duration(days: 18, hours: 6)),
        blockNumber: 19429103,
        confirmations: 12400,
      ),
      TransactionRecord(
        id: 'tx_017',
        txHash: 'b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3b5c7d9e1f3a5b7c9d1e3f5a7b9',
        type: 'sent',
        status: 'confirmed',
        chainId: 'btc',
        chainName: 'Bitcoin',
        token: 'BTC',
        amount: 0.01,
        usdValue: 630.00,
        fromAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        toAddress: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        toName: 'Unknown',
        fee: 0.00012,
        feeUsd: 7.56,
        timestamp: now.subtract(const Duration(days: 20, hours: 17)),
        blockNumber: 834523,
        confirmations: 357,
      ),
      TransactionRecord(
        id: 'tx_018',
        txHash: '2xZ7vN5cL1wT9bQ4sG6hJ8mR3pK1xZ5vN7cL2wT9bQ4sG6hJ8mR3pK1xZ5vN7c',
        type: 'swap',
        status: 'confirmed',
        chainId: 'sol',
        chainName: 'Solana',
        token: 'SOL',
        amount: 5,
        usdValue: 725.00,
        fromAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        toAddress: 'JUP6LkbZbjS1jKKwapdHc6a5xVwRbVXcNVbBqufMYWxt',
        toName: 'Jupiter',
        fee: 0.000005,
        feeUsd: 0.000725,
        memo: 'Swap SOL to USDC',
        timestamp: now.subtract(const Duration(days: 22, hours: 4)),
        blockNumber: 245821409,
        confirmations: 5892,
      ),
      TransactionRecord(
        id: 'tx_019',
        txHash: '0xe8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8',
        type: 'received',
        status: 'confirmed',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'USDT',
        amount: 800,
        usdValue: 800.00,
        fromAddress: '0x28C6c06298d514Db089934071355E5743bf21d60',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Nora',
        fee: 0,
        feeUsd: 0,
        timestamp: now.subtract(const Duration(days: 24, hours: 13)),
        blockNumber: 19418562,
        confirmations: 15437,
      ),
      TransactionRecord(
        id: 'tx_020',
        txHash: '0xf9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9',
        type: 'sent',
        status: 'confirmed',
        chainId: 'trx',
        chainName: 'TRON',
        token: 'TRX',
        amount: 1500,
        usdValue: 180.00,
        fromAddress: 'TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL',
        toAddress: 'TYhQCkGqNGh7DHKVgFoG7BqV23RCjVkKAT',
        toName: 'Oscar',
        fee: 0.4,
        feeUsd: 0.048,
        memo: 'Weekly allowance',
        timestamp: now.subtract(const Duration(days: 25, hours: 20)),
        blockNumber: 59801234,
        confirmations: 2103,
      ),
      TransactionRecord(
        id: 'tx_021',
        txHash: '0xa0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0',
        type: 'received',
        status: 'confirmed',
        chainId: 'bsc',
        chainName: 'BSC',
        token: 'BNB',
        amount: 3.0,
        usdValue: 1755.00,
        fromAddress: '0xF977814e90dA44bFA03b6295A0616a897441aceC',
        toAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toName: 'Penny',
        fee: 0,
        feeUsd: 0,
        memo: 'Birthday gift',
        timestamp: now.subtract(const Duration(days: 27, hours: 8)),
        blockNumber: 37241987,
        confirmations: 14903,
      ),
      TransactionRecord(
        id: 'tx_022',
        txHash: '0xb2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
        type: 'sent',
        status: 'pending',
        chainId: 'eth',
        chainName: 'Ethereum',
        token: 'ETH',
        amount: 0.25,
        usdValue: 728.75,
        fromAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
        toAddress: '0x4e83362442B8d1beC281594cEa3050c8EB01311C',
        toName: 'Quinn',
        fee: 0.0025,
        feeUsd: 7.29,
        memo: 'Subscription renewal',
        timestamp: now.subtract(const Duration(minutes: 45)),
        blockNumber: null,
        confirmations: 1,
      ),
      TransactionRecord(
        id: 'tx_023',
        txHash: '5vN7cL2wT9bQ4sG6hJ8mR3pK1xZ5vN7cL2wT9bQ4sG6hJ8mR3pK1xZ5vN7cL2',
        type: 'bridge',
        status: 'confirmed',
        chainId: 'sol',
        chainName: 'Solana',
        token: 'SOL',
        amount: 50,
        usdValue: 7250.00,
        fromAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        toAddress: 'worm2ZoG2kUd4vFXhvjh93UUH596ayRfgQ2MgjNMTth',
        toName: 'SOL→ETH Wormhole',
        fee: 0.000005,
        feeUsd: 0.000725,
        memo: 'Cross-chain transfer to Ethereum',
        timestamp: now.subtract(const Duration(days: 29, hours: 15)),
        blockNumber: 245781023,
        confirmations: 10285,
      ),
    ]);
  }

  List<TransactionRecord> getAllTransactions() {
    _ensureSeeded();
    final sorted = List<TransactionRecord>.from(_transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  List<TransactionRecord> getSentTransactions() {
    _ensureSeeded();
    return _transactions
        .where((t) => t.type == 'sent')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionRecord> getReceivedTransactions() {
    _ensureSeeded();
    return _transactions
        .where((t) => t.type == 'received')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionRecord> getTransactionsByChain(String chainId) {
    _ensureSeeded();
    return _transactions
        .where((t) => t.chainId == chainId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  TransactionRecord? getTransactionById(String id) {
    _ensureSeeded();
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TransactionRecord> searchTransactions(String query) {
    _ensureSeeded();
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
    _ensureSeeded();
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

    String mostUsedChain = 'eth';
    int maxChain = 0;
    chainCount.forEach((chain, count) {
      if (count > maxChain) {
        maxChain = count;
        mostUsedChain = chain;
      }
    });

    String mostUsedToken = 'ETH';
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