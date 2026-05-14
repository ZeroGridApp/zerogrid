import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_service.dart';
import '../chat/chat_list_screen.dart';
import '../contacts/add_contact_screen.dart';
import '../notifications/notification_screen.dart';
import '../search/search_screen.dart';
import '../discover/discover_feed.dart';
import '../settings/profile_screen.dart';
import '../wallet/wallet_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  static const _tabs = <Widget>[
    ChatListScreen(),
    DiscoverFeedScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.seedDemo();
  }

  void _navigateToAddContact() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddContactScreen(),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NotificationScreen(),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final navItems = [
      BottomNavigationBarItem(icon: const Icon(Icons.chat_outlined), activeIcon: const Icon(Icons.chat_bubble_rounded), label: l10n.tabChats),
      BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore_rounded), label: l10n.tabSpace),
      BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined), activeIcon: const Icon(Icons.account_balance_wallet_rounded), label: l10n.tabWallet),
      BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person_rounded), label: l10n.tabProfile),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.zBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Zero',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: context.zTextSecondary,
              size: ZeroTypography.title(context).fontSize,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SearchScreen()),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: context.zTextSecondary,
                  size: ZeroTypography.title(context).fontSize,
                ),
                onPressed: _navigateToNotifications,
              ),
              if (_notificationService.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: context.zError,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _notificationService.unreadCount > 9
                          ? '9+'
                          : '${_notificationService.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _tabs[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddContact,
              backgroundColor: context.zAccent,
              elevation: 0,
              child: Icon(
                Icons.person_add_rounded,
                color: context.zBg,
                size: 24,
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.zDivider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: navItems,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}