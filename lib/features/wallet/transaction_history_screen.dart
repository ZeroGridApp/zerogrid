import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/wallet/transaction_history_service.dart';
import '../../widgets/zero_card.dart';

const _chainColors = <String, Color>{
  'eth': Color(0xFF627EEA),
  'bsc': Color(0xFFF3BA2F),
  'sol': Color(0xFF9945FF),
  'trx': Color(0xFFFF060A),
  'btc': Color(0xFFF7931A),
};

const _chainDisplayNames = <String, String>{
  'eth': 'ETH',
  'bsc': 'BSC',
  'sol': 'SOL',
  'trx': 'TRX',
  'btc': 'BTC',
};

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final ZeroTransactionHistoryService _txService =
      ZeroTransactionHistoryService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedChain = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  List<TransactionRecord> _applyFilters({
    required List<TransactionRecord> source,
  }) {
    var filtered = source;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.token.toLowerCase().contains(q) ||
            (t.memo?.toLowerCase().contains(q) ?? false) ||
            t.fromAddress.toLowerCase().contains(q) ||
            t.toAddress.toLowerCase().contains(q) ||
            (t.toName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_selectedChain != 'all') {
      filtered = filtered
          .where((t) => t.chainId == _selectedChain)
          .toList();
    }

    return filtered;
  }

  List<TransactionRecord> _getTransactionsForTab(int tabIndex) {
    List<TransactionRecord> source;
    switch (tabIndex) {
      case 0:
        source = _txService.getAllTransactions();
        break;
      case 1:
        source = _txService.getSentTransactions();
        break;
      case 2:
        source = _txService.getReceivedTransactions();
        break;
      default:
        source = _txService.getAllTransactions();
    }
    return _applyFilters(source: source);
  }

  String _formatUsd(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatSmallUsd(double value) {
    if (value.abs() >= 1000000) {
      return '\$${(value.abs() / 1000000).toStringAsFixed(2)}M';
    }
    if (value.abs() >= 1000) {
      return '\$${(value.abs() / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.abs().toStringAsFixed(2)}';
  }

  String _truncateAddress(String addr) {
    if (addr.length <= 16) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  String _timeAgo(DateTime timestamp, bool isZh) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
    if (diff.inMinutes < 60) {
      return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    }
    if (diff.inDays < 365) {
      return isZh
          ? '${timestamp.month}月${timestamp.day}日'
          : '${timestamp.month}/${timestamp.day}';
    }
    return isZh
        ? '${timestamp.year}年${timestamp.month}月${timestamp.day}日'
        : '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  String _trType(String type, bool isZh) {
    return switch (type) {
      'sent' => isZh ? '支出' : 'Sent',
      'received' => isZh ? '收入' : 'Received',
      'swap' => isZh ? '兑换' : 'Swap',
      'bridge' => isZh ? '跨链' : 'Bridge',
      _ => type,
    };
  }

  String _trStatus(String status, bool isZh) {
    return switch (status) {
      'confirmed' => isZh ? '已确认' : 'Confirmed',
      'pending' => isZh ? '待确认' : 'Pending',
      'failed' => isZh ? '失败' : 'Failed',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'confirmed' => context.zSuccess,
      'pending' => context.zWarning,
      'failed' => context.zError,
      _ => context.zTextTertiary,
    };
  }

  String _trChainName(String chainName, bool isZh) {
    return switch (chainName) {
      'Ethereum' => isZh ? '以太坊' : 'Ethereum',
      'BSC' => 'BSC',
      'Solana' => 'Solana',
      'TRON' => 'TRON',
      'Bitcoin' => isZh ? '比特币' : 'Bitcoin',
      _ => chainName,
    };
  }

  IconData _directionIcon(String type) {
    return switch (type) {
      'sent' => Icons.arrow_upward,
      'received' => Icons.arrow_downward,
      'swap' || 'bridge' => Icons.swap_horiz,
      _ => Icons.swap_horiz,
    };
  }

  Color _directionColor(String type) {
    return switch (type) {
      'sent' => context.zError,
      'received' => context.zSuccess,
      _ => context.zAccent,
    };
  }

  String _amountPrefix(String type) {
    return switch (type) {
      'sent' => '-',
      'received' => '+',
      _ => '↔ ',
    };
  }

  Color _amountColor(String type) {
    return switch (type) {
      'sent' => context.zError,
      'received' => context.zSuccess,
      _ => context.zAccent,
    };
  }

  String _tokenIcon(String token) {
    return switch (token) {
      'ETH' => '⟠',
      'BTC' => '₿',
      'BNB' => '🟡',
      'SOL' => '🟣',
      'TRX' => '🔴',
      'USDT' => '💵',
      _ => '🪙',
    };
  }

  void _showTransactionDetail(TransactionRecord tx) {
    final isZh = ZeroTheme.isZh(context);
    final txHashDisplay = tx.txHash.length > 30
        ? '${tx.txHash.substring(0, 16)}...${tx.txHash.substring(tx.txHash.length - 12)}'
        : tx.txHash;
    final chainColor =
        _chainColors[tx.chainId] ?? context.zTextTertiary;
    final chainName = _trChainName(tx.chainName, isZh);
    final chainDisplay = _chainDisplayNames[tx.chainId] ?? tx.chainId.toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
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
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            _amountColor(tx.type).withOpacity(0.2),
                            _amountColor(tx.type).withOpacity(0.08),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _directionIcon(tx.type),
                        size: 28,
                        color: _amountColor(tx.type),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _amountPrefix(tx.type),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -1.5,
                            color: _amountColor(tx.type),
                          ),
                        ),
                        Text(
                          '${tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 4)} ${tx.token}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.5,
                            color: _amountColor(tx.type),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      '\$${tx.usdValue.toStringAsFixed(2)}',
                      style: ZeroTypography.body(context).copyWith(
                        fontFamily: 'Inter',
                        color: context.zTextSecondary,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                    _buildStatusBadge(tx.status, isZh),
                  ],
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              _buildDetailSection(
                isZh ? '交易哈希' : 'Transaction Hash',
                txHashDisplay,
                copyable: true,
                copyText: tx.txHash,
                monospace: true,
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '状态' : 'Status',
                _trStatus(tx.status, isZh),
                trailing: _buildStatusBadge(tx.status, isZh),
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '金额' : 'Amount',
                '${_amountPrefix(tx.type)}${tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 4)} ${tx.token}',
                subtitle: '\$${tx.usdValue.toStringAsFixed(2)}',
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '发送方' : 'From',
                tx.fromAddress,
                copyable: true,
                copyText: tx.fromAddress,
                monospace: true,
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '接收方' : 'To',
                tx.toAddress,
                copyable: true,
                copyText: tx.toAddress,
                monospace: true,
                extraText: tx.toName,
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '手续费' : 'Fee',
                '${tx.fee.toStringAsFixed(6)} ${tx.token}',
                subtitle: tx.feeUsd > 0
                    ? '\$${tx.feeUsd.toStringAsFixed(2)}'
                    : null,
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '网络 / 区块' : 'Chain / Block',
                chainName,
                subtitle: tx.blockNumber != null
                    ? (isZh
                        ? '区块 #${tx.blockNumber}'
                        : 'Block #${tx.blockNumber}')
                    : null,
                leadingColor: chainColor,
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '确认数' : 'Confirmations',
                '${tx.confirmations}',
              ),
              SizedBox(height: ZeroSpacing.md),
              _buildDetailSection(
                isZh ? '时间' : 'Timestamp',
                '${tx.timestamp.year}-'
                    '${tx.timestamp.month.toString().padLeft(2, '0')}-'
                    '${tx.timestamp.day.toString().padLeft(2, '0')} '
                    '${tx.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${tx.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${tx.timestamp.second.toString().padLeft(2, '0')}',
              ),
              if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                SizedBox(height: ZeroSpacing.md),
                _buildDetailSection(
                  isZh ? '备注' : 'Memo',
                  tx.memo!,
                ),
              ],
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final explorerUrl = _getExplorerUrl(tx.chainId, tx.txHash);
                    Clipboard.setData(ClipboardData(text: explorerUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isZh ? '浏览器链接已复制' : 'Explorer link copied',
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
                          borderRadius:
                              BorderRadius.circular(ZeroSpacing.chipRadius),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_browser, size: 16, color: context.zAccent),
                  label: Text(
                    isZh ? '在浏览器中查看' : 'View on Explorer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.zAccent,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zAccent.withOpacity(0.1),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(
                        color: context.zAccent.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final buffer = StringBuffer();
                    buffer.writeln(isZh ? '交易收据' : 'Transaction Receipt');
                    buffer.writeln('---');
                    buffer.writeln('${isZh ? "哈希" : "Hash"}: ${tx.txHash}');
                    buffer.writeln(
                        '${isZh ? "金额" : "Amount"}: ${_amountPrefix(tx.type)}${tx.amount} ${tx.token} (\$${tx.usdValue})');
                    buffer.writeln(
                        '${isZh ? "发送方" : "From"}: ${tx.fromAddress}');
                    buffer.writeln(
                        '${isZh ? "接收方" : "To"}: ${tx.toAddress}');
                    buffer.writeln(
                        '${isZh ? "手续费" : "Fee"}: ${tx.fee} ${tx.token} (\$${tx.feeUsd})');
                    buffer.writeln(
                        '${isZh ? "状态" : "Status"}: ${_trStatus(tx.status, isZh)}');
                    buffer.writeln(
                        '${isZh ? "时间" : "Time"}: ${tx.timestamp}');
                    Clipboard.setData(
                        ClipboardData(text: buffer.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isZh ? '收据已复制到剪贴板' : 'Receipt copied to clipboard',
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
                          borderRadius:
                              BorderRadius.circular(ZeroSpacing.chipRadius),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.share_outlined, size: 16, color: context.zTextSecondary),
                  label: Text(
                    isZh ? '分享收据' : 'Share Receipt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.zTextSecondary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zSurfaceOverlay,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(
                        color: context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
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
                      borderRadius:
                          BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(
                        color: context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
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
              SizedBox(
                height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String label,
    String value, {
    String? subtitle,
    String? extraText,
    bool copyable = false,
    String? copyText,
    bool monospace = false,
    Widget? trailing,
    Color? leadingColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leadingColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leadingColor,
                ),
              ),
              SizedBox(width: ZeroSpacing.xs),
            ],
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
        SizedBox(height: ZeroSpacing.xs),
        GestureDetector(
          onTap: copyable
              ? () {
                  final text = copyText ?? value;
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ZeroTheme.isZh(context) ? '已复制' : 'Copied',
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
                        borderRadius:
                            BorderRadius.circular(ZeroSpacing.chipRadius),
                      ),
                    ),
                  );
                }
              : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: (monospace
                          ? ZeroTypography.monoSmall(context)
                          : ZeroTypography.body(context))
                      .copyWith(
                    fontSize: monospace ? 10 : 14,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
              if (copyable) ...[
                SizedBox(width: ZeroSpacing.xs),
                Icon(Icons.copy, size: 13, color: context.zTextTertiary),
              ],
            ],
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 2),
          Text(
            subtitle,
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 11,
            ),
          ),
        ],
        if (extraText != null) ...[
          SizedBox(height: 2),
          Text(
            extraText,
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 11,
              color: context.zAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isZh) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.sm + 2,
        vertical: ZeroSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'confirmed'
                ? Icons.check_circle
                : status == 'pending'
                    ? Icons.hourglass_empty
                    : Icons.cancel,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            _trStatus(status, isZh),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getExplorerUrl(String chainId, String txHash) {
    return switch (chainId) {
      'eth' => 'https://etherscan.io/tx/$txHash',
      'bsc' => 'https://bscscan.com/tx/$txHash',
      'sol' => 'https://solscan.io/tx/$txHash',
      'trx' => 'https://tronscan.org/#/transaction/$txHash',
      'btc' => 'https://www.blockchain.com/explorer/transactions/btc/$txHash',
      _ => 'https://explorer.zerochain.network/tx/$txHash',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final summary = _txService.getSummary();

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Text(
          isZh ? '交易记录' : 'Transaction History',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(summary, isZh),
          _buildSearchBar(isZh),
          _buildChainFilterChips(),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.screenHorizontal,
            ),
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(ZeroSpacing.chipRadius - 1),
                color: context.zAccent.withOpacity(0.1),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: context.zAccent,
              unselectedLabelColor: context.zTextTertiary,
              labelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                Tab(text: isZh ? '全部分类' : 'All'),
                Tab(text: isZh ? '支出' : 'Sent'),
                Tab(text: isZh ? '收入' : 'Received'),
              ],
            ),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [0, 1, 2].map((tabIndex) {
                final transactions = _getTransactionsForTab(tabIndex);
                return _buildTransactionList(transactions, isZh);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TransactionSummary summary, bool isZh) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.sm,
      ),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.lg),
        borderRadius: ZeroSpacing.cardRadius,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: context.zAccent,
                ),
                SizedBox(width: ZeroSpacing.xs),
                Text(
                  isZh ? '交易概览' : 'Transaction Summary',
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                    color: context.zAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.md),
            Row(
              children: [
                _buildSummaryItem(
                  isZh ? '总支出' : 'Total Sent',
                  summary.totalSent,
                  context.zError,
                ),
                _buildSummaryItem(
                  isZh ? '总收入' : 'Total Received',
                  summary.totalReceived,
                  context.zSuccess,
                ),
                _buildSummaryItem(
                  isZh ? '总手续费' : 'Total Fees',
                  summary.totalFees,
                  context.zWarning,
                ),
                _buildSummaryItem(
                  isZh ? '交易数' : 'Tx Count',
                  summary.transactionCount.toDouble(),
                  context.zAccent,
                  isCount: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color accentColor, {
    bool isCount = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.6)],
            ).createShader(bounds),
            child: Text(
              isCount
                  ? '${value.toInt()}'
                  : _formatSmallUsd(value),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCount ? 22 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: accentColor,
              ),
            ),
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            label,
            style: ZeroTypography.caption(context).copyWith(
              fontSize: 10,
              color: context.zTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isZh) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.xs,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.sm,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
          border: Border.all(
            color: context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: ZeroTypography.body(context).copyWith(
            fontSize: 14,
            color: context.zTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: isZh ? '搜索代币、备注、地址、名称' : 'Search token, memo, address, name',
            hintStyle: ZeroTypography.body(context).copyWith(
              fontSize: 14,
              color: context.zTextTertiary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: context.zTextTertiary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.zTextTertiary,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: ZeroSpacing.sm,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildChainFilterChips() {
    final chains = [
      {'id': 'all', 'label': 'All'},
      {'id': 'eth', 'label': 'ETH'},
      {'id': 'bsc', 'label': 'BSC'},
      {'id': 'sol', 'label': 'SOL'},
      {'id': 'trx', 'label': 'TRX'},
      {'id': 'btc', 'label': 'BTC'},
    ];

    return Container(
      height: 38,
      margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        itemCount: chains.length,
        itemBuilder: (_, i) {
          final chain = chains[i];
          final chainId = chain['id']!;
          final label = chain['label']!;
          final isSelected = chainId == _selectedChain;
          final chipColor =
              _chainColors[chainId] ?? context.zAccent;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChain = chainId;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: ZeroSpacing.sm),
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.md,
                vertical: ZeroSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withOpacity(0.15)
                    : context.zSurfaceOverlay.withOpacity(0.5),
                borderRadius:
                    BorderRadius.circular(ZeroSpacing.chipRadius),
                border: Border.all(
                  color: isSelected
                      ? chipColor.withOpacity(0.4)
                      : context.zFrostWhiteStrong,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chainId != 'all')
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: chipColor.withOpacity(0.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: chipColor,
                        ),
                      ),
                    ),
                  if (chainId != 'all')
                    SizedBox(width: ZeroSpacing.xs),
                  Text(
                    chainId == 'all' ? (ZeroTheme.isZh(context) ? '全部' : 'All') : label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isSelected ? chipColor : context.zTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionRecord> transactions, bool isZh) {
    if (transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.zAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 80),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: context.zTextDisabled,
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Text(
                    isZh ? '暂无交易记录' : 'No transactions found',
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty || _selectedChain != 'all')
                    Padding(
                      padding: EdgeInsets.only(top: ZeroSpacing.xs),
                      child: Text(
                        isZh ? '尝试调整筛选条件' : 'Try adjusting your filters',
                        style: ZeroTypography.caption(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.zAccent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          0,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return Padding(
            padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: _buildTransactionCard(tx, isZh),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionRecord tx, bool isZh) {
    final dirColor = _directionColor(tx.type);
    final amtColor = _amountColor(tx.type);
    final chainColor = _chainColors[tx.chainId] ?? context.zTextTertiary;
    final chainDisplay =
        _chainDisplayNames[tx.chainId] ?? tx.chainId.toUpperCase();
    final otherParty = tx.type == 'sent' ? tx.toAddress : tx.fromAddress;
    final otherName = tx.type == 'sent' ? tx.toName : null;
    final displayName = otherName?.isNotEmpty == true
        ? '$otherName · ${_truncateAddress(otherParty)}'
        : _truncateAddress(otherParty);

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      onTap: () => _showTransactionDetail(tx),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      dirColor.withOpacity(0.2),
                      dirColor.withOpacity(0.08),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _directionIcon(tx.type),
                  size: 20,
                  color: dirColor,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _tokenIcon(tx.token),
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(width: ZeroSpacing.xs),
                        Text(
                          tx.token,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: ZeroSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.xs + 2,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: chainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: chainColor.withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            chainDisplay,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: chainColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      displayName,
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_amountPrefix(tx.type)}${tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 4)} ${tx.token}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: amtColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '\$${tx.usdValue.toStringAsFixed(2)}',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm + 4),
          Row(
            children: [
              _buildStatusBadge(tx.status, isZh),
              const Spacer(),
              if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                Expanded(
                  child: Text(
                    tx.memo!,
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: ZeroSpacing.md),
              ],
              Icon(
                Icons.access_time,
                size: 12,
                color: context.zTextTertiary,
              ),
              SizedBox(width: ZeroSpacing.xs),
              Text(
                _timeAgo(tx.timestamp, isZh),
                style: ZeroTypography.caption(context).copyWith(
                  fontSize: 11,
                  color: context.zTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}