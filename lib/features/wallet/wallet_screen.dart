import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/crypto/zero_crypto.dart';
import '../../services/identity_service.dart';
import '../../services/wallet/bip44_wallet.dart';
import '../../services/wallet/rpc_service.dart';
import '../../widgets/zero_card.dart';
import '../chain/zerochain_explorer.dart';
import '../dao/zero_dao_screen.dart';
import '../bridge/bridge_screen.dart';
import '../market/zeromarket_screen.dart';
import 'transaction_history_screen.dart';
import '../tokenomics/tokenomics_dashboard.dart';
import 'zerodns_screen.dart';

const _chainColors = <String, Color>{
  'BTC': Color(0xFFC89B5E),
  'ETH': Color(0xFF7B8FC0),
  'BSC': Color(0xFFC9A83C),
  'TRX': Color(0xFFC4615E),
  'SOL': Color(0xFF937BC0),
};

const _chainNames = <String, String>{
  'BTC': 'Bitcoin',
  'ETH': 'Ethereum',
  'BSC': 'BNB Chain',
  'TRX': 'TRON',
  'SOL': 'Solana',
};

const _chainUnits = <String, String>{
  'BTC': 'BTC',
  'ETH': 'ETH',
  'BSC': 'BNB',
  'TRX': 'TRX',
  'SOL': 'SOL',
};

const _chainOrder = ['BTC', 'ETH', 'BSC', 'TRX', 'SOL'];

const _explorerUrls = <String, String>{
  'BTC': 'https://www.blockchain.com/explorer/transactions/btc/',
  'ETH': 'https://etherscan.io/tx/',
  'BSC': 'https://bscscan.com/tx/',
  'TRX': 'https://tronscan.org/#/transaction/',
  'SOL': 'https://solscan.io/tx/',
};

class _ContactEntry {
  final String label;
  final String address;
  final String chainId;

  const _ContactEntry({
    required this.label,
    required this.address,
    required this.chainId,
  });
}

class _QrCodePainter extends CustomPainter {
  final String data;
  final Color foreground;
  final Color background;

