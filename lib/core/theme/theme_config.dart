import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';

class ZeroThemeConfig {
  final String id;
  final String name;
  final String nameZh;
  final Color previewAccent;
  final Color previewBg;
  final bool isDark;
  final ThemeData themeData;

  const ZeroThemeConfig({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.previewAccent,
    required this.previewBg,
    required this.isDark,
    required this.themeData,
  });

  static final List<ZeroThemeConfig> all = [ink, paper, frost, bamboo];

  static final ink = ZeroThemeConfig(
    id: 'ink',
    name: 'Ink',
    nameZh: '水墨',
    previewAccent: const Color(0xFFB8A57A),
    previewBg: const Color(0xFF0A0A0F),
    isDark: true,
    themeData: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB8A57A),
        secondary: Color(0xFF7AAC9E),
        surface: Color(0xFF14141B),
        error: Color(0xFFE06C6C),
        onPrimary: Color(0xFF0A0A0F),
        onSecondary: Color(0xFF0A0A0F),
        onSurface: Color(0xFFE8E6E1),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: _appBarDark(const Color(0xFF0A0A0F), const Color(0xFFE8E6E1)),
      cardTheme: _cardDark(const Color(0xFF14141B)),
      dividerTheme: _divider(const Color(0xFF252530)),
      bottomNavigationBarTheme: _navDark(const Color(0xFF14141B), const Color(0xFFB8A57A)),
      iconTheme: _icon(const Color(0xFFA0A0A8)),
      textSelectionTheme: _textSel(const Color(0xFFB8A57A)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
  );

  static final paper = ZeroThemeConfig(
    id: 'paper',
    name: 'Paper',
    nameZh: '宣纸',
    previewAccent: const Color(0xFF9B863F),
    previewBg: const Color(0xFFEBE5D9),
    isDark: false,
    themeData: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFEBE5D9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF9B863F),
        secondary: Color(0xFF5A8A7A),
        surface: Color(0xFFF7F4EF),
        error: Color(0xFFC06060),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF3B3A36),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: _appBarLight(const Color(0xFFEBE5D9), const Color(0xFF3B3A36)),
      cardTheme: _cardLight(const Color(0xFFF7F4EF)),
      dividerTheme: _divider(const Color(0xFFDBD6CC)),
      bottomNavigationBarTheme: _navLight(const Color(0xFFF7F4EF), const Color(0xFF9B863F)),
      iconTheme: _icon(const Color(0xFF7A7670)),
      textSelectionTheme: _textSel(const Color(0xFF9B863F)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
  );

  static final frost = ZeroThemeConfig(
    id: 'frost',
    name: 'Frost',
    nameZh: '霜月',
    previewAccent: const Color(0xFF8FA4C0),
    previewBg: const Color(0xFF0C0D16),
    isDark: true,
    themeData: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0D16),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8FA4C0),
        secondary: Color(0xFF6B9EB7),
        surface: Color(0xFF151724),
        error: Color(0xFFC87474),
        onPrimary: Color(0xFF0C0D16),
        onSecondary: Color(0xFF0C0D16),
        onSurface: Color(0xFFE0E2EA),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: _appBarDark(const Color(0xFF0C0D16), const Color(0xFFE0E2EA)),
      cardTheme: _cardDark(const Color(0xFF151724)),
      dividerTheme: _divider(const Color(0xFF222436)),
      bottomNavigationBarTheme: _navDark(const Color(0xFF151724), const Color(0xFF8FA4C0)),
      iconTheme: _icon(const Color(0xFF969AB4)),
      textSelectionTheme: _textSel(const Color(0xFF8FA4C0)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
  );

  static final bamboo = ZeroThemeConfig(
    id: 'bamboo',
    name: 'Bamboo',
    nameZh: '翠竹',
    previewAccent: const Color(0xFF9BB88C),
    previewBg: const Color(0xFF0D110E),
    isDark: true,
    themeData: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D110E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9BB88C),
        secondary: Color(0xFF7AB89C),
        surface: Color(0xFF151A17),
        error: Color(0xFFC87474),
        onPrimary: Color(0xFF0D110E),
        onSecondary: Color(0xFF0D110E),
        onSurface: Color(0xFFE2E6DF),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: _appBarDark(const Color(0xFF0D110E), const Color(0xFFE2E6DF)),
      cardTheme: _cardDark(const Color(0xFF151A17)),
      dividerTheme: _divider(const Color(0xFF1E2B23)),
      bottomNavigationBarTheme: _navDark(const Color(0xFF151A17), const Color(0xFF9BB88C)),
      iconTheme: _icon(const Color(0xFF8A9E8A)),
      textSelectionTheme: _textSel(const Color(0xFF9BB88C)),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
  );

  static AppBarTheme _appBarDark(Color bg, Color text) => AppBarTheme(
    backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: text),
  );

  static AppBarTheme _appBarLight(Color bg, Color text) => AppBarTheme(
    backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: text),
  );

  static CardTheme _cardDark(Color color) => CardTheme(color: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius)), margin: EdgeInsets.zero);
  static CardTheme _cardLight(Color color) => CardTheme(color: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius)), margin: EdgeInsets.zero);

  static DividerThemeData _divider(Color c) => DividerThemeData(color: c, thickness: 0.5, space: 0);

  static BottomNavigationBarThemeData _navDark(Color bg, Color sel) => BottomNavigationBarThemeData(
    backgroundColor: bg, selectedItemColor: sel, unselectedItemColor: const Color(0xFF6B6B76),
    type: BottomNavigationBarType.fixed, elevation: 0, showSelectedLabels: false, showUnselectedLabels: false,
  );

  static BottomNavigationBarThemeData _navLight(Color bg, Color sel) => BottomNavigationBarThemeData(
    backgroundColor: bg, selectedItemColor: sel, unselectedItemColor: const Color(0xFFA8A49D),
    type: BottomNavigationBarType.fixed, elevation: 0, showSelectedLabels: false, showUnselectedLabels: false,
  );

  static IconThemeData _icon(Color c) => IconThemeData(color: c, size: ZeroSpacing.iconMd);

  static TextSelectionThemeData _textSel(Color c) => TextSelectionThemeData(cursorColor: c, selectionColor: c.withOpacity(0.2), selectionHandleColor: c);
}