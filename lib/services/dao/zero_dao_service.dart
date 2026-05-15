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

  List<DaoProposal> getProposals() {
    return List.unmodifiable(_proposals);
  }

  List<DaoProposal> getActiveProposals() {
    return _proposals.where((p) => p.isActive).toList();
  }

  DaoProposal createProposal(
    String title,
    String description,
    String category,
    String proposerDid,
    String proposerName,
  ) {
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
    return _votes.where((v) => v.voterDid == voterDid).toList();
  }

  List<TreasuryAsset> getTreasury() {
    return List.unmodifiable(_treasury);
  }

  double getTreasuryTotal() {
    return _treasury.fold(0.0, (sum, a) => sum + a.usdValue);
  }

  List<DaoMember> getMembers() {
    return List.unmodifiable(_members);
  }

  bool calculateQuorum(String proposalId) {
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index == -1) return false;
    return _proposals[index].quorumReached;
  }
}