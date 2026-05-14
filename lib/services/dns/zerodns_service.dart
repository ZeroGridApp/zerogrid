class ZeroDomain {
  final String name;
  final String owner;
  final DateTime registeredAt;
  final DateTime expiresAt;
  final Map<String, String> resolution;
  final bool isPremium;
  final int price;

  const ZeroDomain({
    required this.name,
    required this.owner,
    required this.registeredAt,
    required this.expiresAt,
    required this.resolution,
    required this.isPremium,
    required this.price,
  });

  ZeroDomain copyWith({
    String? name,
    String? owner,
    DateTime? registeredAt,
    DateTime? expiresAt,
    Map<String, String>? resolution,
    bool? isPremium,
    int? price,
  }) {
    return ZeroDomain(
      name: name ?? this.name,
      owner: owner ?? this.owner,
      registeredAt: registeredAt ?? this.registeredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      resolution: resolution ?? this.resolution,
      isPremium: isPremium ?? this.isPremium,
      price: price ?? this.price,
    );
  }
}

class _DomainPrice {
  final bool isPremium;
  final int price;

  const _DomainPrice({required this.isPremium, required this.price});
}

class ZeroDNSService {
  factory ZeroDNSService() => _instance;
  ZeroDNSService._internal();
  static final ZeroDNSService _instance = ZeroDNSService._internal();

  final Map<String, ZeroDomain> _registry = {};

  static _DomainPrice _priceForName(String name) {
    final len = name.length;
    if (len >= 4) return const _DomainPrice(isPremium: false, price: 10);
    if (len == 3) return const _DomainPrice(isPremium: true, price: 100);
    if (len == 2) return const _DomainPrice(isPremium: true, price: 500);
    return const _DomainPrice(isPremium: true, price: 1000);
  }

  bool checkAvailability(String name) {
    return !_registry.containsKey(name.toLowerCase());
  }

  _DomainPrice getPriceInfo(String name) {
    return _priceForName(name);
  }

  ZeroDomain registerDomain(String name, String ownerId) {
    final lower = name.toLowerCase();
    if (_registry.containsKey(lower)) {
      throw Exception('Domain $name.zero is already registered');
    }
    final priceInfo = _priceForName(lower);
    final now = DateTime.now();
    final domain = ZeroDomain(
      name: lower,
      owner: ownerId,
      registeredAt: now,
      expiresAt: now.add(const Duration(days: 730)),
      resolution: {'zeroId': ownerId},
      isPremium: priceInfo.isPremium,
      price: priceInfo.price,
    );
    _registry[lower] = domain;
    return domain;
  }

  ZeroDomain? resolveDomain(String name) {
    return _registry[name.toLowerCase()];
  }

  List<ZeroDomain> getMyDomains(String ownerId) {
    return _registry.values
        .where((d) => d.owner == ownerId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  ZeroDomain transferDomain(String name, String newOwnerId) {
    final lower = name.toLowerCase();
    final domain = _registry[lower];
    if (domain == null) {
      throw Exception('Domain $name.zero not found');
    }
    final updated = domain.copyWith(owner: newOwnerId);
    _registry[lower] = updated;
    return updated;
  }

  void deleteDomain(String name) {
    _registry.remove(name.toLowerCase());
  }

  void seedDemoDomains() {
    final demoDomains = [
      'alice', 'bob', 'crypto', 'defi',
      'nft', 'web3', 'satoshi', 'vitalik',
    ];
    final now = DateTime.now();
    for (final name in demoDomains) {
      final priceInfo = _priceForName(name);
      _registry[name] = ZeroDomain(
        name: name,
        owner: 'Z${name.hashCode.abs().toString().substring(0, 8)}',
        registeredAt: now.subtract(Duration(days: name.hashCode.abs() % 365)),
        expiresAt: now.add(const Duration(days: 730)),
        resolution: {'zeroId': 'Z${name.hashCode.abs().toString().substring(0, 8)}'},
        isPremium: priceInfo.isPremium,
        price: priceInfo.price,
      );
    }
  }
}