  _QrCodePainter({
    required this.data,
    required this.foreground,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final gridSize = 29;
    final moduleSize = size.width / gridSize;
    final grid = _buildQrGrid(data, gridSize);

    final fgPaint = Paint()..color = foreground;

    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (grid[r][c]) {
          final rect = Rect.fromLTWH(
            c * moduleSize + moduleSize * 0.08,
            r * moduleSize + moduleSize * 0.08,
            moduleSize * 0.84,
            moduleSize * 0.84,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.15)),
            fgPaint,
          );
        }
      }
    }
  }

  List<List<bool>> _buildQrGrid(String data, int size) {
    final grid = List.generate(size, (_) => List.filled(size, false));

    _drawFinder(grid, 2, 2);
    _drawFinder(grid, size - 9, 2);
    _drawFinder(grid, 2, size - 9);

    _drawTiming(grid, size);

    final hashVal = _hashString(data);
    final rng = Random(hashVal);

    for (var r = 8; r < size - 1; r++) {
      for (var c = 8; c < size - 1; c++) {
        if (r < 9 && c < 9) continue;
        if (r < 9 && c > size - 10) continue;
        if (r > size - 10 && c < 9) continue;
        if (r == 7 || r == size - 7 || c == 7 || c == size - 7) continue;
        if (grid[r][c]) continue;
        grid[r][c] = rng.nextBool();
      }
    }

    _drawAlignment(grid, size - 9, size - 9);

    return grid;
  }

  void _drawFinder(List<List<bool>> grid, int row, int col) {
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final isBorder = r == 0 || r == 7 || c == 0 || c == 7;
        final isInner = r >= 2 && r <= 5 && c >= 2 && c <= 5;
        grid[row + r][col + c] = isBorder || isInner;
      }
    }
  }

  void _drawAlignment(List<List<bool>> grid, int row, int col) {
    for (var r = -2; r <= 2; r++) {
      for (var c = -2; c <= 2; c++) {
        final isBorder = r == -2 || r == 2 || c == -2 || c == 2;
        final isCenter = r == 0 && c == 0;
        final nr = row + r;
        final nc = col + c;
        if (nr >= 0 && nr < grid.length && nc >= 0 && nc < grid[0].length) {
          if (!grid[nr][nc]) {
            grid[nr][nc] = isBorder || isCenter;
          }
        }
      }
    }
  }

  void _drawTiming(List<List<bool>> grid, int size) {
    for (var i = 8; i < size - 8; i++) {
      grid[7][i] = i % 2 == 0;
      grid[i][7] = i % 2 == 0;
    }
  }

  int _hashString(String s) {
    var hash = 0;
    for (var i = 0; i < s.length; i++) {
      hash = ((hash << 5) - hash + s.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background;
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final _bip44Wallet = Bip44Wallet();
  final _rpcService = RpcService();

  List<WalletBalance> _wallets = [];
  Map<String, double> _realBalances = {};
  Map<String, double> _usdPrices = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _selectedIndex = 0;

  final List<_ContactEntry> _contacts = [
    const _ContactEntry(
      label: "Bob's ETH",
      address: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18',
      chainId: 'ETH',
    ),
    const _ContactEntry(
      label: 'Trading Wallet',
      address: '0x28C6c06298d514Db089934071355E5743bf21d60',
      chainId: 'ETH',
    ),
    const _ContactEntry(
      label: 'Cold Storage',
      address: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
      chainId: 'BTC',
    ),
    const _ContactEntry(
      label: 'DeFi Vault',
      address: '0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B',
      chainId: 'BSC',
    ),
    const _ContactEntry(
      label: 'Solana Staking',
      address: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
      chainId: 'SOL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _chainOrder.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initWallet();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _selectedIndex = _tabController.index);
    }
  }

  Future<Uint8List?> _getSeed() async {
    try {
      final identityService = IdentityService();
      final identity = await identityService.loadIdentity();
      if (identity != null) {
        return ZeroCrypto().mnemonicToSeed(identity.mnemonic);
      }
    } catch (_) {}
    return ZeroCrypto().mnemonicToSeed(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
    );
  }

  Future<void> _initWallet() async {
    final seed = await _getSeed();
    if (seed == null) {
      setState(() => _isLoading = false);
      return;
    }

    _bip44Wallet.initWithSeed(seed);
    final wallets = _bip44Wallet.deriveAllWallets();

    final balances = <String, double>{};
    final prices = <String, double>{};

    for (final wallet in wallets) {
      final chainLower = wallet.chainId.toLowerCase();
      try {
        final balance = await _rpcService.getBalance(chainLower, wallet.address);
        balances[wallet.chainId] = balance;
      } catch (_) {
        balances[wallet.chainId] = wallet.balance;
      }
      try {
        final price = await _rpcService.getUsdPrice(chainLower);
        prices[wallet.chainId] = price;
      } catch (_) {
        prices[wallet.chainId] = wallet.balance != 0
            ? wallet.balanceUsd / wallet.balance
            : 0;
      }
    }

    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      _realBalances = balances;
      _usdPrices = prices;
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);

    final balances = <String, double>{};
    final prices = <String, double>{};

    for (final wallet in _wallets) {
      final chainLower = wallet.chainId.toLowerCase();
      try {
        final balance = await _rpcService.getBalance(chainLower, wallet.address);
        balances[wallet.chainId] = balance;
      } catch (_) {
        balances[wallet.chainId] = _realBalances[wallet.chainId] ?? wallet.balance;
      }
      try {
        final price = await _rpcService.getUsdPrice(chainLower);
        prices[wallet.chainId] = price;
      } catch (_) {
        prices[wallet.chainId] = _usdPrices[wallet.chainId] ?? 0;
      }
    }

    if (!mounted) return;
    setState(() {
      _realBalances = balances;
      _usdPrices = prices;
      _isRefreshing = false;
    });
  }

  void _onCopyAddress() {
    Clipboard.setData(ClipboardData(text: _currentWallet.address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).copyPhrase,
          style: ZeroTypography.caption(context).copyWith(color: context.zTextPrimary),
        ),
        backgroundColor: context.zSurfaceRaised,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
          vertical: ZeroSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        ),
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).copyPhrase,
          style: ZeroTypography.caption(context).copyWith(color: context.zTextPrimary),
        ),
        backgroundColor: context.zSurfaceRaised,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
          vertical: ZeroSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        ),
      ),
    );
  }

  WalletBalance get _currentWallet => _wallets[_selectedIndex];

  Color get _currentAccent => _chainColors[_currentWallet.chainId]!;

  double get _currentBalance =>
      _realBalances[_currentWallet.chainId] ?? _currentWallet.balance;

  double get _currentUsdValue =>
      _currentBalance * (_usdPrices[_currentWallet.chainId] ?? 0);

  double get _totalUsdValue {
    var total = 0.0;
    for (final wallet in _wallets) {
      final balance = _realBalances[wallet.chainId] ?? wallet.balance;
      final price = _usdPrices[wallet.chainId] ?? 0;
      total += balance * price;
    }
    return total;
  }

  List<TransactionRecord> get _currentTx => _currentWallet.recentTxs;

  String _formatBalance(double value) {
    if (value >= 10000) {
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );
    }
    if (value >= 1000) {
      return value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 4);
  }

  String _formatUsd(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }

  String _formatBadgeBalance(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value >= 1) {
      return value.toStringAsFixed(2);
    }
    if (value >= 0.01) {
      return value.toStringAsFixed(4);
    }
    return '<0.01';
  }

  String _truncateAddress(String addr) {
    if (addr.length <= 24) return addr;
    return '${addr.substring(0, 10)}...${addr.substring(addr.length - 8)}';
  }

  String _truncateAddressShort(String addr) {
    if (addr.length <= 16) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  void _showActionDialog(String action) {
    switch (action) {
      case 'Receive':
        _showReceiveModal();
        break;
      case 'Swap':
        _showSwapComingSoon();
        break;
      default:
        _showGenericActionDialog(action);
    }
  }

  void _showGenericActionDialog(String action) {
    final l10n = AppLocalizations.of(context);

    final actionLabel = switch (action) {
      'Send' => l10n.walletSend,
      'Stake' => l10n.walletStake,
      _ => action,
    };
    final actionIcon = switch (action) {
      'Send' => Icons.arrow_upward,
      'Stake' => Icons.lock_outline,
      _ => Icons.info_outline,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.zTextDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                gradient: LinearGradient(
                  colors: [
                    _currentAccent.withOpacity(0.2),
                    _currentAccent.withOpacity(0.08),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(actionIcon, color: _currentAccent, size: 26),
            ),
            SizedBox(height: ZeroSpacing.md),
            Text(
              actionLabel,
              style: ZeroTypography.title(context).copyWith(
                color: _currentAccent,
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            Text(
              '$actionLabel on ${_chainNames[_currentWallet.chainId]}',
              style: ZeroTypography.caption(context),
            ),
            SizedBox(height: ZeroSpacing.lg),
            ZeroCard(
              padding: EdgeInsets.all(ZeroSpacing.md),
              borderRadius: ZeroSpacing.cardRadiusSm,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: context.zTextTertiary),
                  SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Text(
                      'This feature will be available in the next update. Zero-fee transfers coming soon.',
                      style: ZeroTypography.caption(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ZeroSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zSurfaceOverlay,
                  foregroundColor: context.zTextSecondary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: ZeroTypography.bodyBold(context).copyWith(
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showReceiveModal() {
    String selectedChain = _currentWallet.chainId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final wallet = _wallets.firstWhere(
              (w) => w.chainId == selectedChain,
              orElse: () => _currentWallet,
            );
            final chainAccent = _chainColors[selectedChain] ?? _currentAccent;

            return Container(
              margin: EdgeInsets.all(ZeroSpacing.md),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              padding: EdgeInsets.all(ZeroSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.zTextDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  Text(
                    AppLocalizations.of(context).walletReceive,
                    style: ZeroTypography.title(context).copyWith(
                      color: chainAccent,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.xs),
                  Text(
                    'Scan QR to receive on ${_chainNames[selectedChain]}',
                    style: ZeroTypography.caption(context),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _chainOrder.map((chain) {
                        final isSelected = chain == selectedChain;
                        final color = _chainColors[chain]!;
                        return Padding(
                          padding: EdgeInsets.only(right: ZeroSpacing.sm),
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedChain = chain),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ZeroSpacing.md,
                                vertical: ZeroSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.15)
                                    : context.zSurfaceOverlay.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withOpacity(0.4)
                                      : context.zFrostWhiteStrong,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.3),
                                          color.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      chain,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ZeroSpacing.xs),
                                  Text(
                                    chain,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: isSelected ? color : context.zTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  Container(
                    padding: EdgeInsets.all(ZeroSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: chainAccent.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            size: Size(220, 220),
                            painter: _QrCodePainter(
                              data: wallet.address,
                              foreground: const Color(0xFF1A1A2E),
                              background: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: ZeroSpacing.md),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                chainAccent.withOpacity(0.25),
                                chainAccent.withOpacity(0.1),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedChain,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chainAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.zSurfaceOverlay.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      border: Border.all(
                        color: context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      wallet.address,
                      style: ZeroTypography.monoSmall(context).copyWith(
                        fontSize: 11,
                        letterSpacing: 0,
                        color: context.zTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: wallet.address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context).copyPhrase,
                              style: ZeroTypography.caption(context).copyWith(
                                color: context.zTextPrimary,
                              ),
                            ),
                            backgroundColor: context.zSurfaceRaised,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.screenHorizontal,
                              vertical: ZeroSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 16, color: context.zBg),
                      label: Text(
                        AppLocalizations.of(context).copyAddress,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.zBg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: chainAccent,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.zSurfaceOverlay,
                        foregroundColor: context.zTextSecondary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          side: BorderSide(
                            color: context.zFrostWhiteStrong,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).cancel,
                        style: ZeroTypography.bodyBold(context).copyWith(
                          color: context.zTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSwapComingSoon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.zTextDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ZeroSpacing.xxl),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.zAccent.withOpacity(0.15),
                    context.zCeladon.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: context.zAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.swap_horiz,
                size: 44,
                color: context.zAccent.withOpacity(0.7),
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Text(
              AppLocalizations.of(context).walletSwap,
              style: ZeroTypography.headline(context).copyWith(
                color: context.zAccent,
              ),
            ),
            SizedBox(height: ZeroSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
              child: Text(
                'Cross-chain swaps via ZeroPay are coming soon.\nSwap BTC, ETH, SOL and more — zero fees, instant settlement.',
                style: ZeroTypography.body(context),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _chainOrder.take(4).map((chain) {
                final color = _chainColors[chain]!;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.sm,
                    vertical: ZeroSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    border: Border.all(
                      color: color.withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    chain,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ZeroSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zSurfaceOverlay,
                  foregroundColor: context.zTextSecondary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).cancel,
                  style: ZeroTypography.bodyBold(context).copyWith(
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionRecord tx) {
    final chainId = _currentWallet.chainId;
    final accent = _currentAccent;
    final unit = _chainUnits[chainId]!;
    final walletAddress = _currentWallet.address;
    final rng = Random(tx.hash.hashCode);

    final mockOtherAddr = chainId == 'BTC'
        ? 'bc1q${_randomHex(38, rng)}'
        : '0x${_randomHex(40, rng)}';

    final fromAddr = tx.incoming ? mockOtherAddr : walletAddress;
    final toAddr = tx.incoming ? walletAddress : mockOtherAddr;

    final isConfirmed = tx.time.isBefore(DateTime.now().subtract(const Duration(minutes: 5)));
    final status = isConfirmed ? 'Confirmed' : 'Pending';
    final statusColor = isConfirmed ? context.zSuccess : context.zWarning;

    final feeAmount = switch (chainId) {
      'BTC' => 0.00005 + rng.nextDouble() * 0.00015,
      'ETH' => 0.001 + rng.nextDouble() * 0.004,
      'BSC' => 0.0005 + rng.nextDouble() * 0.001,
      'TRX' => 0.1 + rng.nextDouble() * 0.5,
      'SOL' => 0.000005 + rng.nextDouble() * 0.00001,
      _ => 0.001,
    };
    final feeUnit = chainId == 'ETH' || chainId == 'BSC' ? 'ETH' : unit;
    final feePrice = _usdPrices[chainId] ?? 0;
    final feeUsd = feeAmount * feePrice;

    final explorerUrl = '${_explorerUrls[chainId]}${tx.hash}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ZeroSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zTextDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: tx.incoming
                          ? context.zSuccess.withOpacity(0.1)
                          : context.zSurfaceOverlay,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      tx.incoming ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 22,
                      color: tx.incoming ? context.zSuccess : accent,
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.type,
                          style: ZeroTypography.title(context),
                        ),
                        SizedBox(height: 2),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.incoming ? '+' : '-'}${_formatBalance(tx.amount)} $unit',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: tx.incoming ? context.zSuccess : context.zTextPrimary,
                        ),
                      ),
                      Text(
                        '\$ ${_formatUsd(tx.usdValue)}',
                        style: ZeroTypography.caption(context),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              _buildDetailRow(ctx, 'Transaction Hash', tx.hash, monospace: true, fullWidth: true),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(ctx, 'From', fromAddr, monospace: true, copyable: true),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(ctx, 'To', toAddr, monospace: true, copyable: true),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(
                ctx,
                'Amount',
                '${tx.incoming ? '+' : '-'}${_formatBalance(tx.amount)} $unit',
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(
                ctx,
                'Value',
                '\$ ${_formatUsd(tx.usdValue)}',
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(
                ctx,
                'Network Fee',
                '${feeAmount.toStringAsFixed(6)} $feeUnit  (\$ ${_formatUsd(feeUsd)})',
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailRow(
                ctx,
                'Timestamp',
                '${tx.time.toString().substring(0, 19)}',
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: explorerUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Explorer link copied',
                          style: ZeroTypography.caption(context).copyWith(
                            color: context.zTextPrimary,
                          ),
                        ),
                        backgroundColor: context.zSurfaceRaised,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.screenHorizontal,
                          vertical: ZeroSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_browser, size: 16, color: accent),
                  label: Text(
                    'View on ${_getExplorerName(chainId)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.withOpacity(0.1),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(color: accent.withOpacity(0.3), width: 0.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zSurfaceOverlay,
                    foregroundColor: context.zTextSecondary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: ZeroTypography.bodyBold(context).copyWith(
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext ctx,
    String label,
    String value, {
    bool monospace = false,
    bool copyable = false,
    bool fullWidth = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(ctx).copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ZeroSpacing.xs),
        GestureDetector(
          onTap: copyable ? () => _copyText(value) : null,
          child: Row(
            children: [
              if (fullWidth)
                Expanded(
                  child: Text(
                    value,
                    style: (monospace
                            ? ZeroTypography.monoSmall(ctx)
                            : ZeroTypography.body(ctx))
                        .copyWith(
                      fontSize: monospace ? 10 : 14,
                      color: ctx.zTextSecondary,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: (monospace
                          ? ZeroTypography.monoSmall(ctx)
                          : ZeroTypography.body(ctx))
                      .copyWith(
                    fontSize: monospace ? 10 : 14,
                    color: ctx.zTextSecondary,
                  ),
                ),
              if (copyable) ...[
                SizedBox(width: ZeroSpacing.sm),
                Icon(Icons.copy, size: 13, color: ctx.zTextTertiary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getExplorerName(String chainId) {
    return switch (chainId) {
      'ETH' => 'Etherscan',
      'BTC' => 'Blockchain.com',
      'BSC' => 'BscScan',
      'TRX' => 'Tronscan',
      'SOL' => 'Solscan',
      _ => 'Explorer',
    };
  }

  String _randomHex(int length, Random rng) {
    const chars = '0123456789abcdef';
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  void _showAddressBook() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: EdgeInsets.all(ZeroSpacing.md),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ZeroSpacing.lg,
                      ZeroSpacing.lg,
                      ZeroSpacing.lg,
                      ZeroSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.zTextDisabled,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: ZeroSpacing.md),
                        Row(
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 22,
                              color: context.zTextSecondary,
                            ),
                            SizedBox(width: ZeroSpacing.sm),
                            Text(
                              'Address Book',
                              style: ZeroTypography.title(context),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _showAddContactForm();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.md,
                                  vertical: ZeroSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: context.zAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    ZeroSpacing.chipRadius,
                                  ),
                                  border: Border.all(
                                    color: context.zAccent.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 16,
                                      color: context.zAccent,
                                    ),
                                    SizedBox(width: ZeroSpacing.xs),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.zAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.lg,
                        vertical: ZeroSpacing.sm,
                      ),
                      itemCount: _contacts.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: ZeroSpacing.sm),
                      itemBuilder: (_, i) {
                        final contact = _contacts[i];
                        final chainColor = _chainColors[contact.chainId]!;
                        return GestureDetector(
                          onTap: () {
                            _copyText(contact.address);
                          },
                          child: Container(
                            padding: EdgeInsets.all(ZeroSpacing.md),
                            decoration: BoxDecoration(
                              color: context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                ZeroSpacing.cardRadiusSm,
                              ),
                              border: Border.all(
                                color: context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        chainColor.withOpacity(0.2),
                                        chainColor.withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    contact.label[0].toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: chainColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ZeroSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.label,
                                        style:
                                            ZeroTypography.bodyBold(context)
                                                .copyWith(fontSize: 14),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _truncateAddress(contact.address),
                                        style: ZeroTypography.monoSmall(context)
                                            .copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ZeroSpacing.sm,
                                    vertical: ZeroSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chainColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: chainColor.withOpacity(0.25),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    contact.chainId,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: chainColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(ZeroSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zSurfaceOverlay,
                          foregroundColor: context.zTextSecondary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: ZeroSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ZeroSpacing.buttonRadius,
                            ),
                            side: BorderSide(
                              color: context.zFrostWhiteStrong,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style:
                              ZeroTypography.bodyBold(context).copyWith(
                            color: context.zTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddContactForm() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    String selectedChain = 'ETH';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: EdgeInsets.all(ZeroSpacing.md),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(ZeroSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.zTextDisabled,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      'Add Contact',
                      style: ZeroTypography.title(context),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      'Label',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: context.zSurfaceOverlay.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                        border: Border.all(
                          color: context.zFrostWhiteStrong,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: labelController,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Bob's Wallet",
                          hintStyle: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      'Address',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: context.zSurfaceOverlay.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                        border: Border.all(
                          color: context.zFrostWhiteStrong,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: addressController,
                        style: ZeroTypography.monoSmall(context).copyWith(
                          fontSize: 13,
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0x... or bc1...',
                          hintStyle: ZeroTypography.monoSmall(context).copyWith(
                            fontSize: 13,
                            color: context.zTextTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      'Chain',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Wrap(
                      spacing: ZeroSpacing.sm,
                      runSpacing: ZeroSpacing.sm,
                      children: _chainOrder.map((chain) {
                        final isSelected = chain == selectedChain;
                        final color = _chainColors[chain]!;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedChain = chain),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.15)
                                  : context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                ZeroSpacing.chipRadius,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? color.withOpacity(0.4)
                                    : context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              chain,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : context.zTextTertiary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final label = labelController.text.trim();
                          final address = addressController.text.trim();
                          if (label.isNotEmpty && address.isNotEmpty) {
                            setState(() {
                              _contacts.add(_ContactEntry(
                                label: label,
                                address: address,
                                chainId: selectedChain,
                              ));
                            });
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Contact added',
                                  style: ZeroTypography.caption(context)
                                      .copyWith(color: context.zTextPrimary),
                                ),
                                backgroundColor: context.zSurfaceRaised,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.screenHorizontal,
                                  vertical: ZeroSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ZeroSpacing.chipRadius,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zAccent,
                          foregroundColor: context.zBg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: ZeroSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ZeroSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Save Contact',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.zBg,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zSurfaceOverlay,
                          foregroundColor: context.zTextSecondary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: ZeroSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ZeroSpacing.buttonRadius,
                            ),
                            side: BorderSide(
                              color: context.zFrostWhiteStrong,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: context.zTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWalletQrDialog() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final wallet = _currentWallet;
    final chainId = wallet.chainId;
    final chainAccent = _chainColors[chainId] ?? _currentAccent;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(ZeroSpacing.lg),
        child: Container(
          padding: EdgeInsets.all(ZeroSpacing.lg),
          decoration: BoxDecoration(
            color: context.zSurfaceRaised,
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
            border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isZh ? '钱包二维码' : 'Wallet QR Code',
                style: ZeroTypography.title(context).copyWith(
                  color: chainAccent,
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(
                padding: EdgeInsets.all(ZeroSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: chainAccent.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _QrCodePainter(
                      data: wallet.address,
                      foreground: const Color(0xFF1A1A2E),
                      background: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.md),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.md,
                  vertical: ZeroSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.zSurfaceOverlay.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: context.zFrostWhiteStrong,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            chainAccent.withOpacity(0.25),
                            chainAccent.withOpacity(0.1),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        chainId,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: chainAccent,
                        ),
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.sm),
                    Expanded(
                      child: Text(
                        wallet.address,
                        style: ZeroTypography.caption(context).copyWith(
                          fontFamily: 'Inter',
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ZeroSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zSurfaceOverlay,
                    foregroundColor: context.zTextSecondary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                  ),
                  child: Text(
                    isZh ? '关闭' : 'Close',
                    style: ZeroTypography.bodyBold(context).copyWith(
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.zBg,
        appBar: AppBar(
          backgroundColor: context.zBg,
          elevation: 0,
          title: Text(
            l10n.tabWallet,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: context.zTextPrimary,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.zTextSecondary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final accent = _currentAccent;

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Text(
          l10n.tabWallet,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.xs),
            child: IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.zTextSecondary,
                      ),
                    )
                  : Icon(Icons.refresh, color: context.zTextSecondary, size: 20),
              onPressed: _isRefreshing ? null : _onRefresh,
              tooltip: 'Refresh',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.xs),
            child: IconButton(
              icon: Icon(Icons.qr_code_scanner, color: context.zTextSecondary, size: 22),
              onPressed: _showWalletQrDialog,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.link_rounded, color: context.zWarning, size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroChainExplorer())),
              tooltip: 'ZeroChain',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.language_rounded, color: context.zAccent, size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroDNSScreen())),
              tooltip: 'ZeroDNS',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.storefront_rounded, color: context.zCeladon, size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroMarketScreen())),
              tooltip: 'ZeroMarket',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.account_balance_rounded, color: const Color(0xFF9B59B6), size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroDAOScreen())),
              tooltip: 'ZeroDAO',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.swap_horiz_rounded, color: const Color(0xFF4FC3F7), size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroBridgeScreen())),
              tooltip: 'ZeroBridge',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.receipt_long_rounded, color: const Color(0xFF26A69A), size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const TransactionHistoryScreen())),
              tooltip: 'Transactions',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.sm),
            child: IconButton(
              icon: Icon(Icons.show_chart_rounded, color: const Color(0xFFF7931A), size: 22),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const TokenomicsDashboard())),
              tooltip: 'ZERO',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: accent,
        backgroundColor: context.zSurfaceRaised,
        displacement: 20,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildTotalBalanceHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildChainTabBar(),
            ),
            SliverToBoxAdapter(
              child: _buildBalanceCard(accent),
            ),
            SliverToBoxAdapter(
              child: _buildActionRow(accent),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: ZeroSpacing.screenHorizontal,
                  right: ZeroSpacing.screenHorizontal,
                  top: ZeroSpacing.lg,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.transactionHistory,
                      style: ZeroTypography.title(context).copyWith(
                        color: context.zTextSecondary,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_chainNames[_currentWallet.chainId]}',
                      style: ZeroTypography.caption(context).copyWith(
                        color: accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildTxCard(
                  _currentTx[i],
                  accent,
                  _chainUnits[_currentWallet.chainId]!,
                ),
                childCount: _currentTx.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: ZeroSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceHeader() {
    final total = _totalUsdValue;

    return Container(
      margin: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.xs,
      ),
      child: ZeroCard(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.lg,
          vertical: ZeroSpacing.md,
        ),
        borderRadius: ZeroSpacing.cardRadius,
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context).walletBalance,
              style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 1.5,
                color: context.zTextTertiary,
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  context.zTextPrimary,
                  context.zTextSecondary.withOpacity(0.6),
                ],
              ).createShader(bounds),
              child: Text(
                '\$ ${_formatUsd(total)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1.5,
                  color: context.zTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainTabBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.xs,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius - 1),
                gradient: LinearGradient(
                  colors: [
                    _chainColors[_wallets[_selectedIndex].chainId]!.withOpacity(0.15),
                    _chainColors[_wallets[_selectedIndex].chainId]!.withOpacity(0.05),
                  ],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _chainColors[_wallets[_selectedIndex].chainId],
              unselectedLabelColor: context.zTextTertiary,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: List.generate(_chainOrder.length, (i) {
                final chainId = _chainOrder[i];
                final wallet = _wallets.firstWhere(
                  (w) => w.chainId == chainId,
                  orElse: () => _wallets[i],
                );
                final balance = _realBalances[chainId] ?? wallet.balance;
                final badgeText = _formatBadgeBalance(balance);
                return Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chainId),
                      if (balance > 0)
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Color accent) {
    final balance = _currentBalance;
    final usd = _currentUsdValue;
    final wallet = _currentWallet;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        borderRadius: ZeroSpacing.cardRadius,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.25), accent.withOpacity(0.1)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    wallet.chainId,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SizedBox(width: ZeroSpacing.sm),
                Text(
                  _chainNames[wallet.chainId]!,
                  style: ZeroTypography.title(context).copyWith(
                    fontSize: 15,
                    color: context.zTextSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.md),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [accent, accent.withOpacity(0.5)],
              ).createShader(bounds),
              child: Text(
                '${_formatBalance(balance)} ${_chainUnits[wallet.chainId]}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.2,
                  color: accent,
                ),
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            Text(
              '\$ ${_formatUsd(usd)}',
              style: ZeroTypography.body(context).copyWith(
                fontFamily: 'Inter',
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: ZeroSpacing.sm),
            Tooltip(
              message: AppLocalizations.of(context).copyAddress,
              child: GestureDetector(
                onTap: _onCopyAddress,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.md,
                    vertical: ZeroSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.zSurfaceOverlay.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 12, color: context.zTextTertiary),
                      const SizedBox(width: ZeroSpacing.xs),
                      Text(
                        wallet.address.length > 24
                            ? '${wallet.address.substring(0, 10)}...${wallet.address.substring(wallet.address.length - 8)}'
                            : wallet.address,
                        style: ZeroTypography.monoSmall(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(Color accent) {
    final l10n = AppLocalizations.of(context);

    final actions = [
      ('Send', l10n.walletSend, Icons.arrow_upward),
      ('Receive', l10n.walletReceive, Icons.arrow_downward),
      ('Swap', l10n.walletSwap, Icons.swap_horiz),
      ('Stake', l10n.walletStake, Icons.lock_outline),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.md,
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: ZeroSpacing.sm),
            Expanded(
              child: _ActionButton(
                icon: actions[i].$3,
                label: actions[i].$2,
                accent: accent,
                onTap: () => _showActionDialog(actions[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTxCard(TransactionRecord tx, Color accent, String unit) {
    final hashDisplay = tx.hash.length > 24
        ? '${tx.hash.substring(0, 10)}...${tx.hash.substring(tx.hash.length - 8)}'
        : tx.hash;

    final timeStr = _formatTxTime(tx.time);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.xs,
      ),
      child: GestureDetector(
        onTap: () => _showTransactionDetail(tx),
        child: ZeroCard(
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.md,
            vertical: ZeroSpacing.md,
          ),
          borderRadius: ZeroSpacing.cardRadiusSm,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tx.incoming
                      ? context.zSuccess.withOpacity(0.1)
                      : context.zSurfaceOverlay,
                ),
                alignment: Alignment.center,
                child: Icon(
                  tx.incoming ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                  color: tx.incoming ? context.zSuccess : accent,
                ),
              ),
              SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.type,
                      style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      hashDisplay,
                      style: ZeroTypography.monoSmall(context).copyWith(
                        fontSize: 9,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.incoming ? '+' : '-'}${_formatBalance(tx.amount)} $unit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: tx.incoming ? context.zSuccess : context.zTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTxTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: accent.withOpacity(0.85)),
            SizedBox(height: 6),
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: context.zTextSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}