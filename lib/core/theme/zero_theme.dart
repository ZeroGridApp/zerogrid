import 'package:flutter/material.dart';

class ZeroTheme {
  ZeroTheme._();

  static bool isZh(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'zh';
  }
}