import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:zero/services/crypto/zero_crypto.dart';
import 'package:zero/services/wallet/rpc_service.dart';

class PayCommand {
  final String action;
  final String? chainId;
  final String? token;
  final double amount;
  final String? toAddress;
  final String? toIdentity;
  final String? memo;

  const PayCommand({
    required this.action,
    this.chainId,
    this.token,
    required this.amount,
    this.toAddress,
    this.toIdentity,
    this.memo,
  });

  @override
  String toString() =>
      'PayCommand(action:$action, chainId:$chainId, token:$token, amount:$amount, toAddress:$toAddress, toIdentity:$toIdentity, memo:$memo)';
}

class PaymentValidation {
  final bool isValid;
  final String? errorMessage;
  final bool balanceSufficient;
  final double estimatedFee;
  final double estimatedTotal;

  const PaymentValidation({
    required this.isValid,
    this.errorMessage,
    required this.balanceSufficient,
    required this.estimatedFee,
    required this.estimatedTotal,
  });
}

class PaymentResult {
  final bool success;
  final String? txHash;
  final String? errorMessage;
  final DateTime timestamp;

  const PaymentResult({
    required this.success,
    this.txHash,
    this.errorMessage,
    required this.timestamp,
  });
}

class ZeroPayService {
  static final ZeroPayService _instance = ZeroPayService._();
  factory ZeroPayService() => _instance;
  ZeroPayService._();

  final _rpc = RpcService();
  final _crypto = ZeroCrypto();
  final _random = Random();

  static const _nativeTokens = {'eth', 'bsc', 'bnb', 'btc', 'trx', 'sol', 'matic', 'avax', 'dot', 'atom'};

  static const _chainBySymbol = {
    'eth': 'eth',
    'bsc': 'bsc',
    'bnb': 'bsc',
    'btc': 'btc',
    'trx': 'trx',
    'sol': 'sol',
  };

  PayCommand? parsePayCommand(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final lowered = trimmed.toLowerCase();
    String action;
    int bodyStart;

    if (lowered.startsWith('/pay ')) {
      action = 'pay';
      bodyStart = 5;
    } else if (lowered.startsWith('/request ')) {
      action = 'request';
      bodyStart = 9;
    } else {
      return null;
    }

    final body = trimmed.substring(bodyStart).trim();
    if (body.isEmpty) return null;

    final parts = _tokenizePayBody(body);
    if (parts.isEmpty) return null;

    final parsed = _parseParts(action, parts);
    if (parsed == null || parsed.amount <= 0) return null;

    return parsed;
  }

  Future<PaymentValidation> validatePayment(PayCommand command, String fromAddress) async {
    try {
      final normalizedToken = (command.token ?? '').toLowerCase();

      if (command.toAddress != null) {
        final chain = command.chainId ?? _chainBySymbol[normalizedToken];
        if (chain != null) {
          final addressError = _validateAddress(chain, command.toAddress!);
          if (addressError != null) {
            return PaymentValidation(
              isValid: false,
              errorMessage: addressError,
              balanceSufficient: false,
              estimatedFee: 0,
              estimatedTotal: 0,
            );
          }
        }
      }

      if (command.toAddress == null && command.toIdentity == null) {
        return PaymentValidation(
          isValid: false,
          errorMessage: 'Requires a recipient address or Zero identity',
          balanceSufficient: false,
          estimatedFee: 0,
          estimatedTotal: 0,
        );
      }

      final chain = command.chainId ?? _inferChain(command) ?? 'eth';
      final token = command.token ?? chain;

      double balance;
      if (_isNativeToken(token, chain)) {
        balance = await _rpc.getBalance(chain, fromAddress);
      } else {
        balance = await _rpc.getTokenBalance(chain, token, fromAddress);
      }

      final fee = await _rpc.estimateFee(chain, fromAddress, command.toAddress ?? fromAddress, command.amount);
      final total = command.action == 'pay' ? command.amount + fee : command.amount;

      final isNative = _isNativeToken(token, chain);
      final balanceSufficient = isNative ? balance >= total : balance >= command.amount;

      if (!balanceSufficient && command.action == 'pay') {
        return PaymentValidation(
          isValid: false,
          errorMessage: isNative
              ? 'Insufficient balance: have ${balance.toStringAsFixed(6)} $token, need ${total.toStringAsFixed(6)} $token (including ${fee.toStringAsFixed(6)} fee)'
              : 'Insufficient $token balance: have ${balance.toStringAsFixed(2)}, need ${command.amount.toStringAsFixed(2)}',
          balanceSufficient: false,
          estimatedFee: fee,
          estimatedTotal: total,
        );
      }

      return PaymentValidation(
        isValid: true,
        balanceSufficient: balanceSufficient,
        estimatedFee: fee,
        estimatedTotal: total,
      );
    } on RpcException catch (e) {
      return PaymentValidation(
        isValid: false,
        errorMessage: 'Network error: ${e.message}',
        balanceSufficient: false,
        estimatedFee: 0,
        estimatedTotal: 0,
      );
    } catch (e) {
      return PaymentValidation(
        isValid: false,
        errorMessage: 'Validation error: $e',
        balanceSufficient: false,
        estimatedFee: 0,
        estimatedTotal: 0,
      );
    }
  }

