import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/identity_service.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_logo.dart';
import '../home/home_shell.dart';

class CreateIdentityScreen extends StatefulWidget {
  final bool recoverMode;

  const CreateIdentityScreen({super.key, this.recoverMode = false});

  @override
  State<CreateIdentityScreen> createState() => _CreateIdentityScreenState();
}

enum _CreateStep { generate, showSeed, verify, done }

class _CreateIdentityScreenState extends State<CreateIdentityScreen>
    with SingleTickerProviderStateMixin {
  final IdentityService _identityService = IdentityService();
  late final TabController _tabController;
  late final TextEditingController _recoverController;

  ZeroIdentity? _identity;
  bool _creating = false;

  _CreateStep _createStep = _CreateStep.generate;
  List<String> _words = [];
  List<String> _shuffledWords = [];
  int _verifiedIndex = 0;
  final Set<int> _selectedIndices = {};

  bool _recovering = false;
  String? _recoverError;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.recoverMode ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _recoverController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recoverController.dispose();
    super.dispose();
  }

  Future<void> _generateIdentity() async {
    setState(() => _creating = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    final identity = await _identityService.createIdentity();
    final words = identity.mnemonic.split(' ');
    final shuffled = List<String>.from(words)..shuffle(Random());

    setState(() {
      _identity = identity;
      _creating = false;
      _createStep = _CreateStep.showSeed;
      _words = words;
      _shuffledWords = shuffled;
    });
  }

  void _startVerification() {
    setState(() {
      _createStep = _CreateStep.verify;
      _verifiedIndex = 0;
      _selectedIndices.clear();
    });
  }

  void _tapVerifyWord(int shuffledIndex) {
    if (_selectedIndices.contains(shuffledIndex)) return;
    if (_verifiedIndex >= _words.length) return;

    final tappedWord = _shuffledWords[shuffledIndex];
    final expectedWord = _words[_verifiedIndex];

    if (tappedWord != expectedWord) return;

    setState(() {
      _selectedIndices.add(shuffledIndex);
      _verifiedIndex++;
    });

    if (_verifiedIndex >= _words.length) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _createStep = _CreateStep.done);
        }
      });
    }
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (_) => false,
    );
  }

  Future<void> _recover() async {
    final text = _recoverController.text.trim();
    final words = text.split(RegExp(r'\s+'));

    if (words.length != 12 || words.any((w) => w.isEmpty)) {
      setState(() => _recoverError = AppLocalizations.of(context).invalidMnemonic);
      return;
    }

    setState(() {
      _recovering = true;
      _recoverError = null;
    });

    await _identityService.createIdentityFromMnemonic(text);

    if (!mounted) return;

    setState(() => _recovering = false);
    _enterApp();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.recoverMode) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.zDarkGradient),
          child: SafeArea(
            child: _buildRecoverContent(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCreateTab(),
                    _buildRecoverContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: ZeroSpacing.screenHorizontal,
        right: ZeroSpacing.screenHorizontal,
        top: ZeroSpacing.lg,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
            gradient: context.zAccentGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: context.zBg,
          unselectedLabelColor: context.zTextSecondary,
          labelStyle: ZeroTypography.bodyBold(context).copyWith(
            fontSize: 14,
          ),
          unselectedLabelStyle: ZeroTypography.body(context).copyWith(
            fontSize: 14,
          ),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(text: l10n.createIdentity),
            Tab(text: l10n.recover),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    switch (_createStep) {
      case _CreateStep.generate:
        return _buildGenerateStep();
      case _CreateStep.showSeed:
        return _buildShowSeedStep();
      case _CreateStep.verify:
        return _buildVerifyStep();
      case _CreateStep.done:
        return _buildDoneStep();
    }
  }

  Widget _buildGenerateStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          Spacer(flex: 2),
          ZeroLogo(size: 72, animated: true),
          SizedBox(height: ZeroSpacing.xl),
          Text(
            l10n.yourZeroIdentity,
            style: ZeroTypography.headline(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            l10n.zeroTaglineDesc,
            textAlign: TextAlign.center,
            style: ZeroTypography.body(context),
          ),
          SizedBox(height: ZeroSpacing.xxl),
          if (_creating)
            Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.zAccent,
                  ),
                ),
                const SizedBox(height: ZeroSpacing.md),
                Text(
                  l10n.generatingIdentity,
                  style: ZeroTypography.caption(context),
                ),
              ],
            )
          else
            ZeroButton(
              label: l10n.generateSeed,
              onTap: _generateIdentity,
              icon: Icons.fingerprint_outlined,
            ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildShowSeedStep() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          SizedBox(height: ZeroSpacing.xxl),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.zAccentGradient,
              boxShadow: [
                BoxShadow(
                  color: context.zAccentGlow,
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.vpn_key_outlined, color: context.zBg, size: 28),
            ),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          Text(
            l10n.mnemonicTitle,
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            l10n.mnemonicDesc,
            textAlign: TextAlign.center,
            style: ZeroTypography.body(context),
          ),
          const SizedBox(height: ZeroSpacing.xl),
          _buildWordGrid(),
          const SizedBox(height: ZeroSpacing.lg),
          ZeroButton(
            label: l10n.copyPhrase,
            onTap: () {
              Clipboard.setData(ClipboardData(text: _words.join(' ')));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.phraseCopied,
                    style: ZeroTypography.body(context).copyWith(
                      color: context.zBg,
                    ),
                  ),
                  backgroundColor: context.zSuccess,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            outlined: true,
            icon: Icons.copy_outlined,
          ),
          SizedBox(height: ZeroSpacing.md),
          Container(
            padding: EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zFrostWhite,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
              border: Border.all(color: context.zWarning.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: context.zWarning),
                SizedBox(width: ZeroSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.seedWarning,
                    style: ZeroTypography.caption(context).copyWith(
                      color: context.zWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeroSpacing.xl),
          ZeroButton(
            label: l10n.saveSeedConfirm,
            onTap: _startVerification,
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildWordGrid() {
    return Container(
      padding: EdgeInsets.all(ZeroSpacing.md),
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
      ),
      child: Column(
        children: List.generate(4, (row) {
          return Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : ZeroSpacing.sm),
            child: Row(
              children: List.generate(3, (col) {
                final index = row * 3 + col;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: col == 0 ? 0 : ZeroSpacing.xs,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.sm,
                        vertical: ZeroSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: context.zFrostWhite,
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index + 1}',
                            style: ZeroTypography.monoSmall(context).copyWith(
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _words[index],
                            style: ZeroTypography.mono(context).copyWith(
                              color: context.zTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerifyStep() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          const SizedBox(height: ZeroSpacing.xxl),
          Text(
            l10n.verifyIdentity,
            style: ZeroTypography.headline(context),
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Text(
            l10n.verifyInstruction,
            style: ZeroTypography.body(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          _buildProgressIndicator(),
          const SizedBox(height: ZeroSpacing.xl),
          _buildShuffledWordGrid(),
          const SizedBox(height: ZeroSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.md,
        vertical: ZeroSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
        border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_verifiedIndex} / 12',
                style: ZeroTypography.mono(context).copyWith(
                  color: context.zAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (_verifiedIndex == 12)
                Icon(Icons.check_circle, color: context.zSuccess, size: 20),
            ],
          ),
          SizedBox(height: ZeroSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _verifiedIndex / 12,
              backgroundColor: context.zFrostWhiteStrong,
              valueColor: AlwaysStoppedAnimation<Color>(context.zAccent),
              minHeight: 3,
            ),
          ),
          if (_selectedIndices.isNotEmpty) ...[
            SizedBox(height: ZeroSpacing.md),
            Wrap(
              spacing: ZeroSpacing.xs,
              runSpacing: ZeroSpacing.xs,
              children: List.generate(_verifiedIndex, (i) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.sm,
                    vertical: ZeroSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.zFrostWhite,
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${i + 1}.',
                        style: ZeroTypography.monoSmall(context).copyWith(
                          color: context.zAccent,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _words[i],
                        style: ZeroTypography.mono(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShuffledWordGrid() {
    return Wrap(
      spacing: ZeroSpacing.sm,
      runSpacing: ZeroSpacing.sm,
      alignment: WrapAlignment.center,
      children: List.generate(_shuffledWords.length, (index) {
        final isSelected = _selectedIndices.contains(index);
        return GestureDetector(
          onTap: () => _tapVerifyWord(index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: ZeroSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.zAccent.withOpacity(0.15)
                  : context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              border: Border.all(
                color: isSelected
                    ? context.zAccent.withOpacity(0.3)
                    : context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            child: Text(
              _shuffledWords[index],
              style: ZeroTypography.mono(context).copyWith(
                color: isSelected ? context.zTextTertiary : context.zTextPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDoneStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          Spacer(flex: 2),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.zAccentGradient,
              boxShadow: [
                BoxShadow(
                  color: context.zAccentGlow,
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.zBg,
              size: 40,
            ),
          ),
          SizedBox(height: ZeroSpacing.xl),
          Text(
            l10n.verifySuccess,
            style: ZeroTypography.headline(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            l10n.seedConfirmed,
            textAlign: TextAlign.center,
            style: ZeroTypography.body(context),
          ),
          SizedBox(height: ZeroSpacing.xxl),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.md,
              vertical: ZeroSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  l10n.zeroIdLabel,
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: ZeroSpacing.xs),
                Text(
                  _identity?.zeroId ?? '',
                  style: ZeroTypography.mono(context).copyWith(
                    fontSize: 22,
                    color: context.zAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ZeroButton(
            label: l10n.enterApp,
            onTap: _enterApp,
            icon: Icons.arrow_forward_rounded,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildRecoverContent() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          SizedBox(height: ZeroSpacing.xxxl),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [context.zCeladon, context.zAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.zCeladonGlow,
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.restore_outlined, color: context.zBg, size: 28),
            ),
          ),
          SizedBox(height: ZeroSpacing.lg),
          Text(
            l10n.recover,
            style: ZeroTypography.headline(context),
          ),
          SizedBox(height: ZeroSpacing.sm),
          Text(
            l10n.recoverInstruction,
            textAlign: TextAlign.center,
            style: ZeroTypography.body(context),
          ),
          SizedBox(height: ZeroSpacing.xl),
          Container(
            padding: EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
              border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            child: TextField(
              controller: _recoverController,
              maxLines: 6,
              style: ZeroTypography.mono(context).copyWith(
                color: context.zTextPrimary,
                height: 1.8,
              ),
              decoration: InputDecoration(
                hintText: l10n.pasteWordsHint,
                hintStyle: ZeroTypography.mono(context).copyWith(
                  color: context.zTextDisabled,
                  height: 1.8,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_recoverError != null) {
                  setState(() => _recoverError = null);
                }
              },
            ),
          ),
          if (_recoverError != null) ...[
            SizedBox(height: ZeroSpacing.sm),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: context.zError),
                SizedBox(width: ZeroSpacing.xs),
                Text(
                  _recoverError!,
                  style: ZeroTypography.caption(context).copyWith(
                    color: context.zError,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: ZeroSpacing.lg),
          ZeroButton(
            label: _recovering ? l10n.recovering : l10n.recover,
            onTap: _recovering ? null : _recover,
            icon: _recovering ? null : Icons.restore_outlined,
          ),
          const SizedBox(height: ZeroSpacing.xxl),
        ],
      ),
    );
  }
}