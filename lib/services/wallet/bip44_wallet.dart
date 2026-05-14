import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:zero/services/crypto/zero_crypto.dart';

class ChainConfig {
  final String chainId;
  final String name;
  final String symbol;
  final int bip44CoinType;
  final String addressPrefix;
  final int decimals;
  final String iconPath;

  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.bip44CoinType,
    required this.addressPrefix,
    required this.decimals,
    required this.iconPath,
  });

  static const btc = ChainConfig(
    chainId: 'BTC',
    name: 'Bitcoin',
    symbol: 'BTC',
    bip44CoinType: 0,
    addressPrefix: '1',
    decimals: 8,
    iconPath: 'assets/images/chains/btc.png',
  );

  static const eth = ChainConfig(
    chainId: 'ETH',
    name: 'Ethereum',
    symbol: 'ETH',
    bip44CoinType: 60,
    addressPrefix: '0x',
    decimals: 18,
    iconPath: 'assets/images/chains/eth.png',
  );

  static const bsc = ChainConfig(
    chainId: 'BSC',
    name: 'BNB Chain',
    symbol: 'BNB',
    bip44CoinType: 60,
    addressPrefix: '0x',
    decimals: 18,
    iconPath: 'assets/images/chains/bsc.png',
  );

  static const trx = ChainConfig(
    chainId: 'TRX',
    name: 'TRON',
    symbol: 'TRX',
    bip44CoinType: 195,
    addressPrefix: 'T',
    decimals: 6,
    iconPath: 'assets/images/chains/trx.png',
  );

  static const sol = ChainConfig(
    chainId: 'SOL',
    name: 'Solana',
    symbol: 'SOL',
    bip44CoinType: 501,
    addressPrefix: '',
    decimals: 9,
    iconPath: 'assets/images/chains/sol.png',
  );

  static const supportedChains = [btc, eth, bsc, trx, sol];

  static ChainConfig fromChainId(String chainId) {
    switch (chainId.toUpperCase()) {
      case 'BTC':
        return btc;
      case 'ETH':
        return eth;
      case 'BSC':
        return bsc;
      case 'TRX':
        return trx;
      case 'SOL':
        return sol;
      default:
        throw ArgumentError('Unsupported chain: $chainId');
    }
  }
}

class WalletAddress {
  final String chainId;
  final String address;
  final String derivationPath;
  final String publicKeyHex;

  const WalletAddress({
    required this.chainId,
    required this.address,
    required this.derivationPath,
    required this.publicKeyHex,
  });

  @override
  String toString() => 'WalletAddress($chainId: $address, path: $derivationPath)';
}

class WalletBalance {
  final String chainId;
  final String symbol;
  final String address;
  final double balance;
  final double balanceUsd;
  final List<TransactionRecord> recentTxs;

  const WalletBalance({
    required this.chainId,
    required this.symbol,
    required this.address,
    required this.balance,
    required this.balanceUsd,
    required this.recentTxs,
  });
}

class TransactionRecord {
  final String hash;
  final String type;
  final double amount;
  final double usdValue;
  final DateTime time;
  final bool incoming;

  const TransactionRecord({
    required this.hash,
    required this.type,
    required this.amount,
    required this.usdValue,
    required this.time,
    required this.incoming,
  });
}

class Bip44Wallet {
  static final Bip44Wallet _instance = Bip44Wallet._();
  factory Bip44Wallet() => _instance;
  Bip44Wallet._();

  final _crypto = ZeroCrypto();
  final _secp256k1 = ECCurve_secp256k1();
  final _random = Random.secure();
  final _base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  Uint8List? _seed;

  void initWithSeed(Uint8List seed) {
    if (seed.length < 64) {
      throw ArgumentError('Seed must be at least 64 bytes, got ${seed.length}');
    }
    _seed = seed;
  }

  void initWithMnemonic(String mnemonic, {String passphrase = ''}) {
    initWithSeed(_crypto.mnemonicToSeed(mnemonic, passphrase: passphrase));
  }

  bool get isInitialized => _seed != null;

  void _ensureInitialized() {
    if (_seed == null) {
      throw StateError('Bip44Wallet not initialized. Call initWithSeed() or initWithMnemonic() first.');
    }
  }

  String _buildDerivationPath(String chainId, int account, int change, int index) {
    final config = ChainConfig.fromChainId(chainId);
    return "m/44'/${config.bip44CoinType}'/$account'/$change/$index";
  }

