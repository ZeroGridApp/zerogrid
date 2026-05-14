import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/dao/zero_dao_service.dart';
import '../../widgets/zero_card.dart';

class ZeroDAOScreen extends StatefulWidget {
  const ZeroDAOScreen({super.key});

  @override
  State<ZeroDAOScreen> createState() => _ZeroDAOScreenState();
}

class _ZeroDAOScreenState extends State<ZeroDAOScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final ZeroDAOService _daoService = ZeroDAOService();

  List<DaoProposal> _proposals = [];
  List<TreasuryAsset> _treasury = [];
  List<DaoMember> _members = [];
  String _memberSort = 'power';

  static const _avatarColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFFDCB6E),
    Color(0xFFE84393),
    Color(0xFF00CEC9),
    Color(0xFFD63031),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    _proposals = _daoService.getProposals();
    _treasury = _daoService.getTreasury();
    _members = _daoService.getMembers();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _refreshAll();
    });
  }

  Color _avatarColorFor(String id) {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = (hash * 31 + id.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return _avatarColors[hash % _avatarColors.length];
  }

  String _timeRemainingText(Duration remaining, bool isZh) {
    if (remaining.inSeconds <= 0) return isZh ? '已结束' : 'Ended';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) return isZh ? '剩余 ${days}天${hours}小时' : '${days}d ${hours}h left';
    final mins = remaining.inMinutes % 60;
    if (hours > 0) return isZh ? '剩余 ${hours}小时${mins}分钟' : '${hours}h ${mins}m left';
    return isZh ? '剩余 ${mins}分钟' : '${mins}m left';
  }

  String _formatNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _formatUsd(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatBalance(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _categoryLabel(String category, bool isZh) {
    return switch (category) {
      'Funding' => isZh ? '资金' : 'Funding',
      'Protocol' => isZh ? '协议' : 'Protocol',
      'Governance' => isZh ? '治理' : 'Governance',
      'Ecosystem' => isZh ? '生态' : 'Ecosystem',
      _ => category,
    };
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Funding' => const Color(0xFFFDCB6E),
      'Protocol' => const Color(0xFF0984E3),
      'Governance' => const Color(0xFF6C5CE7),
      'Ecosystem' => const Color(0xFF00B894),
      _ => const Color(0xFF888888),
    };
  }

  String _statusLabel(String status, bool isZh) {
    return switch (status) {
      'Active' => isZh ? '进行中' : 'Active',
      'Passed' => isZh ? '已通过' : 'Passed',
      'Rejected' => isZh ? '已拒绝' : 'Rejected',
      'Executed' => isZh ? '已执行' : 'Executed',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Active' => const Color(0xFF6BAF7B),
      'Passed' => const Color(0xFF0984E3),
      'Rejected' => const Color(0xFFE17055),
      'Executed' => const Color(0xFF6C5CE7),
      _ => const Color(0xFF888888),
    };
  }

  void _showProposalDetail(DaoProposal proposal) {
    final isZh = ZeroTheme.isZh(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final totalVotes = proposal.totalVotes;
        final forPct = totalVotes > 0 ? (proposal.votesFor / totalVotes * 100) : 0.0;
        final againstPct = totalVotes > 0 ? (proposal.votesAgainst / totalVotes * 100) : 0.0;
        final abstainPct = totalVotes > 0 ? (proposal.votesAbstain / totalVotes * 100) : 0.0;

        return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.sm + 4,
                        vertical: ZeroSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(proposal.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                        border: Border.all(
                          color: _categoryColor(proposal.category).withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _categoryLabel(proposal.category, isZh),
                        style: TextStyle(
                          fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _categoryColor(proposal.category),
                        ),
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.sm + 4,
                        vertical: ZeroSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(proposal.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                        border: Border.all(
                          color: _statusColor(proposal.status).withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _statusLabel(proposal.status, isZh),
                        style: TextStyle(
                          fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(proposal.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      proposal.quorumReached
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: proposal.quorumReached
                          ? context.zSuccess
                          : context.zTextTertiary,
                    ),
                    SizedBox(width: ZeroSpacing.xs),
                    Text(
                      '${
                        proposal.quorumReached
                            ? (isZh ? '法定人数已达成' : 'Quorum reached')
                            : (isZh ? '法定人数未达成' : 'Quorum not reached')
                      }',
                      style: ZeroTypography.caption(context).copyWith(
                        color: proposal.quorumReached
                            ? context.zSuccess
                            : context.zTextTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ZeroSpacing.md),
                Text(
                  proposal.title,
                  style: ZeroTypography.headline(context),
                ),
                SizedBox(height: ZeroSpacing.sm),
                Text(
                  proposal.description,
                  style: ZeroTypography.body(context),
                ),
                SizedBox(height: ZeroSpacing.lg),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: context.zFrostWhiteStrong,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(
                      children: [
                        if (forPct > 0)
                          Flexible(
                            flex: (forPct * 10).round().clamp(1, 1000),
                            child: Container(color: context.zSuccess),
                          ),
                        if (againstPct > 0)
                          Flexible(
                            flex: (againstPct * 10).round().clamp(1, 1000),
                            child: Container(color: context.zError),
                          ),
                        if (abstainPct > 0)
                          Flexible(
                            flex: (abstainPct * 10).round().clamp(1, 1000),
                            child: Container(color: context.zTextDisabled),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.sm),
                Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.zSuccess,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${isZh ? "支持" : "For"} ${_formatNumber(proposal.votesFor.toDouble())} (${forPct.toStringAsFixed(1)}%)',
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                    SizedBox(width: ZeroSpacing.md),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.zError,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${isZh ? "反对" : "Against"} ${_formatNumber(proposal.votesAgainst.toDouble())} (${againstPct.toStringAsFixed(1)}%)',
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                    if (abstainPct > 0) ...[
                      SizedBox(width: ZeroSpacing.md),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.zTextDisabled,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${isZh ? "弃权" : "Abstain"} ${_formatNumber(proposal.votesAbstain.toDouble())}',
                            style: ZeroTypography.caption(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                SizedBox(height: ZeroSpacing.md),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: context.zTextTertiary),
                    SizedBox(width: ZeroSpacing.xs),
                    Text(
                      '${proposal.proposerName}',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextSecondary,
                      ),
                    ),
                    SizedBox(width: ZeroSpacing.sm),
                    Text(
                      proposal.proposerDid,
                      style: ZeroTypography.monoSmall(context).copyWith(fontSize: 10),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: context.zTextTertiary),
                    SizedBox(width: ZeroSpacing.xs),
                    Text(
                      _timeRemainingText(proposal.timeRemaining, isZh),
                      style: ZeroTypography.caption(context).copyWith(
                        color: proposal.isActive
                            ? context.zWarning
                            : context.zTextTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (proposal.isActive) ...[
                  SizedBox(height: ZeroSpacing.lg),
                  Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
                  SizedBox(height: ZeroSpacing.lg),
                  Text(
                    isZh ? '投票' : 'Cast Your Vote',
                    style: ZeroTypography.title(context),
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _VoteButton(
                          label: isZh ? '支持' : 'For',
                          icon: Icons.thumb_up_outlined,
                          color: context.zSuccess,
                          onTap: () {
                            _daoService.vote(
                              proposal.id,
                              'Z8P2K5W1RT',
                              'You',
                              'for',
                              50000,
                            );
                            Navigator.of(ctx).pop();
                            setState(() => _refreshAll());
                          },
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Expanded(
                        child: _VoteButton(
                          label: isZh ? '反对' : 'Against',
                          icon: Icons.thumb_down_outlined,
                          color: context.zError,
                          onTap: () {
                            _daoService.vote(
                              proposal.id,
                              'Z8P2K5W1RT',
                              'You',
                              'against',
                              50000,
                            );
                            Navigator.of(ctx).pop();
                            setState(() => _refreshAll());
                          },
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Expanded(
                        child: _VoteButton(
                          label: isZh ? '弃权' : 'Abstain',
                          icon: Icons.remove_circle_outline,
                          color: context.zTextTertiary,
                          onTap: () {
                            _daoService.vote(
                              proposal.id,
                              'Z8P2K5W1RT',
                              'You',
                              'abstain',
                              50000,
                            );
                            Navigator.of(ctx).pop();
                            setState(() => _refreshAll());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateProposal() {
    final isZh = ZeroTheme.isZh(context);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Funding';

    final categories = ['Funding', 'Protocol', 'Governance', 'Ecosystem'];

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
                      isZh ? '创建提案' : 'Create Proposal',
                      style: ZeroTypography.headline(context),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh ? '向DAO社区提交新的治理提案' : 'Submit a new governance proposal to the DAO',
                      style: ZeroTypography.body(context),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      isZh ? '标题' : 'Title',
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
                        controller: titleController,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '提案标题' : 'Proposal title',
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
                      isZh ? '描述' : 'Description',
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
                        controller: descController,
                        maxLines: 4,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '提案描述...' : 'Proposal description...',
                          hintStyle: ZeroTypography.body(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(ZeroSpacing.md),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '分类' : 'Category',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                    Wrap(
                      spacing: ZeroSpacing.sm,
                      runSpacing: ZeroSpacing.sm,
                      children: categories.map((cat) {
                        final isSelected = cat == selectedCategory;
                        final catColor = _categoryColor(cat);
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = cat),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withOpacity(0.15)
                                  : context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: isSelected
                                    ? catColor.withOpacity(0.4)
                                    : context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _categoryLabel(cat, isZh),
                              style: TextStyle(
                                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? catColor : context.zTextTertiary,
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
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          if (title.isNotEmpty && desc.isNotEmpty) {
                            _daoService.createProposal(
                              title,
                              desc,
                              selectedCategory,
                              'Z8P2K5W1RT',
                              'You',
                            );
                            Navigator.of(ctx).pop();
                            setState(() => _refreshAll());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zAccent,
                          foregroundColor: context.zBg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                        ),
                        child: Text(
                          isZh ? '提交提案' : 'Submit Proposal',
                          style: TextStyle(
                            fontFamily: isZh ? 'NotoSansSC' : 'Inter',
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
                          padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                            side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                          ),
                        ),
                        child: Text(
                          isZh ? '取消' : 'Cancel',
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              isZh ? 'ZeroDAO' : 'ZeroDAO',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.zAccentGlow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isZh ? '治理' : 'GOVERN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: context.zAccent,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.zAccent,
              indicatorWeight: 1.5,
              labelColor: context.zTextPrimary,
              unselectedLabelColor: context.zTextTertiary,
              labelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: isZh ? '提案' : 'Proposals'),
                Tab(text: isZh ? '国库' : 'Treasury'),
                Tab(text: isZh ? '成员' : 'Members'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProposal,
        backgroundColor: context.zAccent,
        elevation: 0,
        child: Icon(Icons.add_rounded, color: context.zBg, size: 24),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProposalsTab(),
          _buildTreasuryTab(),
          _buildMembersTab(),
        ],
      ),
    );
  }

  Widget _buildProposalsTab() {
    final isZh = ZeroTheme.isZh(context);

    if (_proposals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.zAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_outlined, size: 64, color: context.zTextDisabled),
                  SizedBox(height: ZeroSpacing.md),
                  Text(
                    isZh ? '暂无提案' : 'No proposals yet',
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
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
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.md,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom + 80,
        ),
        itemCount: _proposals.length,
        itemBuilder: (context, index) {
          final proposal = _proposals[index];
          return Padding(
            padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: _buildProposalCard(proposal, isZh),
          );
        },
      ),
    );
  }

  Widget _buildProposalCard(DaoProposal proposal, bool isZh) {
    final catColor = _categoryColor(proposal.category);
    final statusColor = _statusColor(proposal.status);
    final totalVotes = proposal.totalVotes;
    final forPct = totalVotes > 0 ? proposal.votesFor / totalVotes : 0.0;
    final againstPct = totalVotes > 0 ? proposal.votesAgainst / totalVotes : 0.0;

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadius,
      onTap: () => _showProposalDetail(proposal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.sm,
                  vertical: ZeroSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: catColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _categoryLabel(proposal.category, isZh),
                  style: TextStyle(
                    fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: catColor,
                  ),
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.sm,
                  vertical: ZeroSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _statusLabel(proposal.status, isZh),
                  style: TextStyle(
                    fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              if (proposal.isActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.zWarning,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _timeRemainingText(proposal.timeRemaining, isZh),
                      style: ZeroTypography.caption(context).copyWith(
                        fontSize: 10,
                        color: context.zWarning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm + 4),
          Text(
            proposal.title,
            style: ZeroTypography.title(context).copyWith(fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ZeroSpacing.xs),
          Text(
            proposal.description,
            style: ZeroTypography.body(context).copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ZeroSpacing.md),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: context.zFrostWhiteStrong,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (forPct > 0)
                    Flexible(
                      flex: (forPct * 100).round().clamp(1, 100),
                      child: Container(color: context.zSuccess),
                    ),
                  if (againstPct > 0)
                    Flexible(
                      flex: (againstPct * 100).round().clamp(1, 100),
                      child: Container(color: context.zError),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.zSuccess,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_formatNumber(proposal.votesFor.toDouble())} ${isZh ? "支持" : "For"}',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 10,
                      color: context.zSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: ZeroSpacing.md),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.zError,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_formatNumber(proposal.votesAgainst.toDouble())} ${isZh ? "反对" : "Against"}',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 10,
                      color: context.zError,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    proposal.quorumReached
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 12,
                    color: proposal.quorumReached
                        ? context.zSuccess
                        : context.zTextTertiary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    proposal.quorumReached
                        ? (isZh ? '已达法定人数' : 'Quorum')
                        : (isZh ? '未达法定人数' : 'No Quorum'),
                    style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryTab() {
    final isZh = ZeroTheme.isZh(context);
    final totalUsd = _daoService.getTreasuryTotal();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.zAccent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.md,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        children: [
          ZeroCard(
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.lg,
              vertical: ZeroSpacing.md + 4,
            ),
            borderRadius: ZeroSpacing.cardRadius,
            child: Column(
              children: [
                Text(
                  isZh ? '国库总价值' : 'Total Treasury Value',
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 1.5,
                    color: context.zTextTertiary,
                  ),
                ),
                SizedBox(height: ZeroSpacing.xs),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      context.zAccent,
                      context.zCeladon,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _formatUsd(totalUsd),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -1.5,
                      color: context.zAccent,
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.md),
                SizedBox(
                  height: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: _treasury.map((asset) {
                        final pct = totalUsd > 0 ? asset.usdValue / totalUsd : 0.0;
                        final colors = [
                          const Color(0xFF6C5CE7),
                          const Color(0xFF0984E3),
                          const Color(0xFF00B894),
                          const Color(0xFFFDCB6E),
                          const Color(0xFFE17055),
                        ];
                        final idx = _treasury.indexOf(asset) % colors.length;
                        return Flexible(
                          flex: (pct * 100).round().clamp(1, 100),
                          child: Container(color: colors[idx]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: ZeroSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _treasury.map((asset) {
                    final colors = [
                      const Color(0xFF6C5CE7),
                      const Color(0xFF0984E3),
                      const Color(0xFF00B894),
                      const Color(0xFFFDCB6E),
                      const Color(0xFFE17055),
                    ];
                    final idx = _treasury.indexOf(asset) % colors.length;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors[idx],
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            asset.symbol,
                            style: ZeroTypography.caption(context).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: ZeroSpacing.md),
          ..._treasury.map((asset) => _buildTreasuryCard(asset, isZh, totalUsd)),
        ],
      ),
    );
  }

  Widget _buildTreasuryCard(TreasuryAsset asset, bool isZh, double totalUsd) {
    final pct = totalUsd > 0 ? (asset.usdValue / totalUsd * 100).toStringAsFixed(1) : '0.0';
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFF0984E3),
      const Color(0xFF00B894),
      const Color(0xFFFDCB6E),
      const Color(0xFFE17055),
    ];
    final idx = _treasury.indexOf(asset) % colors.length;
    final assetColor = colors[idx];

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    assetColor.withOpacity(0.25),
                    assetColor.withOpacity(0.08),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                asset.icon,
                style: TextStyle(fontSize: 22),
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        asset.name,
                        style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: assetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: assetColor.withOpacity(0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          asset.symbol,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: assetColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${asset.chain}',
                    style: ZeroTypography.caption(context).copyWith(
                      fontSize: 11,
                      color: context.zTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatBalance(asset.balance),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: context.zTextPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${_formatUsd(asset.usdValue)} ($pct%)',
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 11,
                    color: context.zTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final isZh = ZeroTheme.isZh(context);

    final sortedMembers = List<DaoMember>.from(_members);
    if (_memberSort == 'power') {
      sortedMembers.sort((a, b) => b.votingPower.compareTo(a.votingPower));
    } else {
      sortedMembers.sort((a, b) => a.joinDate.compareTo(b.joinDate));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.zAccent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.md,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: ZeroSpacing.md),
            child: Row(
              children: [
                _SortChip(
                  label: isZh ? '投票权重' : 'Voting Power',
                  isSelected: _memberSort == 'power',
                  onTap: () => setState(() => _memberSort = 'power'),
                ),
                SizedBox(width: ZeroSpacing.sm),
                _SortChip(
                  label: isZh ? '加入时间' : 'Join Date',
                  isSelected: _memberSort == 'date',
                  onTap: () => setState(() => _memberSort = 'date'),
                ),
              ],
            ),
          ),
          ...sortedMembers.map((member) => _buildMemberCard(member, isZh)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(DaoMember member, bool isZh) {
    final avatarColor = _avatarColorFor(member.did);
    final totalMembers = _members.fold(0.0, (s, m) => s + m.votingPower);
    final powerPct = totalMembers > 0
        ? (member.votingPower / totalMembers * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Row(
          children: [
            Container(
              width: ZeroSpacing.avatarMd,
              height: ZeroSpacing.avatarMd,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    member.did,
                    style: ZeroTypography.monoSmall(context).copyWith(fontSize: 10),
                  ),
                  SizedBox(height: ZeroSpacing.xs),
                  Row(
                    children: [
                      Text(
                        '${_formatNumber(member.zeroStaked)} ZERO',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                          color: context.zAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.md),
                      Text(
                        '$powerPct% ${isZh ? "权重" : "power"}',
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 11,
                          color: context.zTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${member.proposalsCreated} ${isZh ? "创建" : "created"}',
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 10,
                    color: context.zTextTertiary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${member.proposalsVoted} ${isZh ? "投票" : "voted"}',
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 10,
                    color: context.zTextTertiary,
                  ),
                ),
                SizedBox(height: ZeroSpacing.xs),
                Text(
                  isZh
                      ? '${member.joinDate.year}/${member.joinDate.month} 加入'
                      : 'Joined ${member.joinDate.month}/${member.joinDate.year}',
                  style: ZeroTypography.caption(context).copyWith(
                    fontSize: 10,
                    color: context.zTextDisabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(height: 4),
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.zAccent.withOpacity(0.1)
              : context.zSurfaceOverlay.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: isSelected
                ? context.zAccent.withOpacity(0.3)
                : context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? context.zAccent : context.zTextTertiary,
          ),
        ),
      ),
    );
  }
}