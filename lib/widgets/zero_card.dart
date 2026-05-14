import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';

class ZeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const ZeroCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: context.zFrostWhiteStrong,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}