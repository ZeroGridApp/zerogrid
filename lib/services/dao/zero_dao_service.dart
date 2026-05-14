class DaoProposal {
  final String id;
  final String title;
  final String description;
  final String proposerName;
  final String proposerDid;
  final String category;
  final String status;
  int votesFor;
  int votesAgainst;
  int votesAbstain;
  final double totalZeroStaked;
  final double quorum;
  final DateTime createdAt;
  final DateTime endTime;
  final String? executionData;

  DaoProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.proposerName,
    required this.proposerDid,
    required this.category,
    required this.status,
    required this.votesFor,
    required this.votesAgainst,
    required this.votesAbstain,
    required this.totalZeroStaked,
    this.quorum = 0.15,
    required this.createdAt,
    required this.endTime,
    this.executionData,
  });

  int get totalVotes => votesFor + votesAgainst + votesAbstain;
  double get turnout => totalZeroStaked > 0 ? totalVotes / totalZeroStaked : 0;
  bool get quorumReached => turnout >= quorum;
  double get forRatio => totalVotes > 0 ? votesFor / totalVotes : 0;
  double get againstRatio => totalVotes > 0 ? votesAgainst / totalVotes : 0;
  double get abstainRatio => totalVotes > 0 ? votesAbstain / totalVotes : 0;
  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get isActive => status == 'Active' && timeRemaining.inSeconds > 0;
}

class DaoVote {
  final String proposalId;
  final String voterDid;
  final String voterName;
  final String choice;
  final double votingPower;
  final DateTime timestamp;

  const DaoVote({
    required this.proposalId,
    required this.voterDid,
    required this.voterName,
    required this.choice,
    required this.votingPower,
    required this.timestamp,
  });
}

class TreasuryAsset {
  final String id;
  final String name;
  final String symbol;
  final double balance;
  final double usdValue;
  final String chain;
  final String icon;

  const TreasuryAsset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.balance,
    required this.usdValue,
    required this.chain,
    required this.icon,
  });
}

class DaoMember {
  final String did;
  final String name;
  final double zeroStaked;
  final double votingPower;
  final int proposalsCreated;
  final int proposalsVoted;
  final DateTime joinDate;

  const DaoMember({
    required this.did,
    required this.name,
    required this.zeroStaked,
    required this.votingPower,
    required this.proposalsCreated,
    required this.proposalsVoted,
    required this.joinDate,
  });
}

class ZeroDAOService {
  ZeroDAOService._();
  static final ZeroDAOService _instance = ZeroDAOService._();
  factory ZeroDAOService() => _instance;

  final List<DaoProposal> _proposals = [];
  final List<DaoVote> _votes = [];
  final List<TreasuryAsset> _treasury = [];
  final List<DaoMember> _members = [];
  bool _seeded = false;

  List<DaoProposal> getProposals() {
    _ensureSeeded();
    return List.unmodifiable(_proposals);
  }

  List<DaoProposal> getActiveProposals() {
    _ensureSeeded();
    return _proposals.where((p) => p.isActive).toList();
  }

  DaoProposal createProposal(
    String title,
    String description,
    String category,
    String proposerDid,
    String proposerName,
  ) {
    _ensureSeeded();
    final now = DateTime.now();
    final id = 'prop_${now.millisecondsSinceEpoch}';
    final proposal = DaoProposal(
      id: id,
      title: title,
      description: description,
      proposerName: proposerName,
      proposerDid: proposerDid,
      category: category,
      status: 'Active',
      votesFor: 0,
      votesAgainst: 0,
      votesAbstain: 0,
      totalZeroStaked: 1250000,
      createdAt: now,
      endTime: now.add(const Duration(days: 7)),
    );
    _proposals.insert(0, proposal);

    final memberIndex = _members.indexWhere((m) => m.did == proposerDid);
    if (memberIndex != -1) {
      final old = _members[memberIndex];
      _members[memberIndex] = DaoMember(
        did: old.did,
        name: old.name,
        zeroStaked: old.zeroStaked,
        votingPower: old.votingPower,
        proposalsCreated: old.proposalsCreated + 1,
        proposalsVoted: old.proposalsVoted,
        joinDate: old.joinDate,
      );
    }

    return proposal;
  }

  DaoVote vote(
    String proposalId,
    String voterDid,
    String voterName,
    String choice,
    double votingPower,
  ) {
    _ensureSeeded();
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index == -1) {
      throw ArgumentError('Proposal not found: $proposalId');
    }

