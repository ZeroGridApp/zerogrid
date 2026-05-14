import 'dart:math';

class WalletService {
  static const chains = ['BTC', 'ETH', 'BSC', 'TRX', 'SOL'];
  static const tokens = ['USDC', 'USDT'];

  List<ChainWallet> deriveAllWallets() {
    return chains.map((chain) => ChainWallet.generate(chain)).toList();
  }
}

class ChainWallet {
  final String chain;
  final String address;
  final String derivationPath;
  double balance;

  ChainWallet({
    required this.chain,
    required this.address,
    required this.derivationPath,
    this.balance = 0.0,
  });

  factory ChainWallet.generate(String chain) {
    final path = _bip44Path(chain);
    return ChainWallet(
      chain: chain,
      address: _generateAddress(chain),
      derivationPath: path,
    );
  }

  static String _bip44Path(String chain) {
    switch (chain) {
      case 'BTC':
        return "m/44'/0'/0'/0/0";
      case 'ETH':
        return "m/44'/60'/0'/0/0";
      case 'BSC':
        return "m/44'/60'/0'/0/0";
      case 'TRX':
        return "m/44'/195'/0'/0/0";
      case 'SOL':
        return "m/44'/501'/0'/0'";
      default:
        return "m/44'/0'/0'/0/0";
    }
  }

  static String _generateAddress(String chain) {
    final rand = Random.secure();
    final chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final len = chain == 'BTC' ? 34 : chain == 'TRX' ? 34 : 42;

    String prefix;
    switch (chain) {
      case 'BTC':
        prefix = '1';
        break;
      case 'ETH':
      case 'BSC':
        prefix = '0x';
        break;
      case 'TRX':
        prefix = 'T';
        break;
      case 'SOL':
        prefix = '';
        break;
      default:
        prefix = '';
    }

    final body = String.fromCharCodes(
      List.generate(len - prefix.length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );

    return '$prefix$body';
  }
}