  Future<PaymentResult> executePayment(PayCommand command) async {
    final now = DateTime.now();
    try {
      if (command.toAddress == null && command.toIdentity == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'No recipient specified',
          timestamp: now,
        );
      }

      final chain = command.chainId ?? _inferChain(command) ?? 'eth';
      final normalizedToken = (command.token ?? '').toLowerCase();

      final fromAddress = '0x${_randomHex(40)}';
      final toAddress = command.toAddress ?? '0x${_randomHex(40)}';

      double balance;
      final isNative = _isNativeToken(normalizedToken, chain);
      if (isNative) {
        balance = await _rpc.getBalance(chain, fromAddress);
      } else {
        balance = await _rpc.getTokenBalance(chain, normalizedToken, fromAddress);
      }

      final fee = await _rpc.estimateFee(chain, fromAddress, toAddress, command.amount);
      final total = command.amount + fee;

      if (isNative && balance < total) {
        return PaymentResult(
          success: false,
          errorMessage: 'Insufficient balance for transaction',
          timestamp: now,
        );
      }

      if (!isNative && balance < command.amount) {
        return PaymentResult(
          success: false,
          errorMessage: 'Insufficient $normalizedToken balance',
          timestamp: now,
        );
      }

      final txPayload = '$fromAddress:$toAddress:${command.amount}:${now.millisecondsSinceEpoch}:${_randomHex(8)}';
      final txHash = _crypto.sha256Hex(Uint8List.fromList(utf8.encode(txPayload)));

      final signedTx = '0x${_randomHex(128)}';
      try {
        await _rpc.broadcastTransaction(chain, signedTx);
      } on RpcException catch (e) {
        return PaymentResult(
          success: false,
          errorMessage: 'Broadcast failed: ${e.message}',
          timestamp: now,
        );
      }

      if (_random.nextDouble() > 0.95) {
        return PaymentResult(
          success: false,
          errorMessage: 'Transaction reverted during execution',
          timestamp: now,
        );
      }

      return PaymentResult(
        success: true,
        txHash: txHash,
        timestamp: now,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Payment execution error: $e',
        timestamp: now,
      );
    }
  }

  String formatAmount(double amount, String symbol) {
    final upperSymbol = symbol.toUpperCase();

    if (amount >= 1.0) {
      return '$amount $upperSymbol';
    }
    if (amount >= 0.001) {
      return '${amount.toStringAsFixed(4)} $upperSymbol';
    }
    return '${amount.toStringAsFixed(8)} $upperSymbol';
  }

  String? _validateAddress(String chainId, String address) {
    final chain = chainId.toLowerCase();

    switch (chain) {
      case 'eth':
      case 'bsc':
        if (address.length != 42 || !address.startsWith('0x')) {
          return 'Invalid $chainId address: must be 42 chars starting with 0x';
        }
        final hexPart = address.substring(2);
        if (RegExp(r'^[0-9a-fA-F]{40}$').stringMatch(hexPart) == null) {
          return 'Invalid $chainId address: contains non-hex characters';
        }
        return null;

      case 'btc':
        if (address.startsWith('1') || address.startsWith('3')) {
          if (address.length < 26 || address.length > 35) {
            return 'Invalid BTC address: legacy address length must be 26-35 chars';
          }
          return null;
        }
        if (address.startsWith('bc1')) {
          if (address.length < 42 || address.length > 62) {
            return 'Invalid BTC address: bech32 length must be 42-62 chars';
          }
          return null;
        }
        return 'Invalid BTC address: must start with 1, 3, or bc1';

      case 'trx':
        if (address.length != 34 || !address.startsWith('T')) {
          return 'Invalid TRX address: must be 34 chars starting with T';
        }
        return null;

      case 'sol':
        if (address.length < 32 || address.length > 44) {
          return 'Invalid SOL address: must be 32-44 chars';
        }
        final solRegex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
        if (solRegex.stringMatch(address) == null) {
          return 'Invalid SOL address: not valid base58';
        }
        return null;

      default:
        return 'Unknown chain: $chainId';
    }
  }

  String? _inferChain(PayCommand command) {
    if (command.chainId != null) return command.chainId;

    final token = (command.token ?? '').toLowerCase();
    return _chainBySymbol[token];
  }

  bool _isNativeToken(String token, String chain) {
    final nativeForChain = _chainBySymbol.entries
        .where((e) => e.value == chain)
        .map((e) => e.key)
        .toSet();
    return token == chain || nativeForChain.contains(token);
  }

  List<String> _tokenizePayBody(String body) {
    final tokens = <String>[];
    final regex = RegExp(r'@[^\s]+|\S+');
    for (final match in regex.allMatches(body)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  PayCommand? _parseParts(String action, List<String> parts) {
    if (parts.isEmpty) return null;

    double? amount;
    String? token;
    String? toAddress;
    String? toIdentity;
    String? chainId;
    String? memo;

    final amountRegex = RegExp(r'^(\d+\.?\d*)$');

    var i = 0;
    while (i < parts.length) {
      final part = parts[i];

      if (amountRegex.hasMatch(part) && amount == null) {
        amount = double.tryParse(part);
        i++;
        continue;
      }

      if (amount != null && token == null) {
        token = part;
        i++;
        continue;
      }

      if (part.toLowerCase() == 'to' && i + 1 < parts.length) {
        i++;
        final next = parts[i];
        if (next.startsWith('@')) {
          toIdentity = next.substring(1);
        } else {
          toAddress = next;
        }
        i++;
        continue;
      }

      if (part.startsWith('@') && toIdentity == null) {
        toIdentity = part.substring(1);
        i++;
        continue;
      }

      if (_isLikelyAddress(part) && toAddress == null) {
        toAddress = part;
        i++;
        continue;
      }

      if (part.startsWith('memo:') || part.startsWith('note:')) {
        memo = part.substring(part.indexOf(':') + 1);
        i++;
        continue;
      }

      i++;
    }

    if (amount == null) return null;

    if (token != null && _chainBySymbol.containsKey(token.toLowerCase())) {
      chainId = _chainBySymbol[token.toLowerCase()];
    }

    return PayCommand(
      action: action,
      chainId: chainId,
      token: token,
      amount: amount,
      toAddress: toAddress,
      toIdentity: toIdentity,
      memo: memo,
    );
  }

  bool _isLikelyAddress(String s) {
    if (s.length < 26 || s.length > 62) return false;
    if (s.startsWith('0x') && s.length == 42) return true;
    if (s.startsWith('T') && s.length == 34) return true;
    if (s.startsWith('1') || s.startsWith('3')) return true;
    if (s.startsWith('bc1')) return true;
    return false;
  }

  String _randomHex(int length) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}