    _votes.removeWhere((v) => v.proposalId == proposalId && v.voterDid == voterDid);

    final vote = DaoVote(
      proposalId: proposalId,
      voterDid: voterDid,
      voterName: voterName,
      choice: choice,
      votingPower: votingPower,
      timestamp: DateTime.now(),
    );
    _votes.add(vote);

    final p = _proposals[index];
    switch (choice) {
      case 'for':
        p.votesFor += 1;
        break;
      case 'against':
        p.votesAgainst += 1;
        break;
      case 'abstain':
        p.votesAbstain += 1;
        break;
    }

    if (p.quorumReached && p.status == 'Active') {
      if (p.forRatio > 0.5) {
        _proposals[index] = DaoProposal(
          id: p.id,
          title: p.title,
          description: p.description,
          proposerName: p.proposerName,
          proposerDid: p.proposerDid,
          category: p.category,
          status: 'Passed',
          votesFor: p.votesFor,
          votesAgainst: p.votesAgainst,
          votesAbstain: p.votesAbstain,
          totalZeroStaked: p.totalZeroStaked,
          quorum: p.quorum,
          createdAt: p.createdAt,
          endTime: p.endTime,
          executionData: p.executionData,
        );
      } else {
        _proposals[index] = DaoProposal(
          id: p.id,
          title: p.title,
          description: p.description,
          proposerName: p.proposerName,
          proposerDid: p.proposerDid,
          category: p.category,
          status: 'Rejected',
          votesFor: p.votesFor,
          votesAgainst: p.votesAgainst,
          votesAbstain: p.votesAbstain,
          totalZeroStaked: p.totalZeroStaked,
          quorum: p.quorum,
          createdAt: p.createdAt,
          endTime: p.endTime,
          executionData: p.executionData,
        );
      }
    }

    final memberIndex = _members.indexWhere((m) => m.did == voterDid);
    if (memberIndex != -1) {
      final old = _members[memberIndex];
      _members[memberIndex] = DaoMember(
        did: old.did,
        name: old.name,
        zeroStaked: old.zeroStaked,
        votingPower: old.votingPower,
        proposalsCreated: old.proposalsCreated,
        proposalsVoted: old.proposalsVoted + 1,
        joinDate: old.joinDate,
      );
    }

