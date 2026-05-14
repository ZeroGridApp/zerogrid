class ZeroTokenomics {
  ZeroTokenomics._();

  static const double totalSupply = 1000000000.0;
  static const double initialPrice = 0.01;
  static const double currentPrice = 0.50;

  static const double communityRewards = 0.30;
  static const double ecosystemFund = 0.20;
  static const double teamAdvisors = 0.15;
  static const double investors = 0.12;
  static const double development = 0.10;
  static const double reserve = 0.08;
  static const double liquidity = 0.05;

  static const double totalBurned = 2500000.0;
  static const double burnRate = 0.001;

  static double lockedTokens = 300000000.0;

  static double get circulatingSupply =>
      totalSupply - totalBurned - lockedTokens;

  static double get marketCap => circulatingSupply * currentPrice;
  static double get fullyDilutedValue => totalSupply * currentPrice;

  static const double totalStaked = 150000000.0;
  static const double stakingAPY = 8.5;
  static const double minStake = 1000.0;

  static const List<double> stakingTiers = [1000, 5000, 10000, 50000, 100000];
  static const List<double> stakingAPYs = [5.0, 7.0, 8.5, 10.0, 12.0];

  static const double annualBurnRate = 0.05;

  static double projectedSupply(int years) {
    double supply = circulatingSupply;
    for (int i = 0; i < years; i++) {
      supply *= (1 - annualBurnRate);
    }
    return supply;
  }

  static double projectedPrice(int years) {
    double supply = projectedSupply(years);
    double ratio = circulatingSupply / supply;
    return (currentPrice * ratio).clamp(0.01, double.infinity);
  }

  static const Map<String, double> distributionShares = {
    'communityRewards': communityRewards,
    'ecosystemFund': ecosystemFund,
    'teamAdvisors': teamAdvisors,
    'investors': investors,
    'development': development,
    'reserve': reserve,
    'liquidity': liquidity,
  };
}

class StakingCalculator {
  StakingCalculator._();

  static double calculateRewards(double amount, int days) {
    final apy = getTierAPY(amount);
    return amount * (apy / 100) * (days / 365.0);
  }

  static double getTierAPY(double amount) {
    double apy = 5.0;
    for (int i = 0; i < ZeroTokenomics.stakingTiers.length; i++) {
      if (amount >= ZeroTokenomics.stakingTiers[i]) {
        apy = ZeroTokenomics.stakingAPYs[i];
      }
    }
    return apy;
  }

  static int getTierLevel(double amount) {
    int tier = 1;
    for (int i = 0; i < ZeroTokenomics.stakingTiers.length; i++) {
      if (amount >= ZeroTokenomics.stakingTiers[i]) tier = i + 1;
    }
    return tier;
  }

  static String getTierLabel(int tier) {
    switch (tier) {
      case 1: return 'Bronze';
      case 2: return 'Silver';
      case 3: return 'Gold';
      case 4: return 'Platinum';
      case 5: return 'Diamond';
      default: return 'N/A';
    }
  }

  static String getTierLabelZh(int tier) {
    switch (tier) {
      case 1: return '青铜';
      case 2: return '白银';
      case 3: return '黄金';
      case 4: return '铂金';
      case 5: return '钻石';
      default: return '未知';
    }
  }

  static Map<String, double> calculateRewardSchedule(double amount, int days) {
    final apy = getTierAPY(amount);
    final total = calculateRewards(amount, days);
    return {
      'daily': total / days,
      'weekly': total / (days / 7),
      'monthly': total / (days / 30),
      'yearly': amount * (apy / 100),
    };
  }
}

class GasEstimator {
  GasEstimator._();

  static const Map<String, GasConfig> chainConfigs = {
    'eth': GasConfig(
      name: 'Ethereum',
      avgGwei: 15,
      usdPerTx: 2.50,
      zeroPerTx: 5.0,
      nativeSymbol: 'ETH',
    ),
    'bsc': GasConfig(
      name: 'BSC',
      avgGwei: 3,
      usdPerTx: 0.15,
      zeroPerTx: 0.3,
      nativeSymbol: 'BNB',
    ),
    'sol': GasConfig(
      name: 'Solana',
      avgGwei: 0,
      usdPerTx: 0.0002,
      zeroPerTx: 0.0004,
      nativeSymbol: 'SOL',
    ),
    'trx': GasConfig(
      name: 'TRON',
      avgGwei: 0,
      usdPerTx: 0.10,
      zeroPerTx: 0.2,
      nativeSymbol: 'TRX',
    ),
    'btc': GasConfig(
      name: 'Bitcoin',
      avgGwei: 0,
      usdPerTx: 3.50,
      zeroPerTx: 7.0,
      nativeSymbol: 'BTC',
    ),
  };

  static double estimateGasFee(String chainId, String txType) {
    final config = chainConfigs[chainId];
    if (config == null) return 0;
    double base = config.zeroPerTx;
    switch (txType) {
      case 'swap':
        return base * 2.5;
      case 'nft':
        return base * 3.0;
      case 'bridge':
        return base * 5.0;
      default:
        return base;
    }
  }

  static double estimateBatchCost(int operations) {
    return operations * 0.0004;
  }

  static double getSavingsPercent(String chainId) {
    final config = chainConfigs[chainId];
    if (config == null) return 0;
    if (config.zeroPerTx >= config.usdPerTx) return 0;
    return ((config.usdPerTx - config.zeroPerTx) / config.usdPerTx * 100);
  }
}

class GasConfig {
  final String name;
  final int avgGwei;
  final double usdPerTx;
  final double zeroPerTx;
  final String nativeSymbol;

  const GasConfig({
    required this.name,
    required this.avgGwei,
    required this.usdPerTx,
    required this.zeroPerTx,
    required this.nativeSymbol,
  });
}

class TokenomicsFormatter {
  TokenomicsFormatter._();

  static String formatZero(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(2)}B';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }

  static String formatUsd(double amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(2)}B';
    }
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(4)}';
  }

  static String formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatDays(int days) {
    if (days >= 365) {
      final years = days ~/ 365;
      final remaining = days % 365;
      if (remaining == 0) return '${years}Y';
      return '${years}Y ${remaining}D';
    }
    if (days >= 30) {
      final months = days ~/ 30;
      return '${months}M';
    }
    return '${days}D';
  }
}