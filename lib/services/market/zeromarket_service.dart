import 'dart:math';

class MarketListing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String sellerId;
  final String sellerName;
  final String category;
  final List<String> images;
  final String condition;
  final String location;
  final DateTime createdAt;
  final String status;
  final int totalRatings;
  final double averageRating;

  const MarketListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.sellerId,
    required this.sellerName,
    required this.category,
    required this.images,
    required this.condition,
    required this.location,
    required this.createdAt,
    required this.status,
    required this.totalRatings,
    required this.averageRating,
  });
}

class MarketOrder {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final double price;
  final double escrowedZero;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? shippingAddress;
  final String? contactPhone;
  final String? contactEmail;
  final String deliveryMethod;
  final String? orderNote;

  const MarketOrder({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.price,
    required this.escrowedZero,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.shippingAddress,
    this.contactPhone,
    this.contactEmail,
    this.deliveryMethod = 'express',
    this.orderNote,
  });

  MarketOrder copyWith({
    String? status,
    DateTime? updatedAt,
    String? shippingAddress,
    String? contactPhone,
    String? contactEmail,
    String? deliveryMethod,
    String? orderNote,
  }) {
    return MarketOrder(
      id: id,
      listingId: listingId,
      buyerId: buyerId,
      buyerName: buyerName,
      price: price,
      escrowedZero: escrowedZero,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      orderNote: orderNote ?? this.orderNote,
    );
  }
}

class ZeroMarketService {
  static final ZeroMarketService _instance = ZeroMarketService._();
  factory ZeroMarketService() => _instance;
  ZeroMarketService._();

  final _random = Random();
  final List<MarketListing> _listings = [];
  final List<MarketOrder> _orders = [];
  final List<Map<String, String>> _savedAddresses = [];
  bool _seeded = false;

  static const categories = [
    'Electronics',
    'Fashion',
    'Collectibles',
    'Digital Goods',
    'Services',
    'Other',
  ];

  static const _conditions = ['New', 'Like New', 'Used'];

  static const _categoryEmojis = {
    'Electronics': '💻',
    'Fashion': '👕',
    'Collectibles': '💎',
    'Digital Goods': '🎵',
    'Services': '🔧',
    'Other': '📦',
  };

  static const _sellerNames = [
    'CryptoWhale',
    'SatoshiFan',
    'Web3Builder',
    'NFTCollector',
    'DeFiNinja',
    'ChainLinker',
    'VitalikFan',
    'MerkleTree',
  ];

  static const _locations = [
    'Global',
    'Asia Pacific',
    'Europe',
    'North America',
    'South America',
    'Africa',
    'Middle East',
  ];

  MarketListing createListing({
    required String title,
    required String description,
    required double price,
    required String sellerId,
    required String sellerName,
    required String category,
    List<String> images = const [],
    required String condition,
    required String location,
  }) {
    final listing = MarketListing(
      id: 'listing_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      title: title,
      description: description,
      price: price,
      sellerId: sellerId,
      sellerName: sellerName,
      category: category,
      images: images,
      condition: condition,
      location: location,
      createdAt: DateTime.now(),
      status: 'Active',
      totalRatings: 0,
      averageRating: 0.0,
    );
    _listings.insert(0, listing);
    return listing;
  }

