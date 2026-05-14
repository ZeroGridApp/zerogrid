import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';

class ZeroGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ZeroGlassSurface({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zFrostWhite,
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
        border: Border.all(
          color: context.zFrostWhiteStrong,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}