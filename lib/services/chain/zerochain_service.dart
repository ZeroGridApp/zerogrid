import 'dart:async';
import 'dart:math';

class ZeroBlock {
  final int number;
  final String hash;
  final String previousHash;
  final DateTime timestamp;
  final String validatorId;
  final String validatorName;
  final int txCount;
  final double totalZeroBurned;
  final int size;

  const ZeroBlock({
    required this.number,
    required this.hash,
    required this.previousHash,
    required this.timestamp,
    required this.validatorId,
    required this.validatorName,
    required this.txCount,
    required this.totalZeroBurned,
    required this.size,
  });
}

class ZeroTransaction {
  final String hash;
  final int blockNumber;
  final String from;
  final String to;
  final double amount;
  final double fee;
  final String type;
  final DateTime timestamp;
  final String status;

  const ZeroTransaction({
    required this.hash,
    required this.blockNumber,
    required this.from,
    required this.to,
    required this.amount,
    required this.fee,
    required this.type,
    required this.timestamp,
    required this.status,
  });
}

class ZeroValidator {
  final String id;
  final String name;
  final double stake;
  final int blocksProduced;
  final double uptime;
  final double rewardEarned;
  final bool isActive;

  const ZeroValidator({
    required this.id,
    required this.name,
    required this.stake,
    required this.blocksProduced,
    required this.uptime,
    required this.rewardEarned,
    required this.isActive,
  });

  ZeroValidator copyWith({
    int? blocksProduced,
    double? rewardEarned,
  }) {
    return ZeroValidator(
      id: id,
      name: name,
      stake: stake,
      blocksProduced: blocksProduced ?? this.blocksProduced,
      uptime: uptime,
      rewardEarned: rewardEarned ?? this.rewardEarned,
      isActive: isActive,
    );
  }
}

class ZeroChainService {
  static final ZeroChainService _instance = ZeroChainService._();
  factory ZeroChainService() => _instance;
  ZeroChainService._();

  final _random = Random();
  final List<ZeroBlock> _blocks = [];
  final List<ZeroTransaction> _transactions = [];
  final List<ZeroValidator> _validators = [];
  Timer? _blockTimer;
  bool _isRunning = false;
  bool _seeded = false;

  static const _txTypes = ['transfer', 'stake', 'burn', 'domain', 'dns'];
  static const _zidPrefixes = ['zid:zero:alice', 'zid:zero:bob', 'zid:zero:charlie', 'zid:zero:dave', 'zid:zero:eve'];
  static const _addressPrefixes = ['0xZ'];

  static const _validatorDefs = [
    {'id': 'v_alpha', 'name': 'Alpha', 'stakePct': 0.07},
    {'id': 'v_beta', 'name': 'Beta', 'stakePct': 0.05},
    {'id': 'v_gamma', 'name': 'Gamma', 'stakePct': 0.03},
    {'id': 'v_delta', 'name': 'Delta', 'stakePct': 0.04},
    {'id': 'v_epsilon', 'name': 'Epsilon', 'stakePct': 0.06},
    {'id': 'v_zeta', 'name': 'Zeta', 'stakePct': 0.05},
  ];

  ZeroChainService._internal();