    return vote;
  }

  List<DaoVote> getUserVotes(String voterDid) {
    _ensureSeeded();
    return _votes.where((v) => v.voterDid == voterDid).toList();
  }

  List<TreasuryAsset> getTreasury() {
    _ensureSeeded();
    return List.unmodifiable(_treasury);
  }

  double getTreasuryTotal() {
    _ensureSeeded();
    return _treasury.fold(0.0, (sum, a) => sum + a.usdValue);
  }

  List<DaoMember> getMembers() {
    _ensureSeeded();
    return List.unmodifiable(_members);
  }

  bool calculateQuorum(String proposalId) {
    _ensureSeeded();
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index == -1) return false;
    return _proposals[index].quorumReached;
  }

  void seedDaoData() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();

    _proposals.addAll([
      DaoProposal(
        id: 'prop_1',
        title: 'Zero Protocol v2.0 Upgrade',
        description:
            '升级 Zero Protocol 到 v2.0 版本，引入新的共识机制 ZeroBFT，提升网络吞吐量至 10,000 TPS。同时优化链上存储方案，降低节点运行成本约 40%。该升级将采用硬分叉方式，需要所有节点在区块高度 1,500,000 之前完成升级。技术团队已完成 6 个月的内部测试和 3 轮安全审计，由 Trail of Bits 和 CertiK 联合审计。',
        proposerName: 'ZeroCore Team',
        proposerDid: 'Z0C4R3T7EM',
        category: 'Protocol',
        status: 'Active',
        votesFor: 187500,
        votesAgainst: 23400,
        votesAbstain: 12100,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 2)),
        endTime: now.add(const Duration(days: 5)),
        executionData: '0x7b3f...upgrade_v2',
      ),
      DaoProposal(
        id: 'prop_2',
        title: 'Community Fund Allocation Q2',
        description:
            'Q2 季度社区基金分配方案：开发者激励计划 35%（含核心协议开发和生态工具建设），社区活动与教育 25%（含全球 12 场线下黑客松和线上技术课程），安全审计预算 20%（含第三方审计和漏洞赏金计划），市场推广 15%，应急储备 5%。总计拨款 2,500,000 ZERO。申请团队需提交详细的路演报告。',
        proposerName: 'DAO Council',
        proposerDid: 'Z5D2A9O4CL',
        category: 'Funding',
        status: 'Active',
        votesFor: 148000,
        votesAgainst: 89000,
        votesAbstain: 31000,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 3)),
        endTime: now.add(const Duration(days: 4)),
        executionData: '0x4a2d...fund_q2',
      ),
      DaoProposal(
        id: 'prop_3',
        title: 'Integrate Solana Chain Support',
        description:
            '为 Zero 生态添加 Solana 链支持，允许用户在 Zero Wallet 中管理 SOL 和 SPL 代币，支持 Solana 生态 DApp 接入 ZeroPay 支付网络。技术方案包括：部署 Solana RPC 节点集群，实现跨链桥接合约（Wormhole 集成），开发 Solana 适配器层。预计开发周期 3 个月，预算 1,200,000 ZERO。',
        proposerName: 'Bridge Builder',
        proposerDid: 'Z7B2R5I1DG',
        category: 'Ecosystem',
        status: 'Active',
        votesFor: 210000,
        votesAgainst: 45000,
        votesAbstain: 18000,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 6)),
        executionData: '0x3f81...sol_integration',
      ),
      DaoProposal(
        id: 'prop_4',
        title: 'Marketing Budget 2026',
        description:
            '2026 年度市场推广预算提案：品牌建设与合作 30%（顶级 Web3 会议赞助、KOL 合作矩阵），内容创作与社区建设 25%（多语言内容团队、社区大使计划），开发者关系 25%（开发者文档升级、SDK 推广、技术博客），绩效广告与增长 20%。总预算 3,800,000 ZERO，预期带来 50 万新增活跃用户和 200 个生态项目接入。',
        proposerName: 'Growth Guild',
        proposerDid: 'Z3G9R5W7TH',
        category: 'Funding',
        status: 'Passed',
        votesFor: 310000,
        votesAgainst: 67000,
        votesAbstain: 43000,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 15)),
        endTime: now.subtract(const Duration(days: 8)),
        executionData: '0x8c12...marketing_2026',
      ),
      DaoProposal(
        id: 'prop_5',
        title: 'Governance Parameter Adjustment',
        description:
            '调整治理参数：将提案创建阈值从 10,000 ZERO 降低至 5,000 ZERO，将法定人数从 15% 调整至 12%，将投票周期从 7 天延长至 10 天。此调整旨在降低治理参与门槛，鼓励更多社区成员积极参与 DAO 治理。数据表明当前 15% 的法定人数在非热门提案中难以达成，导致提案积压。',
        proposerName: 'Governance WG',
        proposerDid: 'Z6G4V3N1WG',
        category: 'Governance',
        status: 'Rejected',
        votesFor: 98000,
        votesAgainst: 156000,
        votesAbstain: 24000,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 20)),
        endTime: now.subtract(const Duration(days: 13)),
        executionData: null,
      ),
      DaoProposal(
        id: 'prop_6',
        title: 'ZeroAI Integration Phase 1',
        description:
            '将 AI 能力深度整合到 Zero 生态中：AI 驱动的链上数据分析面板、智能合约自动审计助手、自然语言交互的区块链浏览器、AI 优化路由算法。技术架构采用去中心化推理网络，由社区节点提供算力。第一阶段预算 2,000,000 ZERO，开发周期 4 个月。已与三个 AI 研究团队达成合作意向。',
        proposerName: 'AI Guild',
        proposerDid: 'Z1A4I9G2LD',
        category: 'Ecosystem',
        status: 'Executed',
        votesFor: 356000,
        votesAgainst: 21000,
        votesAbstain: 15000,
        totalZeroStaked: 1250000,
        createdAt: now.subtract(const Duration(days: 40)),
        endTime: now.subtract(const Duration(days: 33)),
        executionData: '0xa1b2...zeroai_phase1',
      ),
    ]);

    _treasury.addAll([
      const TreasuryAsset(
        id: 'treasury_1',
        name: 'Zero Ecosystem Token',
        symbol: 'ZERO',
        balance: 8520000,
        usdValue: 12780000,
        chain: 'ZeroChain',
        icon: '🏦',
      ),
      const TreasuryAsset(
        id: 'treasury_2',
        name: 'Ethereum',
        symbol: 'ETH',
        balance: 1250,
        usdValue: 3750000,
        chain: 'Ethereum',
        icon: '💎',
      ),
      const TreasuryAsset(
        id: 'treasury_3',
        name: 'Tether USD',
        symbol: 'USDT',
        balance: 2800000,
        usdValue: 2800000,
        chain: 'Ethereum',
        icon: '💵',
      ),
      const TreasuryAsset(
        id: 'treasury_4',
        name: 'Bitcoin',
        symbol: 'BTC',
        balance: 32.5,
        usdValue: 2112500,
        chain: 'Bitcoin',
        icon: '🪙',
      ),
      const TreasuryAsset(
        id: 'treasury_5',
        name: 'Solana',
        symbol: 'SOL',
        balance: 8400,
        usdValue: 1260000,
        chain: 'Solana',
        icon: '☀️',
      ),
    ]);

    _members.addAll([
      DaoMember(
        did: 'Z0C4R3T7EM',
        name: 'ZeroCore Team',
        zeroStaked: 250000,
        votingPower: 250000,
        proposalsCreated: 5,
        proposalsVoted: 12,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z5D2A9O4CL',
        name: 'DAO Council',
        zeroStaked: 180000,
        votingPower: 180000,
        proposalsCreated: 8,
        proposalsVoted: 20,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z7B2R5I1DG',
        name: 'Bridge Builder',
        zeroStaked: 120000,
        votingPower: 120000,
        proposalsCreated: 3,
        proposalsVoted: 15,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z3G9R5W7TH',
        name: 'Growth Guild',
        zeroStaked: 95000,
        votingPower: 95000,
        proposalsCreated: 4,
        proposalsVoted: 11,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z6G4V3N1WG',
        name: 'Governance WG',
        zeroStaked: 160000,
        votingPower: 160000,
        proposalsCreated: 6,
        proposalsVoted: 18,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z1A4I9G2LD',
        name: 'AI Guild',
        zeroStaked: 135000,
        votingPower: 135000,
        proposalsCreated: 2,
        proposalsVoted: 9,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z8P2K5W1RT',
        name: 'Alice Validator',
        zeroStaked: 210000,
        votingPower: 210000,
        proposalsCreated: 0,
        proposalsVoted: 7,
        joinDate: DateTime(2025, 3, 1),
      ),
      DaoMember(
        did: 'Z4N7M3T6HS',
        name: 'Bob Delegate',
        zeroStaked: 88000,
        votingPower: 88000,
        proposalsCreated: 1,
        proposalsVoted: 14,
        joinDate: DateTime(2025, 3, 1),
      ),
    ]);

    final baseDate = DateTime(2024, 6, 1);
    for (var i = 0; i < _members.length; i++) {
      final old = _members[i];
      _members[i] = DaoMember(
        did: old.did,
        name: old.name,
        zeroStaked: old.zeroStaked,
        votingPower: old.votingPower,
        proposalsCreated: old.proposalsCreated,
        proposalsVoted: old.proposalsVoted,
        joinDate: baseDate.add(Duration(days: i * 45)),
      );
    }

    _votes.addAll([
      DaoVote(
        proposalId: 'prop_1',
        voterDid: 'Z0C4R3T7EM',
        voterName: 'ZeroCore Team',
        choice: 'for',
        votingPower: 80000,
        timestamp: now.subtract(const Duration(days: 1, hours: 12)),
      ),
      DaoVote(
        proposalId: 'prop_1',
        voterDid: 'Z5D2A9O4CL',
        voterName: 'DAO Council',
        choice: 'for',
        votingPower: 60000,
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      DaoVote(
        proposalId: 'prop_1',
        voterDid: 'Z8P2K5W1RT',
        voterName: 'Alice Validator',
        choice: 'for',
        votingPower: 47500,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      DaoVote(
        proposalId: 'prop_1',
        voterDid: 'Z4N7M3T6HS',
        voterName: 'Bob Delegate',
        choice: 'against',
        votingPower: 23400,
        timestamp: now.subtract(const Duration(hours: 20)),
      ),
      DaoVote(
        proposalId: 'prop_2',
        voterDid: 'Z5D2A9O4CL',
        voterName: 'DAO Council',
        choice: 'for',
        votingPower: 60000,
        timestamp: now.subtract(const Duration(days: 2, hours: 15)),
      ),
      DaoVote(
        proposalId: 'prop_2',
        voterDid: 'Z8P2K5W1RT',
        voterName: 'Alice Validator',
        choice: 'for',
        votingPower: 50000,
        timestamp: now.subtract(const Duration(days: 2, hours: 6)),
      ),
      DaoVote(
        proposalId: 'prop_2',
        voterDid: 'Z6G4V3N1WG',
        voterName: 'Governance WG',
        choice: 'against',
        votingPower: 45000,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      DaoVote(
        proposalId: 'prop_2',
        voterDid: 'Z7B2R5I1DG',
        voterName: 'Bridge Builder',
        choice: 'for',
        votingPower: 38000,
        timestamp: now.subtract(const Duration(days: 1, hours: 18)),
      ),
      DaoVote(
        proposalId: 'prop_3',
        voterDid: 'Z7B2R5I1DG',
        voterName: 'Bridge Builder',
        choice: 'for',
        votingPower: 60000,
        timestamp: now.subtract(const Duration(hours: 20)),
      ),
      DaoVote(
        proposalId: 'prop_3',
        voterDid: 'Z1A4I9G2LD',
        voterName: 'AI Guild',
        choice: 'for',
        votingPower: 50000,
        timestamp: now.subtract(const Duration(hours: 16)),
      ),
      DaoVote(
        proposalId: 'prop_3',
        voterDid: 'Z4N7M3T6HS',
        voterName: 'Bob Delegate',
        choice: 'for',
        votingPower: 35000,
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      DaoVote(
        proposalId: 'prop_3',
        voterDid: 'Z0C4R3T7EM',
        voterName: 'ZeroCore Team',
        choice: 'for',
        votingPower: 65000,
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      DaoVote(
        proposalId: 'prop_4',
        voterDid: 'Z3G9R5W7TH',
        voterName: 'Growth Guild',
        choice: 'for',
        votingPower: 50000,
        timestamp: now.subtract(const Duration(days: 14)),
      ),
      DaoVote(
        proposalId: 'prop_4',
        voterDid: 'Z5D2A9O4CL',
        voterName: 'DAO Council',
        choice: 'for',
        votingPower: 70000,
        timestamp: now.subtract(const Duration(days: 13)),
      ),
      DaoVote(
        proposalId: 'prop_4',
        voterDid: 'Z8P2K5W1RT',
        voterName: 'Alice Validator',
        choice: 'for',
        votingPower: 55000,
        timestamp: now.subtract(const Duration(days: 12)),
      ),
      DaoVote(
        proposalId: 'prop_4',
        voterDid: 'Z6G4V3N1WG',
        voterName: 'Governance WG',
        choice: 'against',
        votingPower: 35000,
        timestamp: now.subtract(const Duration(days: 11)),
      ),
      DaoVote(
        proposalId: 'prop_5',
        voterDid: 'Z6G4V3N1WG',
        voterName: 'Governance WG',
        choice: 'for',
        votingPower: 60000,
        timestamp: now.subtract(const Duration(days: 19)),
      ),
      DaoVote(
        proposalId: 'prop_5',
        voterDid: 'Z0C4R3T7EM',
        voterName: 'ZeroCore Team',
        choice: 'against',
        votingPower: 80000,
        timestamp: now.subtract(const Duration(days: 18)),
      ),
      DaoVote(
        proposalId: 'prop_5',
        voterDid: 'Z5D2A9O4CL',
        voterName: 'DAO Council',
        choice: 'against',
        votingPower: 55000,
        timestamp: now.subtract(const Duration(days: 17)),
      ),
      DaoVote(
        proposalId: 'prop_6',
        voterDid: 'Z1A4I9G2LD',
        voterName: 'AI Guild',
        choice: 'for',
        votingPower: 70000,
        timestamp: now.subtract(const Duration(days: 39)),
      ),
      DaoVote(
        proposalId: 'prop_6',
        voterDid: 'Z8P2K5W1RT',
        voterName: 'Alice Validator',
        choice: 'for',
        votingPower: 65000,
        timestamp: now.subtract(const Duration(days: 38)),
      ),
      DaoVote(
        proposalId: 'prop_6',
        voterDid: 'Z4N7M3T6HS',
        voterName: 'Bob Delegate',
        choice: 'for',
        votingPower: 48000,
        timestamp: now.subtract(const Duration(days: 37)),
      ),
    ]);
  }

  void _ensureSeeded() {
    if (!_seeded) {
      seedDaoData();
    }
  }
}