  WalletAddress deriveAddress(String chainId, {int account = 0, int change = 0, int index = 0}) {
    _ensureInitialized();
    final path = _buildDerivationPath(chainId, account, change, index);

    switch (chainId.toUpperCase()) {
      case 'BTC':
        return _deriveBitcoinAddress(path, chainId, account, change, index);
      case 'ETH':
      case 'BSC':
      case 'TRX':
        return _deriveSecp256k1Address(path, chainId, account, change, index);
      case 'SOL':
        return _deriveSolanaMockAddress(path, chainId, account, change, index);
      default:
        throw ArgumentError('Unsupported chain: $chainId');
    }
  }

  WalletAddress _deriveSecp256k1Address(
    String path,
    String chainId,
    int account,
    int change,
    int index,
  ) {
    final privateKeyBytes = _deriveChildKey(chainId, account, change, index);
    final (publicKeyHex, uncompressedPubKey) = _computeSecp256k1PublicKey(privateKeyBytes);

    final keccak = KeccakDigest(256);
    final pubKeyHash = keccak.process(uncompressedPubKey);
    final addressBytes = pubKeyHash.sublist(pubKeyHash.length - 20, pubKeyHash.length);

    final hexAddress = _bytesToHex(addressBytes);

    final address = chainId == 'TRX'
        ? _buildTronAddress(hexAddress)
        : _applyEip55Checksum(hexAddress);

    final prefixedAddress = chainId == 'TRX' ? address : '0x$address';

    return WalletAddress(
      chainId: chainId,
      address: prefixedAddress,
      derivationPath: path,
      publicKeyHex: publicKeyHex,
    );
  }

  String _applyEip55Checksum(String lowerHex) {
    final keccak = KeccakDigest(256);
    final hashBytes = keccak.process(utf8.encode(lowerHex));

    final buffer = StringBuffer();
    for (var i = 0; i < lowerHex.length; i++) {
      final char = lowerHex[i];
      final hashByte = hashBytes[i ~/ 2];
      final nibble = (i.isEven) ? (hashByte >> 4) & 0x0F : hashByte & 0x0F;
      buffer.write(nibble >= 8 ? char.toUpperCase() : char);
    }
    return buffer.toString();
  }

  String _buildTronAddress(String hexAddress) {
    const tronPrefix = '41';
    final prefixed = tronPrefix + hexAddress;
    final prefixedBytes = _hexToBytes(prefixed);

    final sha256_1 = _crypto.sha256(prefixedBytes);
    final sha256_2 = _crypto.sha256(sha256_1);
    final checksum = sha256_2.sublist(0, 4);

    final addressWithChecksum = Uint8List.fromList([...prefixedBytes, ...checksum]);
    return _base58Encode(addressWithChecksum);
  }

  WalletAddress _deriveBitcoinAddress(
    String path,
    String chainId,
    int account,
    int change,
    int index,
  ) {
    final privateKeyBytes = _deriveChildKey(chainId, account, change, index);
    final (publicKeyHex, uncompressedPubKey) = _computeSecp256k1PublicKey(privateKeyBytes);

    final sha256Hash = _crypto.sha256(uncompressedPubKey);
    final ripemd160 = RIPEMD160Digest();
    final pubKeyHash = ripemd160.process(sha256Hash);

    final payload = Uint8List.fromList([0x00, ...pubKeyHash]);

    final checksum1 = _crypto.sha256(payload);
    final checksum2 = _crypto.sha256(checksum1);
    final checksum = checksum2.sublist(0, 4);

    final addressBytes = Uint8List.fromList([...payload, ...checksum]);
    final address = _base58Encode(addressBytes);

    return WalletAddress(
      chainId: chainId,
      address: address,
      derivationPath: path,
      publicKeyHex: publicKeyHex,
    );
  }

  WalletAddress _deriveSolanaMockAddress(
    String path,
    String chainId,
    int account,
    int change,
    int index,
  ) {
    final privateKeyBytes = _deriveChildKey(chainId, account, change, index);
    final publicKeyHex = _bytesToHex(privateKeyBytes).substring(0, 64);

    final addressBytes = _crypto.sha256(Uint8List.fromList([...privateKeyBytes, ...utf8.encode('sol')]));
    final address = _base58Encode(addressBytes.sublist(0, 32));

    return WalletAddress(
      chainId: chainId,
      address: address,
      derivationPath: path,
      publicKeyHex: publicKeyHex,
    );
  }

  (String, Uint8List) _computeSecp256k1PublicKey(Uint8List privateKeyBytes) {
    final d = _bytesToBigInt(privateKeyBytes) % _secp256k1.n!;

    final Q = _secp256k1.G! * d;
    if (Q == null || Q.isInfinity) {
      throw StateError('Failed to compute secp256k1 public key: point at infinity');
    }

    final xCoord = Q.x;
    final yCoord = Q.y;
    if (xCoord == null || yCoord == null) {
      throw StateError('Failed to get coordinates for secp256k1 public key');
    }

    final xBytes = _bigIntToFixedBytes(xCoord.toBigInteger()!, 32);
    final yBytes = _bigIntToFixedBytes(yCoord.toBigInteger()!, 32);

    final publicKeyHex = _bytesToHex(xBytes) + _bytesToHex(yBytes);
    final uncompressedPubKey = Uint8List.fromList([0x04, ...xBytes, ...yBytes]);

    return (publicKeyHex, uncompressedPubKey);
  }