  String _generateHash() {
    const chars = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < 64; i++) {
      sb.write(chars[_random.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  String _generateTxHash() {
    const chars = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < 64; i++) {
      sb.write(chars[_random.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  String _randomZidOrAddress() {
    if (_random.nextBool()) {
      return '${_zidPrefixes[_random.nextInt(_zidPrefixes.length)]}_${_random.nextInt(9999)}';
    }
    final sb = StringBuffer('0xZ');
    const chars = '0123456789abcdef';
    for (var i = 0; i < 40; i++) {
      sb.write(chars[_random.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  ZeroValidator _pickValidator() {
    final active = _validators.where((v) => v.isActive).toList();
    final totalStake = active.fold<double>(0, (sum, v) => sum + v.stake);
    var r = _random.nextDouble() * totalStake;
    for (final v in active) {
      r -= v.stake;
      if (r <= 0) return v;
    }
    return active.last;
  }

  void _initValidators() {
    final totalStake = 1000000.0;
    for (final def in _validatorDefs) {
      _validators.add(ZeroValidator(
        id: def['id'] as String,
        name: def['name'] as String,
        stake: totalStake * (def['stakePct'] as double),
        blocksProduced: 0,
        uptime: 95.0 + _random.nextDouble() * 4.99,
        rewardEarned: 0,
        isActive: true,
      ));
    }
  }

  ZeroTransaction _createRandomTransaction(int blockNumber) {
    final type = _txTypes[_random.nextInt(_txTypes.length)];
    final amount = switch (type) {
      'transfer' || 'dns' => 10.0 + _random.nextDouble() * 990.0,
      'stake' => 100.0 + _random.nextDouble() * 9900.0,
      'burn' => 1.0 + _random.nextDouble() * 99.0,
      'domain' => 50.0 + _random.nextDouble() * 450.0,
      _ => 10.0 + _random.nextDouble() * 100.0,
    };
    final fee = amount * (0.001 + _random.nextDouble() * 0.009);

    return ZeroTransaction(
      hash: _generateTxHash(),
      blockNumber: blockNumber,
      from: _randomZidOrAddress(),
      to: _randomZidOrAddress(),
      amount: double.parse(amount.toStringAsFixed(2)),
      fee: double.parse(fee.toStringAsFixed(4)),
      type: type,
      timestamp: DateTime.now(),
      status: 'confirmed',
    );
  }

  void _produceBlock() {
    final validator = _pickValidator();
    final txCount = 1 + _random.nextInt(3);
    final totalBurned = (0.01 + _random.nextDouble() * 0.49) * txCount;
    final previousHash = _blocks.isNotEmpty ? _blocks.last.hash : '0' * 64;

    final block = ZeroBlock(
      number: _blocks.length,
      hash: _generateHash(),
      previousHash: previousHash,
      timestamp: DateTime.now(),
      validatorId: validator.id,
      validatorName: validator.name,
      txCount: txCount,
      totalZeroBurned: double.parse(totalBurned.toStringAsFixed(4)),
      size: 2048 + _random.nextInt(8192),
    );

    _blocks.add(block);

    for (var i = 0; i < txCount; i++) {
      _transactions.insert(0, _createRandomTransaction(block.number));
    }

    final vIndex = _validators.indexWhere((v) => v.id == validator.id);
    if (vIndex != -1) {
      final v = _validators[vIndex];
      final reward = 0.5 + _random.nextDouble() * 1.5;
      _validators[vIndex] = v.copyWith(
        blocksProduced: v.blocksProduced + 1,
        rewardEarned: v.rewardEarned + double.parse(reward.toStringAsFixed(2)),
      );
    }
  }

  void start() {
    if (_isRunning) return;
    if (!_seeded) {
      seedGenesis();
    }
    _isRunning = true;
    _blockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _produceBlock();
    });
  }

  void stop() {
    _blockTimer?.cancel();
    _blockTimer = null;
    _isRunning = false;
  }

  bool get isRunning => _isRunning;

  List<ZeroBlock> getLatestBlocks(int n) {
    final count = n.clamp(1, _blocks.length);
    return _blocks.sublist(_blocks.length - count).reversed.toList();
  }

  List<ZeroTransaction> getLatestTransactions(int n) {
    final count = n.clamp(1, _transactions.length);
    return _transactions.sublist(0, count);
  }

  List<ZeroValidator> getValidators() {
    return List.unmodifiable(_validators);
  }

  Map<String, dynamic> getChainStats() {
    final totalBlocks = _blocks.length;
    final totalTxs = _transactions.length;
    final totalBurned = _blocks.fold<double>(0, (sum, b) => sum + b.totalZeroBurned);
    final avgBlockTime = 3.0;
    final tps = _transactions.length / ((_blocks.last.timestamp.difference(_blocks.first.timestamp).inSeconds).clamp(1, 999999));

    return {
      'totalBlocks': totalBlocks,
      'totalTxs': totalTxs,
      'totalBurned': double.parse(totalBurned.toStringAsFixed(2)),
      'avgBlockTime': avgBlockTime,
      'tps': double.parse(tps.toStringAsFixed(2)),
    };
  }

  ZeroBlock? getBlockByNumber(int number) {
    if (number < 0 || number >= _blocks.length) return null;
    return _blocks[number];
  }

  List<ZeroTransaction> getTransactionsByBlock(int blockNumber) {
    return _transactions.where((tx) => tx.blockNumber == blockNumber).toList();
  }

  void seedGenesis() {
    if (_seeded) return;
    _seeded = true;

    _initValidators();

    final genesis = ZeroBlock(
      number: 0,
      hash: '0000000000000000000000000000000000000000000000000000000000000001',
      previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      timestamp: DateTime.now().subtract(const Duration(minutes: 60)),
      validatorId: 'v_alpha',
      validatorName: 'Alpha',
      txCount: 1,
      totalZeroBurned: 0.0,
      size: 512,
    );
    _blocks.add(genesis);

    _transactions.add(ZeroTransaction(
      hash: '00000000000000000000000000000000000000000000000000000000000000g1',
      blockNumber: 0,
      from: 'zid:zero:genesis',
      to: 'zid:zero:alpha_1000',
      amount: 1000000.0,
      fee: 0.0,
      type: 'transfer',
      timestamp: genesis.timestamp,
      status: 'confirmed',
    ));

    for (var i = 1; i <= 20; i++) {
      final validator = _pickValidator();
      final txCount = 1 + _random.nextInt(3);
      final totalBurned = (0.01 + _random.nextDouble() * 0.49) * txCount;

      final block = ZeroBlock(
        number: i,
        hash: _generateHash(),
        previousHash: _blocks.last.hash,
        timestamp: DateTime.now().subtract(Duration(seconds: (20 - i) * 3)),
        validatorId: validator.id,
        validatorName: validator.name,
        txCount: txCount,
        totalZeroBurned: double.parse(totalBurned.toStringAsFixed(4)),
        size: 2048 + _random.nextInt(8192),
      );
      _blocks.add(block);

      final vIndex = _validators.indexWhere((v) => v.id == validator.id);
      if (vIndex != -1) {
        final v = _validators[vIndex];
        final reward = 0.5 + _random.nextDouble() * 1.5;
        _validators[vIndex] = v.copyWith(
          blocksProduced: v.blocksProduced + 1,
          rewardEarned: v.rewardEarned + double.parse(reward.toStringAsFixed(2)),
        );
      }

      for (var j = 0; j < txCount; j++) {
        _transactions.insert(0, _createRandomTransaction(block.number));
      }
    }
  }
}