import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';

class ZeroButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool compact;
  final IconData? icon;
  final double width;

  const ZeroButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
    this.compact = false,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.lg,
        vertical: compact ? ZeroSpacing.md : ZeroSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
        border: outlined
            ? Border.all(color: context.zAccentMuted.withOpacity(0.4), width: 0.5)
            : null,
        gradient: outlined
            ? null
            : LinearGradient(
                colors: [context.zAccent, context.zCeladon],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: outlined ? context.zAccent : context.zBg),
            SizedBox(width: ZeroSpacing.sm),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: outlined ? context.zAccent : context.zBg,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}