  Uint8List _deriveChildKey(String chainId, int account, int change, int index) {
    final info = utf8.encode('bip44/$chainId/$account/$change/$index');
    final salt = utf8.encode('zero-wallet');
    return _crypto.hkdf(salt, _seed!, info, 32);
  }

  Map<String, WalletAddress> deriveAllAddresses({int account = 0, int change = 0, int index = 0}) {
    _ensureInitialized();
    final result = <String, WalletAddress>{};
    for (final config in ChainConfig.supportedChains) {
      result[config.chainId] = deriveAddress(
        config.chainId,
        account: account,
        change: change,
        index: index,
      );
    }
    return result;
  }

  List<WalletBalance> deriveAllWallets({int account = 0, int change = 0, int index = 0}) {
    _ensureInitialized();
    final addresses = deriveAllAddresses(account: account, change: change, index: index);
    final result = <WalletBalance>[];

    for (final config in ChainConfig.supportedChains) {
      final walletAddr = addresses[config.chainId]!;
      final (balance, balanceUsd) = _mockBalance(config.chainId);
      result.add(WalletBalance(
        chainId: config.chainId,
        symbol: config.symbol,
        address: walletAddr.address,
        balance: balance,
        balanceUsd: balanceUsd,
        recentTxs: _generateMockTransactions(config.chainId, config.symbol),
      ));
    }

    return result;
  }

  (double, double) _mockBalance(String chainId) {
    switch (chainId) {
      case 'BTC':
        return (1.2473, 1.2473 * 68320);
      case 'ETH':
        return (4.821, 4.821 * 3520);
      case 'BSC':
        return (23.65, 23.65 * 618);
      case 'TRX':
        return (15820.0, 15820.0 * 0.12);
      case 'SOL':
        return (42.38, 42.38 * 186);
      default:
        return (0.0, 0.0);
    }
  }

  List<TransactionRecord> _generateMockTransactions(String chainId, String symbol) {
    final baseAmounts = switch (chainId) {
      'BTC' => [0.023, 0.15, 0.008, 0.42, 0.067, 0.0031],
      'ETH' => [0.5, 1.2, 0.08, 2.4, 0.15, 0.03],
      'BSC' => [4.0, 1.8, 12.0, 0.5, 3.2, 8.0],
      'TRX' => [2000.0, 500.0, 8000.0, 320.0, 1500.0, 6000.0],
      'SOL' => [5.0, 1.5, 20.0, 3.0, 8.0, 0.8],
      _ => [0.0],
    };

    final unitPrice = switch (chainId) {
      'BTC' => 68320.0,
      'ETH' => 3520.0,
      'BSC' => 618.0,
      'TRX' => 0.12,
      'SOL' => 186.0,
      _ => 1.0,
    };

    final typesIn = ['Receive', 'Staking Reward', 'Receive'];
    final typesOut = ['Send', 'Swap', 'Stake'];
    final chars = '0123456789abcdef';

    return List.generate(6, (i) {
      final incoming = i.isEven;
      final amount = baseAmounts[i];
      final type = incoming ? typesIn[i % 3] : typesOut[i % 3];
      final usd = amount * unitPrice;

      final prefix = (chainId == 'ETH' || chainId == 'BSC') ? '0x' : '';
      final hashBody = String.fromCharCodes(
        List.generate(64 - prefix.length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
      );

      return TransactionRecord(
        hash: '$prefix$hashBody',
        type: type,
        amount: amount,
        usdValue: usd,
        time: DateTime.now().subtract(Duration(hours: i * 3 + _random.nextInt(120))),
        incoming: incoming,
      );
    });
  }

  String _base58Encode(Uint8List bytes) {
    final zeroCount = bytes.takeWhile((b) => b == 0).length;
    final prefix = '1' * zeroCount;

    var num = BigInt.zero;
    for (final b in bytes) {
      num = (num << 8) | BigInt.from(b);
    }

    final result = StringBuffer();
    final base = BigInt.from(58);
    while (num > BigInt.zero) {
      final rem = (num % base).toInt();
      result.write(_base58Alphabet[rem]);
      num = num ~/ base;
    }

    return prefix + result.toString().split('').reversed.join();
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  Uint8List _bigIntToFixedBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var v = value;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (v & BigInt.from(0xFF)).toInt();
      v = v >> 8;
    }
    return bytes;
  }
}