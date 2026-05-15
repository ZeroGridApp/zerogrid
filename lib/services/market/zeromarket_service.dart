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

  static String getCategoryEmoji(String category) {
    return _categoryEmojis[category] ?? '📦';
  }
}