  List<MarketListing> getListings({String? category, String? sortBy}) {
    var result = _listings.where((l) => l.status == 'Active').toList();

    if (category != null && category != 'All') {
      result = result.where((l) => l.category == category).toList();
    }

    switch (sortBy) {
      case 'priceLow':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceHigh':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }

  List<MarketListing> getMyListings(String sellerId) {
    return _listings.where((l) => l.sellerId == sellerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  MarketOrder placeOrder(
    String listingId,
    String buyerId,
    String buyerName, {
    String? shippingAddress,
    String? contactPhone,
    String? contactEmail,
    String deliveryMethod = 'express',
    String? orderNote,
  }) {
    final listingIndex = _listings.indexWhere((l) => l.id == listingId);
    if (listingIndex == -1) {
      throw Exception('Listing not found');
    }

    final listing = _listings[listingIndex];
    if (listing.status != 'Active') {
      throw Exception('Listing is no longer active');
    }

    _listings[listingIndex] = MarketListing(
      id: listing.id,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      category: listing.category,
      images: listing.images,
      condition: listing.condition,
      location: listing.location,
      createdAt: listing.createdAt,
      status: 'Sold',
      totalRatings: listing.totalRatings,
      averageRating: listing.averageRating,
    );

    final order = MarketOrder(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      listingId: listingId,
      buyerId: buyerId,
      buyerName: buyerName,
      price: listing.price,
      escrowedZero: listing.price,
      status: 'Locked',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      shippingAddress: shippingAddress,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      deliveryMethod: deliveryMethod,
      orderNote: orderNote,
    );
    _orders.add(order);
    return order;
  }

  List<MarketOrder> getMyOrders(String userId) {
    return _orders.where((o) => o.buyerId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<MarketOrder> getSoldOrders(String sellerId) {
    final sellerListingIds = _listings
        .where((l) => l.sellerId == sellerId)
        .map((l) => l.id)
        .toSet();
    return _orders.where((o) => sellerListingIds.contains(o.listingId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  MarketOrder? updateOrderStatus(String orderId, String status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return null;

    final now = DateTime.now();
    final updated = _orders[index].copyWith(status: status, updatedAt: now);
    _orders[index] = updated;
    return updated;
  }

  void cancelListing(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1 && _listings[index].status == 'Active') {
      final listing = _listings[index];
      _listings[index] = MarketListing(
        id: listing.id,
        title: listing.title,
        description: listing.description,
        price: listing.price,
        sellerId: listing.sellerId,
        sellerName: listing.sellerName,
        category: listing.category,
        images: listing.images,
        condition: listing.condition,
        location: listing.location,
        createdAt: listing.createdAt,
        status: 'Cancelled',
        totalRatings: listing.totalRatings,
        averageRating: listing.averageRating,
      );
    }
  }

  List<Map<String, String>> getSavedAddresses() {
    return List.unmodifiable(_savedAddresses);
  }

  void saveAddress(Map<String, String> address) {
    final existingIndex = _savedAddresses.indexWhere(
      (a) => a['id'] == address['id'],
    );
    if (existingIndex != -1) {
      _savedAddresses[existingIndex] = address;
    } else {
      _savedAddresses.add(address);
    }
  }

  void deleteAddress(int index) {
    if (index >= 0 && index < _savedAddresses.length) {
      _savedAddresses.removeAt(index);
    }
  }

  void seedDemoListings() {
    if (_seeded) return;
    _seeded = true;

    _savedAddresses.addAll([
      {
        'id': 'addr_demo_1',
        'name': '张三',
        'phone': '+86 138-0000-1234',
        'provinceCity': '浙江省 杭州市',
        'street': '西湖区文三路 478 号华星时代广场 12 楼',
        'postalCode': '310012',
        'isDefault': 'true',
      },
      {
        'id': 'addr_demo_2',
        'name': 'John Doe',
        'phone': '+1 415-555-0198',
        'provinceCity': 'California, San Francisco',
        'street': '1234 Market Street, Suite 500',
        'postalCode': '94102',
        'isDefault': 'false',
      },
    ]);

    final demos = [
      {
        'title': 'Ledger Nano X Hardware Wallet',
        'description': 'Brand new Ledger Nano X. Securely store your BTC, ETH, and 5500+ tokens. Bluetooth enabled. Includes original box and cable.',
        'price': 240.0,
        'category': 'Electronics',
        'emoji': '🔐',
        'condition': 'New',
        'seller': 'CryptoWhale',
        'location': 'North America',
        'ratings': 156,
        'avgRating': 4.8,
      },
      {
        'title': 'Raspberry Pi 5 Mining Rig Kit',
        'description': 'Complete Raspberry Pi 5 kit for lightweight crypto node operation. 8GB RAM, 128GB SSD, pre-configured with Umbrel OS.',
        'price': 180.0,
        'category': 'Electronics',
        'emoji': '🥧',
        'condition': 'New',
        'seller': 'MerkleTree',
        'location': 'Europe',
        'ratings': 89,
        'avgRating': 4.6,
      },
      {
        'title': 'Bitcoin Logo Premium Hoodie',
        'description': 'Limited edition Bitcoin hoodie. High quality cotton, embroidered logo. Size L. Never worn.',
        'price': 90.0,
        'category': 'Fashion',
        'emoji': '🧥',
        'condition': 'New',
        'seller': 'SatoshiFan',
        'location': 'Global',
        'ratings': 234,
        'avgRating': 4.9,
      },
      {
        'title': 'Ethereum Merge Commemorative T-Shirt',
        'description': 'Official Ethereum Merge commemorative tee. Proof of Stake design. Size XL. Limited edition.',
        'price': 60.0,
        'category': 'Fashion',
        'emoji': '👕',
        'condition': 'New',
        'seller': 'VitalikFan',
        'location': 'Asia Pacific',
        'ratings': 67,
        'avgRating': 4.5,
      },
      {
        'title': 'Physical Bitcoin 2013 Casascius Coin',
        'description': 'Rare 2013 Casascius physical Bitcoin. 1 BTC denomination, brass construction. Collector condition. Unfunded replica.',
        'price': 400.0,
        'category': 'Collectibles',
        'emoji': '🪙',
        'condition': 'Like New',
        'seller': 'SatoshiFan',
        'location': 'Global',
        'ratings': 312,
        'avgRating': 4.9,
      },
      {
        'title': 'Rare CryptoPunk Postcard Set',
        'description': 'Complete set of 10 CryptoPunk art postcards. High quality print, limited edition #42/100. Mint condition.',
        'price': 150.0,
        'category': 'Collectibles',
        'emoji': '🎴',
        'condition': 'Like New',
        'seller': 'NFTCollector',
        'location': 'Europe',
        'ratings': 178,
        'avgRating': 4.7,
      },
      {
        'title': 'Premium VPN Subscription 1 Year',
        'description': '1 year of premium VPN service. No logs, WireGuard protocol, 100+ servers worldwide. Instant delivery.',
        'price': 48.0,
        'category': 'Digital Goods',
        'emoji': '🔒',
        'condition': 'New',
        'seller': 'Web3Builder',
        'location': 'Global',
        'ratings': 445,
        'avgRating': 4.8,
      },
      {
        'title': 'Smart Contract Audit Report Template',
        'description': 'Professional Solidity smart contract audit report template. Includes checklist, vulnerability database, and formatting guide.',
        'price': 120.0,
        'category': 'Digital Goods',
        'emoji': '📋',
        'condition': 'New',
        'seller': 'DeFiNinja',
        'location': 'Global',
        'ratings': 93,
        'avgRating': 4.4,
      },
      {
        'title': 'Smart Contract Development Service',
        'description': 'Custom ERC-20 / ERC-721 smart contract development. Includes testing, deployment script, and 30-day support.',
        'price': 500.0,
        'category': 'Services',
        'emoji': '⚙️',
        'condition': 'New',
        'seller': 'DeFiNinja',
        'location': 'Global',
        'ratings': 67,
        'avgRating': 4.9,
      },
      {
        'title': 'Crypto Tax Consultation 1 Hour',
        'description': 'Professional crypto tax consultation. Covers DeFi, staking rewards, airdrops, and cross-border compliance.',
        'price': 200.0,
        'category': 'Services',
        'emoji': '🧾',
        'condition': 'New',
        'seller': 'ChainLinker',
        'location': 'North America',
        'ratings': 34,
        'avgRating': 4.3,
      },
      {
        'title': 'Custom Mechanical Keyboard',
        'description': 'Custom built mechanical keyboard with Cherry MX Blue switches. Aluminum case, RGB backlit. Crypto-themed keycaps.',
        'price': 280.0,
        'category': 'Other',
        'emoji': '⌨️',
        'condition': 'Used',
        'seller': 'CryptoWhale',
        'location': 'Asia Pacific',
        'ratings': 45,
        'avgRating': 4.6,
      },
      {
        'title': 'Solana Saga Phone',
        'description': 'Solana Saga Web3 mobile phone. 512GB storage, Seed Vault, dApp Store. Excellent condition with original box.',
        'price': 350.0,
        'category': 'Electronics',
        'emoji': '📱',
        'condition': 'Like New',
        'seller': 'Web3Builder',
        'location': 'South America',
        'ratings': 89,
        'avgRating': 4.5,
      },
    ];

    for (var i = 0; i < demos.length; i++) {
      final d = demos[i];
      final daysAgo = _random.nextInt(30);
      final listing = MarketListing(
        id: 'demo_${i + 1}',
        title: d['title'] as String,
        description: d['description'] as String,
        price: (d['price'] as num).toDouble(),
        sellerId: 'did:zero:${d['seller'].toString().toLowerCase()}',
        sellerName: d['seller'] as String,
        category: d['category'] as String,
        images: [d['emoji'] as String],
        condition: d['condition'] as String,
        location: d['location'] as String,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
        status: 'Active',
        totalRatings: d['ratings'] as int,
        averageRating: (d['avgRating'] as num).toDouble(),
      );
      _listings.add(listing);
    }
  }

  double get zeroUsdRate => 0.50;

  static String getCategoryEmoji(String category) {
    return _categoryEmojis[category] ?? '📦';
  }
}