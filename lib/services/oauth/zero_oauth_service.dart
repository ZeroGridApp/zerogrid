import 'dart:math';

class OAuthApp {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String website;
  final String redirectUrl;
  final String developerName;
  final bool verified;
  final int users;
  final DateTime connectedAt;

  OAuthApp({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.website,
    required this.redirectUrl,
    required this.developerName,
    required this.verified,
    required this.users,
    required this.connectedAt,
  });
}

class OAuthSession {
  final String id;
  final String appId;
  final String appName;
  final String userId;
  final String userDid;
  final String scope;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? authCode;
  final String? accessToken;

  const OAuthSession({
    required this.id,
    required this.appId,
    required this.appName,
    required this.userId,
    required this.userDid,
    required this.scope,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.authCode,
    this.accessToken,
  });

  OAuthSession copyWith({
    String? status,
    String? authCode,
    String? accessToken,
  }) {
    return OAuthSession(
      id: id,
      appId: appId,
      appName: appName,
      userId: userId,
      userDid: userDid,
      scope: scope,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      authCode: authCode ?? this.authCode,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}

class OAuthScope {
  final String name;
  final String key;
  final String description;
  final String icon;

  const OAuthScope({
    required this.name,
    required this.key,
    required this.description,
    required this.icon,
  });
}

class ZeroOAuthService {
  ZeroOAuthService._();

  static final ZeroOAuthService _instance = ZeroOAuthService._();

  factory ZeroOAuthService() => _instance;

  final List<OAuthApp> _availableApps = [];
  final List<OAuthSession> _sessions = [];

  static const scopes = [
    OAuthScope(
      name: 'Basic Profile',
      key: 'basic',
      description: 'Access your basic profile information',
      icon: '👤',
    ),
    OAuthScope(
      name: 'Contacts',
      key: 'contacts',
      description: 'Read your contact list',
      icon: '📇',
    ),
    OAuthScope(
      name: 'Wallet',
      key: 'wallet',
      description: 'View wallet balance and transaction history',
      icon: '💳',
    ),
    OAuthScope(
      name: 'Full Access',
      key: 'full',
      description: 'Full access to your ZeroID account',
      icon: '🔓',
    ),
  ];

  void seedOAuthData() {
    if (_availableApps.isNotEmpty) return;

    final now = DateTime.now();
    final rng = Random();

    _availableApps.addAll([
      OAuthApp(
        id: 'dshop',
        name: 'DShop',
        description: 'Decentralized e-commerce platform with ZeroID login',
        iconUrl: '🛒',
        website: 'https://dshop.zero',
        redirectUrl: 'https://dshop.zero/auth/callback',
        developerName: 'Zero Commerce Labs',
        verified: true,
        users: 28400,
        connectedAt: DateTime(1970),
      ),
      OAuthApp(
        id: 'cryptnote',
        name: 'CryptNote',
        description: 'End-to-end encrypted notes with ZeroID auth',
        iconUrl: '📝',
        website: 'https://cryptnote.zero',
        redirectUrl: 'https://cryptnote.zero/oauth/callback',
        developerName: 'PrivacyFirst Inc.',
        verified: true,
        users: 15600,
        connectedAt: DateTime(1970),
      ),
      OAuthApp(
        id: 'desocial',
        name: 'DeSocial',
        description: 'Decentralized social platform powered by ZeroID',
        iconUrl: '🌐',
        website: 'https://desocial.zero',
        redirectUrl: 'https://desocial.zero/auth/zero',
        developerName: 'DeSocial Foundation',
        verified: true,
        users: 42100,
        connectedAt: DateTime(1970),
      ),
      OAuthApp(
        id: 'zeropay_merchant',
        name: 'ZeroPay Merchant',
        description: 'Payment gateway for merchants using ZeroID',
        iconUrl: '💳',
        website: 'https://zeropay.zero/merchant',
        redirectUrl: 'https://zeropay.zero/merchant/callback',
        developerName: 'ZeroPay Labs',
        verified: false,
        users: 8900,
        connectedAt: DateTime(1970),
      ),
    ]);

    _sessions.addAll([
      OAuthSession(
        id: 'sess_001',
        appId: 'dshop',
        appName: 'DShop',
        userId: 'user_001',
        userDid: 'did:zero:ZA1B2C3D4E',
        scope: 'basic',
        status: 'approved',
        createdAt: now.subtract(const Duration(days: 30)),
        expiresAt: now.add(const Duration(days: 335)),
        authCode: 'ZAUTH_9X4K2M7P_R1',
        accessToken: 'zat_${_randomToken(rng)}',
      ),
      OAuthSession(
        id: 'sess_002',
        appId: 'desocial',
        appName: 'DeSocial',
        userId: 'user_001',
        userDid: 'did:zero:ZA1B2C3D4E',
        scope: 'contacts',
        status: 'approved',
        createdAt: now.subtract(const Duration(days: 14)),
        expiresAt: now.add(const Duration(days: 351)),
        authCode: 'ZAUTH_3F8K1L9Q_X2',
        accessToken: 'zat_${_randomToken(rng)}',
      ),
      OAuthSession(
        id: 'sess_003',
        appId: 'cryptnote',
        appName: 'CryptNote',
        userId: 'user_001',
        userDid: 'did:zero:ZA1B2C3D4E',
        scope: 'wallet',
        status: 'approved',
        createdAt: now.subtract(const Duration(days: 7)),
        expiresAt: now.add(const Duration(days: 358)),
        authCode: 'ZAUTH_7R2W5V8N_Y6',
        accessToken: 'zat_${_randomToken(rng)}',
      ),
      OAuthSession(
        id: 'sess_pending_001',
        appId: 'zeropay_merchant',
        appName: 'ZeroPay Merchant',
        userId: 'user_001',
        userDid: 'did:zero:ZA1B2C3D4E',
        scope: 'wallet',
        status: 'pending',
        createdAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(minutes: 55)),
        authCode: 'ZAUTH_2M9N4K7P_X1',
      ),
    ]);
  }

  static String _randomToken(Random rng) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  List<OAuthApp> getConnectedApps(String userDid) {
    final approvedSessionIds = _sessions
        .where((s) => s.userDid == userDid && s.status == 'approved')
        .map((s) => s.appId)
        .toSet();

    return _availableApps.where((app) => approvedSessionIds.contains(app.id)).map((app) {
      final session = _sessions.firstWhere(
        (s) => s.appId == app.id && s.userDid == userDid && s.status == 'approved',
        orElse: () => _sessions.first,
      );
      return OAuthApp(
        id: app.id,
        name: app.name,
        description: app.description,
        iconUrl: app.iconUrl,
        website: app.website,
        redirectUrl: app.redirectUrl,
        developerName: app.developerName,
        verified: app.verified,
        users: app.users,
        connectedAt: session.createdAt,
      );
    }).toList();
  }

  List<OAuthSession> getPendingAuthorizations() {
    return _sessions.where((s) => s.status == 'pending').toList();
  }

  OAuthSession createAuthSession(String appId, String userDid, String scope) {
    final app = _availableApps.firstWhere((a) => a.id == appId);
    final now = DateTime.now();
    final rng = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = 'ZAUTH_${List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join()}';

    final session = OAuthSession(
      id: 'sess_${now.millisecondsSinceEpoch}',
      appId: appId,
      appName: app.name,
      userId: 'user_001',
      userDid: userDid,
      scope: scope,
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 1)),
      authCode: code,
    );

