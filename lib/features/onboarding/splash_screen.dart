import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_logo.dart';
import 'onboarding_screen.dart';
import 'create_identity_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateIdentityScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToRecover() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
          const CreateIdentityScreen(recoverMode: true),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  const Spacer(flex: 3),
                  _buildLogo(),
                  const Spacer(),
                  _buildContent(),
                  const Spacer(flex: 3),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Opacity(
      opacity: _logoFade.value.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: _logoScale.value.clamp(0.0, 1.0),
        child: const ZeroLogo(size: 100, animated: true),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    return Opacity(
      opacity: _contentFade.value.clamp(0.0, 1.0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.appTitle,
              style: ZeroTypography.displayMedium(context).copyWith(
                fontWeight: FontWeight.w200,
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: ZeroSpacing.xs),
            Text(
              l10n.zeroChinese,
              style: ZeroTypography.headline(context).copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 12,
                color: context.zTextSecondary,
              ),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              l10n.splashTagline,
              style: ZeroTypography.caption(context).copyWith(
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: ZeroSpacing.xxxl),
            ZeroButton(
              label: l10n.createIdentity,
              onTap: _navigateToOnboarding,
              icon: Icons.fingerprint_outlined,
            ),
            const SizedBox(height: ZeroSpacing.md),
            ZeroButton(
              label: l10n.recoverIdentity,
              onTap: _navigateToRecover,
              outlined: true,
              icon: Icons.restore_outlined,
            ),
          ],
        ),
      ),
    );
  }
}