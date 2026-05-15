import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_input.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen>
    with SingleTickerProviderStateMixin {
  final _idController = TextEditingController();
  bool _adding = false;
  bool _added = false;
  _FoundContact? _searchResult;

  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;

  int _selectedTab = 0;
  String _searchQuery = '';

  final List<_Contact> _contacts = [];

  final List<_FriendRequest> _friendRequests = [];

  final List<_NearbyDevice> _nearbyDevices = [];

  final List<_DemoContact> _demoContacts = [];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _radarAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.linear),
    );
    _radarController.repeat();

    _idController.addListener(() {
      final v = _idController.text.trim().toUpperCase();
      if (v != _searchQuery) {
        setState(() {
          _searchQuery = v;
          _searchResult = null;
          _added = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  List<_DemoContact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _demoContacts;
    return _demoContacts.where((c) {
      return c.zeroId.contains(_searchQuery) ||
          c.displayName.toUpperCase().contains(_searchQuery);
    }).toList();
  }

  void _addFriend(_DemoContact contact) {
    setState(() => _adding = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = true;
        _searchResult = _FoundContact(
          zeroId: contact.zeroId,
          displayName: contact.displayName,
          online: contact.online,
        );
      });
      _contacts.add(_Contact(
        zeroId: contact.zeroId,
        displayName: contact.displayName,
        online: contact.online,
        lastSeen: DateTime.now(),
      ));
    });
  }

  void _connectNearby(_NearbyDevice device) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (_contacts.any((c) => c.zeroId == device.zeroId)) return;
    _contacts.add(_Contact(
      zeroId: device.zeroId,
      displayName: device.name,
      online: true,
      lastSeen: DateTime.now(),
    ));
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '已连接 ${device.name}' : 'Connected ${device.name}'),
        backgroundColor: context.zSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _acceptRequest(int index) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final req = _friendRequests[index];
    setState(() {
      _friendRequests.removeAt(index);
    });
    _contacts.add(_Contact(
      zeroId: req.zeroId,
      displayName: req.displayName,
      online: true,
      lastSeen: DateTime.now(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '已接受 ${req.displayName} 的好友请求' : 'Accepted friend request from ${req.displayName}'),
        backgroundColor: context.zSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _declineRequest(int index) {
    setState(() {
      _friendRequests.removeAt(index);
    });
  }

  void _removeContact(int index) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final c = _contacts[index];
    setState(() {
      _contacts.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '已移除 ${c.displayName}' : 'Removed ${c.displayName}'),
        backgroundColor: context.zError,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: isZh ? '撤销' : 'Undo',
          textColor: context.zBg,
          onPressed: () {
            setState(() {
              _contacts.insert(index, c);
            });
          },
        ),
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _idController.text = data!.text!.trim().toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.addContact,
          style: ZeroTypography.title(context).copyWith(
            color: context.zTextPrimary,
          ),
        ),
        bottom: TabBar(
          onTap: (i) => setState(() => _selectedTab = i),
          labelColor: context.zAccent,
          unselectedLabelColor: context.zTextTertiary,
          indicatorColor: context.zAccent,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
          tabs: [
            Tab(text: isZh ? '搜索 ZEROID' : 'SEARCH ZEROID'),
            Tab(text: isZh ? '附近设备' : 'NEARBY'),
            Tab(text: isZh ? '好友请求' : 'REQUESTS'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildSearchTab(),
                _buildNearbyTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
          if (_contacts.isNotEmpty) _buildContactsSection(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ZeroSpacing.lg),
          _buildSearchInputSection(),
          const SizedBox(height: ZeroSpacing.md),
          if (_adding) _buildAddingIndicator(),
          if (_added && _searchResult != null) _buildAddedCard(),
          if (!_added && _searchQuery.isEmpty) ...[
            _buildQRScanner(),
            const SizedBox(height: ZeroSpacing.lg),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.xxl),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: context.zTextTertiary.withOpacity(0.3),
                    ),
                    const SizedBox(height: ZeroSpacing.md),
                    Text(
                      ZeroTheme.isZh(context) ? '输入 ZeroID 搜索' : 'Enter a ZeroID to search',
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextTertiary,
                      ),
                    ),
                    const SizedBox(height: ZeroSpacing.xs),
                    Text(
                      ZeroTheme.isZh(context) ? '或使用 QR 码扫描' : 'or use QR code scanning',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!_added && _searchQuery.isNotEmpty) _buildFilteredResults(),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSearchInputSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchByZeroId,
          style: ZeroTypography.caption(context).copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: context.zTextTertiary,
          ),
        ),
        const SizedBox(height: ZeroSpacing.sm),
        ZeroInput(
          hint: l10n.zeroIdPlaceholder,
          controller: _idController,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pasteFromClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.zFrostWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.content_paste_rounded,
                    size: 16,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ZeroTheme.isZh(context) ? 'QR 扫描即将推出' : 'QR scanning coming soon'),
                      backgroundColor: context.zAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.zFrostWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 16,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              GestureDetector(
                onTap: () {
                  if (_idController.text.trim().isNotEmpty) {
                    _idController.text = '';
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.zAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search,
                    size: 20,
                    color: context.zBg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddingIndicator() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.zAccent,
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              isZh ? '正在搜索 DHT 网络...' : 'Searching DHT network...',
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedCard() {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final contact = _searchResult!;
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.zSuccess.withOpacity(0.3),
                        context.zCeladon.withOpacity(0.3),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: context.zSuccess,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            l10n.requestSent,
            style: ZeroTypography.headline(context).copyWith(
              color: context.zSuccess,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            contact.displayName,
            style: ZeroTypography.bodyBold(context),
          ),
          const SizedBox(height: 2),
          Text(
            contact.zeroId,
            style: ZeroTypography.monoSmall(context).copyWith(
              color: context.zAccent,
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: contact.online ? context.zSuccess : context.zTextDisabled,
                ),
              ),
              const SizedBox(width: ZeroSpacing.xs),
              Text(
                contact.online ? l10n.online : (isZh ? '离线' : 'Offline'),
                style: ZeroTypography.caption(context).copyWith(
                  color: contact.online ? context.zSuccess : context.zTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          ZeroButton(
            label: l10n.searchAnother,
            onTap: () {
              setState(() {
                _searchResult = null;
                _added = false;
              });
              _idController.clear();
            },
            outlined: true,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredResults() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final results = _filteredContacts;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.xxl),
        child: Center(
          child: Text(
            isZh ? 'DHT 中未找到结果' : 'No results found in DHT',
            style: ZeroTypography.body(context).copyWith(
              color: context.zTextTertiary,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Text(
          isZh ? '搜索结果' : 'SEARCH RESULTS',
          style: ZeroTypography.caption(context).copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: context.zTextTertiary,
          ),
        ),
        const SizedBox(height: ZeroSpacing.sm),
        ...results.map((c) => _buildDemoContactTile(c)),
      ],
    );
  }

  Widget _buildDemoContactTile(_DemoContact contact) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final alreadyAdded = _contacts.any((c) => c.zeroId == contact.zeroId);
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: const EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Row(
          children: [
            _buildAvatar(contact.displayName, contact.zeroId, ZeroSpacing.avatarMd),
            const SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        contact.zeroId,
                        style: ZeroTypography.monoSmall(context),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: contact.online
                              ? context.zSuccess
                              : context.zTextDisabled,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact.online ? (isZh ? '在线' : 'Online') : (isZh ? '离线' : 'Offline'),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                          color: contact.online
                              ? context.zSuccess
                              : context.zTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (alreadyAdded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                ),
                child: Text(
                  isZh ? '已添加' : 'Added',
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zSuccess,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _addFriend(contact),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    gradient: LinearGradient(
                      colors: [context.zAccent, context.zCeladon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_rounded, size: 16, color: context.zBg),
                      const SizedBox(width: 4),
                      Text(
                        isZh ? '添加' : 'Add',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.zBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    final l10n = AppLocalizations.of(context);
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.zAccentMuted.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: context.zTextTertiary.withOpacity(0.3),
                ),
                ...List.generate(3, (i) {
                  return Positioned(
                    top: i == 0 ? 20 : null,
                    bottom: i == 2 ? 20 : null,
                    left: i == 0 ? 20 : null,
                    right: i == 2 ? 20 : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.zAccent.withOpacity(0.5),
                            width: 2,
                          ),
                          left: BorderSide(
                            color: context.zAccent.withOpacity(0.5),
                            width: 2,
                          ),
                          bottom: (i < 2)
                              ? BorderSide.none
                              : BorderSide(
                                  color: context.zAccent.withOpacity(0.5),
                                  width: 2,
                                ),
                          right: (i < 2)
                              ? BorderSide.none
                              : BorderSide(
                                  color: context.zAccent.withOpacity(0.5),
                                  width: 2,
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.md),
          Text(
            l10n.scanQRCode,
            style: ZeroTypography.caption(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ZeroTheme.isZh(context) ? 'QR 扫描即将推出' : 'QR scanning coming soon'),
                      backgroundColor: context.zAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.zAccent.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(ZeroSpacing.buttonRadius),
                    border: Border.all(
                      color: context.zAccent.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 18, color: context.zAccent),
                      const SizedBox(width: ZeroSpacing.sm),
                      Text(
                        l10n.scanQR,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.zAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: ZeroSpacing.md),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.myQRCodeCopied),
                      backgroundColor: context.zAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.zSurface,
                    borderRadius:
                        BorderRadius.circular(ZeroSpacing.buttonRadius),
                    border: Border.all(
                      color: context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 18, color: context.zAccent),
                      const SizedBox(width: ZeroSpacing.sm),
                      Text(
                        l10n.myQRCode,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.zAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          const SizedBox(height: ZeroSpacing.lg),
          _buildRadarWidget(),
          const SizedBox(height: ZeroSpacing.lg),
          if (_nearbyDevices.isNotEmpty) ...[
            Text(
              isZh ? '发现设备' : 'DISCOVERED',
              style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: context.zTextTertiary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            ..._nearbyDevices.map((d) => _buildNearbyDeviceTile(d)),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.xxxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 64,
                      color: context.zTextTertiary.withOpacity(0.3),
                    ),
                    const SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '未发现附近设备' : 'No nearby devices found',
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextTertiary,
                      ),
                    ),
                    const SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh ? '开启蓝牙和 DHT 以发现附近设备' : 'Enable BLE and DHT to discover nearby devices',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildRadarWidget() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return ZeroCard(
      padding: const EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zSuccess,
                  boxShadow: [
                    BoxShadow(
                      color: context.zSuccess.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeroSpacing.sm),
              Text(
                isZh ? 'BLE / DHT 活跃' : 'BLE / DHT Active',
                style: ZeroTypography.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.zSuccess,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                isZh
                    ? '${_nearbyDevices.isEmpty ? "正在搜索" : "${_nearbyDevices.length} 个设备"}'
                    : '${_nearbyDevices.isEmpty ? "Scanning" : "${_nearbyDevices.length} devices"}',
                style: ZeroTypography.monoSmall(context),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            width: 260,
            height: 260,
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarPainter(
                    sweepAngle: _radarAnimation.value,
                    accentColor: context.zAccent,
                    surfaceColor: context.zSurface,
                    devices: _nearbyDevices,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyDeviceTile(_NearbyDevice device) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final alreadyConnected = _contacts.any((c) => c.zeroId == device.zeroId);
    final signalBars = _signalBars(device.signalStrength);
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: const EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Row(
          children: [
            _buildAvatar(device.name, device.zeroId, ZeroSpacing.avatarMd),
            const SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _truncateZeroId(device.zeroId),
                        style: ZeroTypography.monoSmall(context),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      ...List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Container(
                            width: 3,
                            height: 8.0 + i * 3,
                            decoration: BoxDecoration(
                              color: i < signalBars
                                  ? context.zAccent
                                  : context.zFrostWhiteStrong,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            if (alreadyConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.zSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                ),
                child: Text(
                  isZh ? '已连接' : 'Connected',
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zSuccess,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _connectNearby(device),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    gradient: LinearGradient(
                      colors: [context.zAccent, context.zCeladon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    isZh ? '连接' : 'Connect',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.zBg,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _signalBars(double strength) {
    if (strength >= 0.75) return 4;
    if (strength >= 0.5) return 3;
    if (strength >= 0.25) return 2;
    return 1;
  }

  String _truncateZeroId(String zeroId) {
    if (zeroId.length <= 8) return zeroId;
    return '${zeroId.substring(0, 4)}...${zeroId.substring(zeroId.length - 2)}';
  }

  Widget _buildRequestsTab() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ZeroSpacing.lg),
          if (_friendRequests.isNotEmpty) ...[
            Text(
              isZh ? '收到的请求' : 'INCOMING REQUESTS',
              style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: context.zTextTertiary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.sm),
            ..._friendRequests.asMap().entries.map(
                  (e) => _buildRequestTile(e.key, e.value),
                ),
          ],
          if (_friendRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ZeroSpacing.xxxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: context.zTextTertiary.withOpacity(0.3),
                    ),
                    const SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '暂无待处理请求' : 'No pending requests',
                      style: ZeroTypography.body(context).copyWith(
                        color: context.zTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildRequestTile(int index, _FriendRequest req) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
      child: ZeroCard(
        padding: const EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(req.displayName, req.zeroId, ZeroSpacing.avatarMd),
                const SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.displayName,
                        style: ZeroTypography.bodyBold(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        req.zeroId,
                        style: ZeroTypography.monoSmall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeroSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              decoration: BoxDecoration(
                color: context.zFrostWhite,
                borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
              ),
              child: Text(
                req.message,
                style: ZeroTypography.body(context).copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _declineRequest(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(ZeroSpacing.buttonRadius),
                        border: Border.all(
                          color: context.zError.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isZh ? '拒绝' : 'Decline',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.zError,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ZeroSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _acceptRequest(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(ZeroSpacing.buttonRadius),
                        gradient: LinearGradient(
                          colors: [context.zSuccess, context.zCeladon],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isZh ? '接受' : 'Accept',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: context.zSurface,
        border: Border(
          top: BorderSide(
            color: context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZeroSpacing.screenHorizontal,
              vertical: ZeroSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Icons.people_rounded, size: 16, color: context.zAccent),
                const SizedBox(width: ZeroSpacing.sm),
                Text(
                  isZh ? '联系人' : 'CONTACTS',
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: context.zAccent,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_contacts.length}',
                  style: ZeroTypography.monoSmall(context).copyWith(
                    color: context.zAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: ZeroSpacing.screenHorizontal,
              ),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                return _buildContactTile(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(int index) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final contact = _contacts[index];
    return Dismissible(
      key: ValueKey(contact.zeroId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeContact(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: ZeroSpacing.sm),
        decoration: BoxDecoration(
          color: context.zError.withOpacity(0.15),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: ZeroSpacing.lg),
        child: Icon(Icons.delete_outline, color: context.zError, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(ZeroSpacing.md),
          decoration: BoxDecoration(
            color: context.zSurface,
            borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
          ),
          child: Row(
            children: [
              _buildAvatar(
                contact.displayName,
                contact.zeroId,
                ZeroSpacing.avatarSm,
              ),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: ZeroTypography.bodyBold(context).copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.zeroId,
                      style: ZeroTypography.monoSmall(context),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: contact.online
                              ? context.zSuccess
                              : context.zTextDisabled,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact.online ? (isZh ? '在线' : 'Online') : (isZh ? '离线' : 'Offline'),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                          color: contact.online
                              ? context.zSuccess
                              : context.zTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatLastSeen(contact.lastSeen, isZh),
                    style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String zeroId, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : zeroId[1];
    final colorSeed = zeroId.hashCode.abs();
    final hue = (colorSeed % 360).toDouble();
    final avatarColor = HSLColor.fromAHSL(0.3, hue, 0.55, 0.45).toColor();
    return Container(
      width: size,
      height: size,
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
        initial,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime dt, bool isZh) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return isZh ? '刚刚' : 'just now';
    if (diff.inMinutes < 60) return isZh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isZh ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isZh ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color accentColor;
  final Color surfaceColor;
  final List<_NearbyDevice> devices;

  _RadarPainter({
    required this.sweepAngle,
    required this.accentColor,
    required this.surfaceColor,
    required this.devices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(0.06),
          surfaceColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bgPaint);

    for (int i = 1; i <= 4; i++) {
      final ringPaint = Paint()
        ..color = accentColor.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }

    final crossPaint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor.withOpacity(0.35),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        sweepAngle,
        math.pi * 0.55,
        true,
      )
      ..close();
    canvas.drawPath(path, sweepPaint);

    final linePaint = Paint()
      ..color = accentColor.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dx = center.dx + radius * math.cos(sweepAngle);
    final dy = center.dy + radius * math.sin(sweepAngle);
    canvas.drawLine(center, Offset(dx, dy), linePaint);

    final centerDotPaint = Paint()..color = accentColor;
    canvas.drawCircle(center, 3, centerDotPaint);

    for (int i = 0; i < devices.length; i++) {
      final device = devices[i];
      final angle = (i * 2 * math.pi / devices.length) + (math.pi / 6);
      final dist = 0.35 + (0.55 * device.signalStrength);
      final dotX = center.dx + radius * dist * math.cos(angle);
      final dotY = center.dy + radius * dist * math.sin(angle);

      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(dotX, dotY), 6, glowPaint);

      final dotPaint = Paint()..color = accentColor;
      canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);

      final pulsePaint = Paint()
        ..color = accentColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset(dotX, dotY), 8, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return sweepAngle != oldDelegate.sweepAngle ||
        accentColor != oldDelegate.accentColor ||
        surfaceColor != oldDelegate.surfaceColor ||
        devices != oldDelegate.devices;
  }
}

class _FoundContact {
  final String zeroId;
  final String displayName;
  final bool online;

  const _FoundContact({
    required this.zeroId,
    required this.displayName,
    required this.online,
  });
}

class _DemoContact {
  final String zeroId;
  final String displayName;
  final bool online;

  const _DemoContact({
    required this.zeroId,
    required this.displayName,
    required this.online,
  });
}

class _NearbyDevice {
  final String name;
  final String zeroId;
  final double signalStrength;

  const _NearbyDevice({
    required this.name,
    required this.zeroId,
    required this.signalStrength,
  });
}

class _FriendRequest {
  final String zeroId;
  final String displayName;
  final String message;

  const _FriendRequest({
    required this.zeroId,
    required this.displayName,
    required this.message,
  });
}

class _Contact {
  final String zeroId;
  final String displayName;
  final bool online;
  final DateTime lastSeen;

  const _Contact({
    required this.zeroId,
    required this.displayName,
    required this.online,
    required this.lastSeen,
  });
}