    _sessions.add(session);
    return session;
  }

  OAuthSession? approveAuth(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return null;

    final rng = Random();
    final updated = _sessions[index].copyWith(
      status: 'approved',
      accessToken: 'zat_${_randomToken(rng)}',
    );
    _sessions[index] = updated;
    return updated;
  }

  OAuthSession? rejectAuth(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return null;

    final updated = _sessions[index].copyWith(status: 'rejected');
    _sessions[index] = updated;
    return updated;
  }

  OAuthSession? revokeAccess(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return null;

    final updated = _sessions[index].copyWith(
      status: 'revoked',
      accessToken: null,
    );
    _sessions[index] = updated;
    return updated;
  }

  List<OAuthApp> getAvailableApps() {
    final connectedIds = _sessions
        .where((s) => s.status == 'approved')
        .map((s) => s.appId)
        .toSet();

    return _availableApps.where((a) => !connectedIds.contains(a.id)).toList();
  }

  String generateQRCode(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    return 'zero://oauth/authorize?session_id=${session.id}&app_id=${session.appId}&scope=${session.scope}&auth_code=${session.authCode}&user_did=${session.userDid}';
  }

  List<OAuthSession> getSessionsForUser(String userDid) {
    return _sessions.where((s) => s.userDid == userDid).toList();
  }
}