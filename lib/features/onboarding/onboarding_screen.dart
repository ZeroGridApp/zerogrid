import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_logo.dart';
import '../../widgets/zero_button.dart';
import 'create_identity_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentPage < 3) {
      _goToPage(_currentPage + 1);
    } else {
      _navigateToCreateIdentity();
    }
  }

  void _navigateToCreateIdentity() {
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

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.zDarkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildPage1(isZh),
                  _buildPage2(isZh),
                  _buildPage3(isZh),
                  _buildPage4(isZh),
                ],
              ),
              _buildSkipButton(isZh),
              Positioned(
                left: 0,
                right: 0,
                bottom: ZeroSpacing.screenBottom + ZeroSpacing.xxl,
                child: _buildIndicators(),
              ),
              Positioned(
                left: ZeroSpacing.screenHorizontal,
                right: ZeroSpacing.screenHorizontal,
                bottom: ZeroSpacing.screenBottom,
                child: _buildBottomButton(isZh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(bool isZh) {
    return Positioned(
      top: ZeroSpacing.sm,
      right: ZeroSpacing.sm,
      child: TextButton(
        onPressed: _navigateToCreateIdentity,
        style: TextButton.styleFrom(
          foregroundColor: context.zTextSecondary,
          padding: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.md,
            vertical: ZeroSpacing.sm,
          ),
        ),
        child: Text(
          isZh ? '跳过' : 'Skip',
          style: ZeroTypography.body(context).copyWith(
            color: context.zTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: ZeroSpacing.xs),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? context.zAccent
                : context.zTextDisabled.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton(bool isZh) {
    final isLastPage = _currentPage == 3;
    if (isLastPage) {
      return ZeroButton(
        label: isZh ? '开始使用' : 'Get Started',
        onTap: _navigateToCreateIdentity,
        icon: Icons.arrow_forward_rounded,
      );
    }
    return ZeroButton(
      label: isZh ? '下一步' : 'Next',
      onTap: _onNext,
      icon: Icons.arrow_forward_rounded,
    );
  }

  Widget _buildIconCircle(IconData icon, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }

  Widget _buildPage1(bool isZh) {
    return _buildPageContent(
      icon: const ZeroLogo(size: 80, animated: false),
      title: isZh ? '欢迎来到 Zero' : 'Welcome to Zero',
      description: isZh
          ? '去中心化通信的新纪元。Zero 让你完全掌控自己的数据和身份，无需信任任何第三方服务器。'
          : 'A new era of decentralized communication. Zero gives you full control over your data and identity without trusting any third-party servers.',
      tagline: isZh ? '真正的隐私，由你掌控' : 'True privacy, in your hands',
    );
  }

  Widget _buildPage2(bool isZh) {
    return _buildPageContent(
      icon: _buildIconCircle(Icons.lock_rounded, context.zAccent),
      title: isZh ? '默认端到端加密' : 'Encrypted by Default',
      description: isZh
          ? '每条消息都使用 Double Ratchet 算法进行端到端加密。没有中间人可以读取你的对话内容，即使 Zero 也无法解密。'
          : 'Every message is end-to-end encrypted using the Double Ratchet algorithm. No intermediary can read your conversations — not even Zero.',
      tagline: isZh ? '数学保护你的每一句话' : 'Math protects every word you say',
    );
  }

  Widget _buildPage3(bool isZh) {
    return _buildPageContent(
      icon: _buildIconCircle(Icons.fingerprint, context.zSuccess),
      title: isZh ? '你的身份，你作主' : 'Your Identity, Your Rules',
      description: isZh
          ? 'ZeroID 基于 BIP39 助记词生成，实现自主主权身份。你的密钥只属于你，没有中心化机构可以冻结或撤销你的身份。'
          : 'ZeroID is generated from BIP39 mnemonics, enabling self-sovereign identity. Your keys belong to you alone — no centralized authority can freeze or revoke your identity.',
      tagline: isZh ? '你是自己数字身份的唯一主人' : 'You are the sole owner of your digital identity',
    );
  }

  Widget _buildPage4(bool isZh) {
    return _buildPageContent(
      icon: _buildIconCircle(Icons.rocket_launch_rounded, context.zWarning),
      title: isZh ? '准备就绪' : 'Ready to Begin',
      description: isZh
          ? '你已经了解了 Zero 的核心理念。现在让我们创建你的第一个身份，开启真正的隐私通信之旅。'
          : 'You now understand the core concepts of Zero. Let\'s create your first identity and begin your journey into truly private communication.',
      tagline: null,
    );
  }

  Widget _buildPageContent({
    required Widget icon,
    required String title,
    required String description,
    String? tagline,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          const Spacer(flex: 3),
          icon,
          SizedBox(height: ZeroSpacing.xxxl),
          Text(
            title,
            style: ZeroTypography.headline(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ZeroSpacing.md),
          Text(
            description,
            style: ZeroTypography.body(context),
            textAlign: TextAlign.center,
          ),
          if (tagline != null) ...[
            SizedBox(height: ZeroSpacing.lg),
            Text(
              tagline,
              style: ZeroTypography.caption(context).copyWith(
                color: context.zAccent,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}