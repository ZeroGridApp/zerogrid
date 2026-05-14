import 'package:flutter/material.dart';

extension ZeroColorsX on BuildContext {
  Color get zBg => Theme.of(this).scaffoldBackgroundColor;
  Color get zSurface => Theme.of(this).colorScheme.surface;
  Color get zSurfaceRaised => Color.alphaBlend(
    Theme.of(this).colorScheme.onSurface.withOpacity(0.04),
    Theme.of(this).colorScheme.surface,
  );
  Color get zSurfaceOverlay => Color.alphaBlend(
    Theme.of(this).colorScheme.onSurface.withOpacity(0.08),
    Theme.of(this).colorScheme.surface,
  );

  Color get zAccent => Theme.of(this).colorScheme.primary;
  Color get zAccentGlow => Theme.of(this).colorScheme.primary.withOpacity(0.25);
  Color get zAccentMuted => Theme.of(this).colorScheme.primary.withOpacity(0.35);

  Color get zCeladon => Theme.of(this).colorScheme.secondary;
  Color get zCeladonGlow => Theme.of(this).colorScheme.secondary.withOpacity(0.25);

  Color get zTextPrimary => Theme.of(this).colorScheme.onSurface;
  Color get zTextSecondary => Theme.of(this).colorScheme.onSurface.withOpacity(0.6);
  Color get zTextTertiary => Theme.of(this).colorScheme.onSurface.withOpacity(0.35);
  Color get zTextDisabled => Theme.of(this).colorScheme.onSurface.withOpacity(0.2);

  Color get zDivider => Theme.of(this).dividerTheme.color ?? Theme.of(this).colorScheme.outline;
  Color get zError => Theme.of(this).colorScheme.error;
  Color get zSuccess => const Color(0xFF6BAF7B);
  Color get zWarning => const Color(0xFFC2A050);

  Color get zFrostWhite => Theme.of(this).colorScheme.onSurface.withOpacity(0.04);
  Color get zFrostWhiteStrong => Theme.of(this).colorScheme.onSurface.withOpacity(0.08);
  Color get zFrostBlack => Theme.of(this).colorScheme.onSurface.withOpacity(0.02);

  LinearGradient get zAccentGradient => LinearGradient(
    colors: [Theme.of(this).colorScheme.primary, Theme.of(this).colorScheme.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get zDarkGradient => LinearGradient(
    colors: [Theme.of(this).scaffoldBackgroundColor, Theme.of(this).colorScheme.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}