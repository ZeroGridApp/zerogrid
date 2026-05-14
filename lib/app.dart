import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_config.dart';
import 'features/onboarding/splash_screen.dart';
import 'l10n/generated/app_localizations.dart';

class ZeroApp extends StatefulWidget {
  const ZeroApp({super.key});

  static ZeroAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<ZeroAppState>();
  }

  @override
  State<ZeroApp> createState() => ZeroAppState();
}

class ZeroAppState extends State<ZeroApp> {
  Locale _locale = const Locale('zh');
  String _themeId = 'ink';
  String _displayName = 'Zero Citizen';
  bool _securityLock = true;
  int _disappearingTime = 0;
  bool _animationsEnabled = true;

  Locale get locale => _locale;
  String get themeId => _themeId;
  ZeroThemeConfig get currentTheme => ZeroThemeConfig.all.firstWhere((t) => t.id == _themeId, orElse: () => ZeroThemeConfig.ink);
  bool get isDark => currentTheme.isDark;
  String get displayName => _displayName;
  bool get securityLock => _securityLock;
  int get disappearingTime => _disappearingTime;
  bool get animationsEnabled => _animationsEnabled;

  void changeLanguage(Locale newLocale) => setState(() => _locale = newLocale);

  void setTheme(String id) => setState(() => _themeId = id);

  void setDisplayName(String name) => setState(() => _displayName = name);
  void toggleSecurityLock() => setState(() => _securityLock = !_securityLock);
  void setDisappearingTime(int seconds) => setState(() => _disappearingTime = seconds);
  void toggleAnimations() => setState(() => _animationsEnabled = !_animationsEnabled);

  void lockAndExit(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme;
    return MaterialApp(
      title: 'Zero / 零界',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final l in supportedLocales) {
          if (l.languageCode == locale?.languageCode) return l;
        }
        return supportedLocales.first;
      },
      theme: ZeroThemeConfig.paper.themeData,
      darkTheme: theme.themeData,
      home: const SplashScreen(),
    );
  }
}