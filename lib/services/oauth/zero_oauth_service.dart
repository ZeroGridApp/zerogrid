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