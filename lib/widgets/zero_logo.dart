import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class ZeroLogo extends StatelessWidget {
  final double size;
  final bool animated;

  const ZeroLogo({super.key, this.size = 80, this.animated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: animated ? context.zAccentGradient : null,
        color: animated ? null : context.zAccent,
        boxShadow: [
          BoxShadow(
            color: context.zAccentGlow,
            blurRadius: size * 0.4,
            spreadRadius: -size * 0.1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '0',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.45,
          fontWeight: FontWeight.w300,
          color: context.zBg,
          height: 1,
        ),
      ),
    );
  }
}