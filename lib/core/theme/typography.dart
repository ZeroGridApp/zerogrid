import 'package:flutter/material.dart';
import 'colors.dart';
import 'zero_theme.dart';

class ZeroTypography {
  ZeroTypography._();

  static TextStyle displayLarge(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: isZh ? 0.04 : -0.02,
      color: context.zTextPrimary,
    );
  }

  static TextStyle displayMedium(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: isZh ? 0.04 : -0.01,
      color: context.zTextPrimary,
    );
  }

  static TextStyle headline(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: isZh ? 0.03 : -0.01,
      color: context.zTextPrimary,
    );
  }

  static TextStyle title(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: isZh ? 0.02 : -0.005,
      color: context.zTextPrimary,
    );
  }

  static TextStyle body(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: isZh ? 0.02 : 0,
      color: context.zTextSecondary,
    );
  }

  static TextStyle bodyBold(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.55,
      letterSpacing: isZh ? 0.02 : 0,
      color: context.zTextPrimary,
    );
  }

  static TextStyle caption(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);
    return TextStyle(
      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: isZh ? 0.03 : 0.01,
      color: context.zTextTertiary,
    );
  }

  static TextStyle mono(BuildContext context) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
      color: context.zTextSecondary,
    );
  }

  static TextStyle monoSmall(BuildContext context) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
      color: context.zTextTertiary,
    );
  }
}