import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/oauth/zero_oauth_service.dart';
import '../../widgets/zero_card.dart';

class ZeroOAuthScreen extends StatefulWidget {
  const ZeroOAuthScreen({super.key});

  @override
  State<ZeroOAuthScreen> createState() => _ZeroOAuthScreenState();
}

class _ZeroOAuthScreenState extends State<ZeroOAuthScreen> with SingleTickerProviderStateMixin {
  final _oauthService = ZeroOAuthService();
  late TabController _tabController;
  late final String _userDid;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    _userDid = 'did:zero:Z${List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join()}';
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _showAppDetailSheet(OAuthApp app) {
    final isZh = ZeroTheme.isZh(context);
    final sessions = _oauthService.getSessionsForUser(_userDid);
    final session = sessions.where((s) => s.appId == app.id && s.status == 'approved').firstOrNull;

    final scopeInfo = ZeroOAuthService.scopes.where((s) => s.key == (session?.scope ?? 'basic')).firstOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ZeroSpacing.cardRadius)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text(
                  app.iconUrl,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: ZeroSpacing.md),
                Text(
                  app.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.zTextPrimary,
                  ),
                ),
                if (app.verified) ...[
                  const SizedBox(height: ZeroSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: context.zAccent),
                      const SizedBox(width: ZeroSpacing.xs),
                      Text(
                        isZh ? '已认证开发者' : 'Verified Developer',
                        style: ZeroTypography.caption(context).copyWith(color: context.zAccent),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: ZeroSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                  child: ZeroCard(
                    padding: const EdgeInsets.all(ZeroSpacing.md),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.info_outline,
                          label: isZh ? '描述' : 'Description',
                          value: app.description,
                          isZh: isZh,
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        _DetailRow(
                          icon: Icons.language,
                          label: isZh ? '网站' : 'Website',
                          value: app.website,
                          isZh: isZh,
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        _DetailRow(
                          icon: Icons.people_outline,
                          label: isZh ? '开发者' : 'Developer',
                          value: app.developerName,
                          isZh: isZh,
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        _DetailRow(
                          icon: Icons.group_outlined,
                          label: isZh ? '用户数' : 'Users',
                          value: '${app.users}',
                          isZh: isZh,
                        ),
                        if (session != null) ...[
                          const SizedBox(height: ZeroSpacing.sm),
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: isZh ? '连接时间' : 'Connected Since',
                            value: '${session.createdAt.year}/${session.createdAt.month}/${session.createdAt.day}',
                            isZh: isZh,
                          ),
                          const SizedBox(height: ZeroSpacing.sm),
                          _DetailRow(
                            icon: Icons.security_outlined,
                            label: isZh ? '授权范围' : 'Scope',
                            value: scopeInfo?.name ?? session.scope,
                            isZh: isZh,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                if (session != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          _oauthService.revokeAccess(session.id);
                          Navigator.pop(ctx);
                          _refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                            border: Border.all(
                              color: context.zError.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isZh ? '撤销访问权限' : 'Revoke Access',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.zError,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQRSheet() {
    final isZh = ZeroTheme.isZh(context);
    final session = _oauthService.createAuthSession('zeropay_merchant', _userDid, 'wallet');
    final qrData = _oauthService.generateQRCode(session.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ZeroSpacing.cardRadius)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text(
                  isZh ? '扫码授权' : 'Scan to Authorize',
                  style: ZeroTypography.title(context),
                ),
                const SizedBox(height: ZeroSpacing.md),
                Text(
                  isZh ? '第三方应用扫描此二维码完成授权' : 'Third-party app scans this QR to authorize',
                  style: ZeroTypography.body(context),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.zBg,
                    borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                    border: Border.all(color: context.zFrostWhiteStrong),
                  ),
                  child: CustomPaint(
                    painter: _QRMockPainter(context.zTextPrimary),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                  child: ZeroCard(
                    padding: const EdgeInsets.all(ZeroSpacing.md),
                    child: Column(
                      children: [
                        Text(
                          isZh ? '授权码' : 'Auth Code',
                          style: ZeroTypography.caption(context),
                        ),
                        const SizedBox(height: ZeroSpacing.xs),
                        SelectableText(
                          session.authCode ?? '',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: context.zAccent,
                          ),
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        Text(
                          isZh ? '有效期 1 小时' : 'Valid for 1 hour',
                          style: ZeroTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    final connectedApps = _oauthService.getConnectedApps(_userDid);
    final pendingAuths = _oauthService.getPendingAuthorizations();
    final availableApps = _oauthService.getAvailableApps();

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isZh ? 'ZeroID OAuth' : 'ZeroID OAuth',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.zAccent,
          unselectedLabelColor: context.zTextTertiary,
          indicatorColor: context.zAccent,
          labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              text: isZh ? '已连接应用' : 'Connected Apps',
            ),
            Tab(
              text: isZh ? '授权管理' : 'Authorization',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectedTab(context, isZh, connectedApps),
          _buildAuthTab(context, isZh, pendingAuths, connectedApps, availableApps),
        ],
      ),
    );
  }

  Widget _buildConnectedTab(
    BuildContext context,
    bool isZh,
    List<OAuthApp> connectedApps,
  ) {
    if (connectedApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 64, color: context.zTextDisabled),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '暂无连接的应用' : 'No connected apps',
              style: ZeroTypography.title(context),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Text(
              isZh ? '连接第三方应用以使用 ZeroID 登录' : 'Connect third-party apps to use ZeroID login',
              style: ZeroTypography.body(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: context.zAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenTop,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        itemCount: connectedApps.length,
        itemBuilder: (context, index) {
          final app = connectedApps[index];
          final sessions = _oauthService.getSessionsForUser(_userDid);
          final session = sessions.where((s) => s.appId == app.id && s.status == 'approved').firstOrNull;
          final scopeInfo = ZeroOAuthService.scopes.where((s) => s.key == (session?.scope ?? 'basic')).firstOrNull;

          return Padding(
            padding: EdgeInsets.only(bottom: index < connectedApps.length - 1 ? ZeroSpacing.md : 0),
            child: ZeroCard(
              padding: const EdgeInsets.all(ZeroSpacing.md),
              onTap: () => _showAppDetailSheet(app),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.zAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    ),
                    child: Center(
                      child: Text(
                        app.iconUrl,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                app.name,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.zTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (app.verified) ...[
                              const SizedBox(width: ZeroSpacing.xs),
                              Icon(Icons.verified, size: 14, color: context.zAccent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.description,
                          style: ZeroTypography.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        Row(
                          children: [
                            Text(
                              '${app.users} ${isZh ? '用户' : 'users'}',
                              style: ZeroTypography.caption(context).copyWith(
                                fontSize: 11,
                                color: context.zTextTertiary,
                              ),
                            ),
                            const SizedBox(width: ZeroSpacing.sm),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.zTextDisabled,
                              ),
                            ),
                            const SizedBox(width: ZeroSpacing.sm),
                            Text(
                              isZh
                                  ? '${app.connectedAt.year}/${app.connectedAt.month}/${app.connectedAt.day} 连接'
                                  : 'Connected ${app.connectedAt.year}/${app.connectedAt.month}/${app.connectedAt.day}',
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
                  if (scopeInfo != null) ...[
                    const SizedBox(width: ZeroSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.sm,
                        vertical: ZeroSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.zAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      ),
                      child: Text(
                        scopeInfo.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthTab(
    BuildContext context,
    bool isZh,
    List<OAuthSession> pendingAuths,
    List<OAuthApp> connectedApps,
    List<OAuthApp> availableApps,
  ) {
    final allSessions = _oauthService.getSessionsForUser(_userDid);
    final approvedSessions = allSessions.where((s) => s.status == 'approved').toList();

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: context.zAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenTop,
          ZeroSpacing.screenHorizontal,
          ZeroSpacing.screenBottom,
        ),
        children: [
          if (pendingAuths.isNotEmpty) ...[
            Text(
              isZh ? '待处理授权' : 'Pending Authorization',
              style: ZeroTypography.title(context).copyWith(color: context.zWarning),
            ),
            const SizedBox(height: ZeroSpacing.md),
            ...pendingAuths.map((session) {
              final scopeInfo = ZeroOAuthService.scopes.where((s) => s.key == session.scope).firstOrNull;
              final app = connectedApps.where((a) => a.id == session.appId).firstOrNull;

              return Padding(
                padding: const EdgeInsets.only(bottom: ZeroSpacing.md),
                child: ZeroCard(
                  padding: const EdgeInsets.all(ZeroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            app?.iconUrl ?? '🔗',
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: ZeroSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.appName,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.zTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isZh ? '请求访问你的数据' : 'Requesting access to your data',
                                  style: ZeroTypography.caption(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ZeroSpacing.md),
                      if (scopeInfo != null)
                        Row(
                          children: [
                            Text(scopeInfo.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: ZeroSpacing.sm),
                            Text(
                              scopeInfo.name,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.zTextSecondary,
                              ),
                            ),
                            const SizedBox(width: ZeroSpacing.sm),
                            Expanded(
                              child: Text(
                                scopeInfo.description,
                                style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: ZeroSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _oauthService.rejectAuth(session.id);
                                _refresh();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm + 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                                  border: Border.all(
                                    color: context.zTextDisabled,
                                    width: 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    isZh ? '拒绝' : 'Reject',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.zTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: ZeroSpacing.md),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _oauthService.approveAuth(session.id);
                                _refresh();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.sm + 2),
                                decoration: BoxDecoration(
                                  color: context.zAccent,
                                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                                ),
                                child: Center(
                                  child: Text(
                                    isZh ? '批准' : 'Approve',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.zBg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        ),
                      ],
                    ),
                  ),
                );
            }),
            const SizedBox(height: ZeroSpacing.lg),
          ],
          if (approvedSessions.isNotEmpty) ...[
            Text(
              isZh ? '已批准授权' : 'Approved Authorizations',
              style: ZeroTypography.title(context).copyWith(color: context.zSuccess),
            ),
            const SizedBox(height: ZeroSpacing.md),
            ...approvedSessions.map((session) {
              final scopeInfo = ZeroOAuthService.scopes.where((s) => s.key == session.scope).firstOrNull;
              final app = _oauthService.getConnectedApps(_userDid).where((a) => a.id == session.appId).firstOrNull;

              return Padding(
                padding: const EdgeInsets.only(bottom: ZeroSpacing.md),
                child: ZeroCard(
                  padding: const EdgeInsets.all(ZeroSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.zSuccess.withOpacity(0.15),
                        ),
                        child: Icon(Icons.check, size: 14, color: context.zSuccess),
                      ),
                      const SizedBox(width: ZeroSpacing.md),
                      Text(
                        app?.iconUrl ?? '🔗',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: ZeroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.appName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.zTextPrimary,
                              ),
                            ),
                            if (scopeInfo != null)
                              Text(
                                '${scopeInfo.icon} ${scopeInfo.name}',
                                style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _oauthService.revokeAccess(session.id);
                          _refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                            border: Border.all(
                              color: context.zError.withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            isZh ? '撤销' : 'Revoke',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.zError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: ZeroSpacing.lg),
          ],
          GestureDetector(
            onTap: _showQRSheet,
            child: Container(
              padding: const EdgeInsets.all(ZeroSpacing.md),
              decoration: BoxDecoration(
                color: context.zAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                border: Border.all(
                  color: context.zAccent.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.zAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    ),
                    child: Icon(Icons.qr_code_scanner, size: 22, color: context.zAccent),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? '添加新应用' : 'Add New App',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.zTextPrimary,
                          ),
                        ),
                        Text(
                          isZh ? '生成授权二维码供第三方扫描' : 'Generate auth QR for third-party scanning',
                          style: ZeroTypography.caption(context).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.qr_code_2, size: 28, color: context.zAccent.withOpacity(0.6)),
                ],
              ),
            ),
          ),
          if (availableApps.isNotEmpty) ...[
            const SizedBox(height: ZeroSpacing.xl),
            Text(
              isZh ? '支持 ZeroID 登录的应用' : 'Apps Supporting ZeroID Login',
              style: ZeroTypography.headline(context),
            ),
            const SizedBox(height: ZeroSpacing.md),
            ...availableApps.map((app) {
              return Padding(
                padding: const EdgeInsets.only(bottom: ZeroSpacing.md),
                child: ZeroCard(
                  padding: const EdgeInsets.all(ZeroSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.zAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                        ),
                        child: Center(
                          child: Text(
                            app.iconUrl,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: ZeroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    app.name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.zTextPrimary,
                                    ),
                                  ),
                                ),
                                if (app.verified) ...[
                                  const SizedBox(width: ZeroSpacing.xs),
                                  Icon(Icons.verified, size: 12, color: context.zAccent),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.description,
                              style: ZeroTypography.caption(context).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: ZeroSpacing.xs),
                            Text(
                              '${app.users} ${isZh ? '用户' : 'users'} · ${app.developerName}',
                              style: ZeroTypography.caption(context).copyWith(
                                fontSize: 10,
                                color: context.zTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      GestureDetector(
                        onTap: () {
                          _oauthService.createAuthSession(app.id, _userDid, 'basic');
                          final session = _oauthService.getSessionsForUser(_userDid)
                              .where((s) => s.appId == app.id && s.status == 'pending')
                              .firstOrNull;
                          if (session != null) {
                            _oauthService.approveAuth(session.id);
                            _refresh();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: context.zAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                          child: Text(
                            isZh ? '连接' : 'Connect',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.zAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isZh;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isZh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.zTextTertiary),
        const SizedBox(width: ZeroSpacing.sm),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.zTextTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.zTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _QRMockPainter extends CustomPainter {
  final Color color;

  _QRMockPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final moduleSize = size.width / 25;
    final modules = [
      [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0],
      [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0],
      [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
      [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0],
      [1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0],
      [1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1],
      [0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1],
      [0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0],
      [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1],
      [1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1],
      [1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1],
      [0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1],
      [1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1],
      [0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1],
      [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0],
      [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0],
      [1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
    ];

    final offsetX = (size.width - modules[0].length * moduleSize) / 2;
    final offsetY = (size.height - modules.length * moduleSize) / 2;

    for (var row = 0; row < modules.length; row++) {
      for (var col = 0; col < modules[row].length; col++) {
        if (modules[row][col] == 1) {
          final rect = Rect.fromLTWH(
            offsetX + col * moduleSize,
            offsetY + row * moduleSize,
            moduleSize,
            moduleSize,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.2)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}