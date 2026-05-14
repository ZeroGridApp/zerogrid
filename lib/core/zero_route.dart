import 'package:flutter/material.dart';

class ZeroRoute extends MaterialPageRoute {
  ZeroRoute({required super.builder, super.settings})
      : super(fullscreenDialog: true);
}

Route<T> zeroRoute<T>(WidgetBuilder builder) {
  return MaterialPageRoute<T>(builder: builder, fullscreenDialog: true);
}