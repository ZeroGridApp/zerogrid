import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/zero_card.dart';
import '../games/games_arcade.dart';
import '../oauth/zero_oauth_screen.dart';
import '../../services/oauth/zero_oauth_service.dart';
import '../../core/theme/zero_theme.dart';
import '../node/node_deploy_screen.dart';
import '../node/network_topology_screen.dart';
import '../node/node_monitor_screen.dart';
import '../node/nat_traversal_screen.dart';
import '../deployment/ipfs_deploy_screen.dart';
import '../developer/api_console_screen.dart';
import '../status/system_status_screen.dart';
import '../changelog/changelog_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _avatarColorIndex = 0;
  int _statusIndex = 0;
  String _bio = 'Building the decentralized future\u2026\none message at a time. \u{1f510}';
  String _location = 'San Francisco, CA';
  String _website = 'zero.me/alex';
  int _followers = 567;
  int _following = 1234;
  int _posts = 42;

  bool _pushNotificationsEnabled = true;
  bool _messagePreviewEnabled = true;
  bool _soundEnabled = true;
  bool _autoDownloadMedia = true;

  static const _avatarColors = [
    _AvatarColorKind.accent,
    _AvatarColorKind.celadon,
    _AvatarColorKind.success,
    _AvatarColorKind.warning,
    _AvatarColorKind.blue,
    _AvatarColorKind.purple,
  ];

  static const _statusList = [
    _StatusInfo('Online', _StatusColorKind.green),
    _StatusInfo('Away', _StatusColorKind.yellow),
    _StatusInfo('Busy', _StatusColorKind.red),
    _StatusInfo('Offline', _StatusColorKind.gray),
  ];

  Color _resolveAvatarColor(BuildContext context, _AvatarColorKind kind) {
    switch (kind) {
      case _AvatarColorKind.celadon:
        return context.zCeladon;
      case _AvatarColorKind.success:
        return context.zSuccess;
      case _AvatarColorKind.warning:
        return context.zWarning;
      case _AvatarColorKind.blue:
        return const Color(0xFF4A90D9);
      case _AvatarColorKind.purple:
        return const Color(0xFF7B6FDE);
      case _AvatarColorKind.accent:
      default:
        return context.zAccent;
    }
  }

  Color _resolveStatusColor(_StatusColorKind kind) {
    switch (kind) {
      case _StatusColorKind.yellow:
        return context.zWarning;
      case _StatusColorKind.red:
        return context.zError;
      case _StatusColorKind.gray:
        return context.zTextDisabled;
      case _StatusColorKind.green:
      default:
        return context.zSuccess;
    }
  }

  String _disappearingLabel(int seconds) {
    final l10n = AppLocalizations.of(context);
    switch (seconds) {
      case 0:
        return l10n.disabled;
      case 30:
        return '30s';
      case 60:
        return '1m';
      case 300:
        return '5m';
      case 3600:
        return '1h';
      case 86400:
        return '1d';
      default:
        return '$seconds s';
    }
  }

  void _showBioEditDialog() {
    final controller = TextEditingController(text: _bio);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Bio', style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
          decoration: InputDecoration(
            hintText: 'Tell the world about yourself...',
            hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
            filled: true,
            fillColor: context.zBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: context.zTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _bio = text);
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx).confirm, style: TextStyle(color: context.zAccent)),
          ),
        ],
      ),
    );
  }

  void _showLocationEditDialog() {
    final controller = TextEditingController(text: _location);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Location', style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary)),
        content: TextField(
          controller: controller,
          style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
          decoration: InputDecoration(
            hintText: 'Your location',
            hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
            filled: true,
            fillColor: context.zBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: context.zTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _location = text);
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx).confirm, style: TextStyle(color: context.zAccent)),
          ),
        ],
      ),
    );
  }

  void _showWebsiteEditDialog() {
    final controller = TextEditingController(text: _website);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Website', style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary)),
        content: TextField(
          controller: controller,
          style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
          decoration: InputDecoration(
            hintText: 'Your website link',
            hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
            filled: true,
            fillColor: context.zBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: context.zTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _website = text);
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx).confirm, style: TextStyle(color: context.zAccent)),
          ),
        ],
      ),
    );
  }

  void _showShareProfileSheet() {
    final app = ZeroApp.of(context);
    if (app == null) return;
    final l10n = AppLocalizations.of(context);
    final zeroId = 'Z8P2K5W1RT';
    final did = 'did:zero:ZA1B2C3D4E';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text('Share Profile', style: ZeroTypography.title(context)),
                const SizedBox(height: ZeroSpacing.lg),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: context.zBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.zFrostWhiteStrong),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 80, color: context.zAccent.withOpacity(0.6)),
                      const SizedBox(height: ZeroSpacing.sm),
                      Text(
                        zeroId,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: context.zAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ZeroSpacing.sm),
                Text(
                  did,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: context.zTextTertiary,
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShareActionChip(
                          icon: Icons.copy_outlined,
                          label: 'Copy ZeroID',
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$zeroId copied',
                                  style: ZeroTypography.body(this.context).copyWith(color: context.zBg),
                                ),
                                backgroundColor: context.zSuccess,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: ZeroSpacing.sm),
                      Expanded(
                        child: _ShareActionChip(
                          icon: Icons.fingerprint,
                          label: 'Copy DID',
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'DID copied',
                                  style: ZeroTypography.body(this.context).copyWith(color: context.zBg),
                                ),
                                backgroundColor: context.zSuccess,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ZeroSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                  child: SizedBox(
                    width: double.infinity,
                    child: _ShareActionChip(
                      icon: Icons.chat_bubble_outline,
                      label: 'Share via ZeroChat',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile shared to ZeroChat',
                              style: ZeroTypography.body(this.context).copyWith(color: context.zBg),
                            ),
                            backgroundColor: context.zSuccess,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatsModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.people_outline, color: context.zAccent, size: 22),
            const SizedBox(width: ZeroSpacing.sm),
            Text('Social Graph', style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.zAccent.withOpacity(0.08),
              ),
              child: Icon(Icons.account_tree_outlined, size: 48, color: context.zAccent.withOpacity(0.4)),
            ),
            const SizedBox(height: ZeroSpacing.md),
            Text(
              'Coming soon: Social graph',
              style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
            ),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              'View and explore your decentralized social connections in the Zero network.',
              style: ZeroTypography.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).ok, style: TextStyle(color: context.zAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final app = ZeroApp.of(context);
    if (app == null) return;
    final controller = TextEditingController(text: app.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Display Name', style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary)),
        content: TextField(
          controller: controller,
          style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
          decoration: InputDecoration(
            hintText: 'Enter display name',
            hintStyle: ZeroTypography.body(context).copyWith(color: context.zTextTertiary),
            filled: true,
            fillColor: context.zBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: context.zTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                app.setDisplayName(name);
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(ctx).confirm, style: TextStyle(color: context.zAccent)),
          ),
        ],
      ),
    );
  }

  void _showLockConfirm() {
    final l10n = AppLocalizations.of(context);
    final app = ZeroApp.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: context.zError, size: 20),
            SizedBox(width: ZeroSpacing.sm),
            Text(l10n.lockAndExit, style: ZeroTypography.title(context).copyWith(color: context.zError)),
          ],
        ),
        content: Text(
          'Your encrypted session will be locked. You\'ll need to verify your identity to return.',
          style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: context.zTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              app?.lockAndExit(context);
            },
            child: Text(l10n.confirm, style: TextStyle(color: context.zError)),
          ),
        ],
      ),
    );
  }

  void _showTimePickerSheet() {
    final l10n = AppLocalizations.of(context);
    final app = ZeroApp.of(context);
    if (app == null) return;
    final options = [0, 30, 60, 300, 3600, 86400];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text(l10n.disappearingMessages, style: ZeroTypography.title(context)),
                const SizedBox(height: ZeroSpacing.md),
                ...options.map((s) {
                  final label = _disappearingLabel(s);
                  final isSelected = app.disappearingTime == s;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                    child: ZeroCard(
                      onTap: () {
                        app.setDisappearingTime(s);
                        Navigator.pop(ctx);
                      },
                      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 2),
                      child: Row(
                        children: [
                          Text(label, style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary)),
                          Spacer(),
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: context.zAccent),
                              child: Icon(Icons.check, size: 16, color: context.zBg),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemePickerSheet() {
    final l10n = AppLocalizations.of(context);
    final app = ZeroApp.of(context);
    if (app == null) return;
    final currentId = app.themeId;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text(l10n.theme, style: ZeroTypography.title(context)),
                const SizedBox(height: ZeroSpacing.md),
                ...ZeroThemeConfig.all.map((theme) {
                  final isSelected = currentId == theme.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                    child: ZeroCard(
                      onTap: () {
                        app.setTheme(theme.id);
                        Navigator.pop(ctx);
                      },
                      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 2),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.previewBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.previewAccent.withOpacity(0.3)),
                            ),
                            child: Center(
                              child: Icon(
                                theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 16,
                                color: theme.previewAccent,
                              ),
                            ),
                          ),
                          SizedBox(width: ZeroSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(theme.name, style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary)),
                              Text(theme.nameZh, style: ZeroTypography.caption(context)),
                            ],
                          ),
                          const Spacer(),
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.previewAccent,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = ZeroApp.of(context);
    if (app == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.zSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: context.zDivider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: ZeroSpacing.lg),
                Text(l10n.language, style: ZeroTypography.title(context)),
                const SizedBox(height: ZeroSpacing.md),
                _LanguageOption(
                  label: '\u4e2d\u6587',
                  subtitle: '\u7b80\u4f53\u4e2d\u6587',
                  isSelected: app.locale.languageCode == 'zh',
                  onTap: () {
                    app.changeLanguage(const Locale('zh'));
                    Navigator.pop(ctx);
                  },
                ),
                _LanguageOption(
                  label: 'English',
                  subtitle: 'English',
                  isSelected: app.locale.languageCode == 'en',
                  onTap: () {
                    app.changeLanguage(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: ZeroSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBackupPhraseDialog() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: context.zWarning, size: 20),
            const SizedBox(width: ZeroSpacing.sm),
            Text(
              isZh ? '安全警告' : 'Security Warning',
              style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary),
            ),
          ],
        ),
        content: Text(
          isZh
              ? '请不要与任何人分享你的恢复助记词。任何拥有助记词的人都可以完全控制你的 ZeroID 和所有相关数据。请将助记词离线保存在安全的地方。'
              : 'Never share your recovery phrase with anyone. Anyone with this phrase can take full control of your ZeroID and all associated data. Keep it offline in a secure location.',
          style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isZh ? '我知道了' : 'I Understand',
              style: TextStyle(color: context.zAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isZh ? '清除缓存' : 'Clear Cache',
          style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary),
        ),
        content: Text(
          isZh ? '这将清除所有本地缓存数据，包括图片和文件缓存。聊天记录不会受影响。确定要继续吗？' : 'This will clear all locally cached data, including images and file caches. Chat history will not be affected. Continue?',
          style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isZh ? '取消' : 'Cancel',
              style: TextStyle(color: context.zTextTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    isZh ? '缓存已清除' : 'Cache cleared',
                    style: ZeroTypography.body(this.context).copyWith(color: context.zBg),
                  ),
                  backgroundColor: context.zSuccess,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              isZh ? '确认' : 'Confirm',
              style: TextStyle(color: context.zAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportStarted() {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh ? '导出已开始' : 'Export started',
          style: ZeroTypography.body(context).copyWith(color: context.zBg),
        ),
        backgroundColor: context.zSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showOpenSourceLicenses() {
    final isZh = ZeroTheme.isZh(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.zSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isZh ? '开源许可' : 'Open Source Licenses',
          style: ZeroTypography.title(context).copyWith(color: context.zTextPrimary),
        ),
        content: SingleChildScrollView(
          child: Text(
            isZh
                ? '本项目使用了以下开源组件：\n\n'
                    'Flutter SDK - MIT License\n'
                    'Dart SDK - BSD License\n\n'
                    'Zero Protocol Core - Apache 2.0\n'
                    'libp2p - MIT License\n'
                    'Noise Protocol Framework - MIT License\n'
                    'Double Ratchet Algorithm - MIT License\n\n'
                    '感谢所有开源社区的贡献者。'
                : 'This project uses the following open source components:\n\n'
                    'Flutter SDK - MIT License\n'
                    'Dart SDK - BSD License\n\n'
                    'Zero Protocol Core - Apache 2.0\n'
                    'libp2p - MIT License\n'
                    'Noise Protocol Framework - MIT License\n'
                    'Double Ratchet Algorithm - MIT License\n\n'
                    'Thanks to all open source contributors.',
            style: ZeroTypography.body(context).copyWith(color: context.zTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isZh ? '关闭' : 'Close',
              style: TextStyle(color: context.zAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String zhText, String enText) {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh ? zhText : enText,
          style: ZeroTypography.body(context).copyWith(color: context.zBg),
        ),
        backgroundColor: context.zAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = ZeroApp.of(context);
    if (app == null) return const SizedBox.shrink();
    final isZh = ZeroTheme.isZh(context);
    final currentTheme = app.currentTheme;
    final avatarColor = _resolveAvatarColor(context, _avatarColors[_avatarColorIndex]);
    final status = _statusList[_statusIndex];
    final statusColor = _resolveStatusColor(status.colorKind);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          children: [
            const SizedBox(height: ZeroSpacing.xl),
            _buildProfileHeader(context, app, l10n, avatarColor, status, statusColor),
            const SizedBox(height: ZeroSpacing.lg),
            _buildBioSection(context, l10n),
            const SizedBox(height: ZeroSpacing.lg),
            _buildStatsRow(context, l10n),
            const SizedBox(height: ZeroSpacing.lg),
            _buildActionButtons(context, l10n),
            const SizedBox(height: ZeroSpacing.lg),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? '游戏大厅' : 'Games Arcade',
              items: [
                _SettingItem(
                  icon: Icons.sports_esports_outlined,
                  label: isZh ? '迷你游戏' : 'Mini Games',
                  value: isZh ? '6款可玩' : '6 playable',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const GamesArcadeScreen()),
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? '通知' : 'Notifications',
              items: [
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  label: isZh ? '推送通知' : 'Push Notifications',
                  value: isZh ? '仅网页' : 'Web only',
                  trailing: Switch(
                    value: _pushNotificationsEnabled,
                    onChanged: (v) => setState(() => _pushNotificationsEnabled = v),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
                _SettingItem(
                  icon: Icons.message_outlined,
                  label: isZh ? '显示预览' : 'Show Preview',
                  value: '',
                  trailing: Switch(
                    value: _messagePreviewEnabled,
                    onChanged: (v) => setState(() => _messagePreviewEnabled = v),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
                _SettingItem(
                  icon: Icons.volume_up_outlined,
                  label: isZh ? '声音' : 'Sound',
                  value: '',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? 'ZeroID 授权' : 'ZeroID OAuth',
              items: [
                _SettingItem(
                  icon: Icons.app_registration_rounded,
                  label: isZh ? 'ZeroID 授权' : 'ZeroID OAuth',
                  value: _oauthConnectedCount(isZh),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroOAuthScreen()),
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: l10n.privacySecurity,
              items: [
                _SettingItem(
                  icon: Icons.lock_outline,
                  label: l10n.securityLock,
                  value: app.securityLock ? l10n.enabled : l10n.disabled,
                  trailing: Switch(
                    value: app.securityLock,
                    onChanged: (_) => app.toggleSecurityLock(),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
                _SettingItem(icon: Icons.vpn_lock_outlined, label: l10n.natStatus, value: 'Private'),
                _SettingItem(
                  icon: Icons.key_outlined,
                  label: isZh ? '显示恢复助记词' : 'Show Recovery Phrase',
                  value: '',
                  onTap: _showBackupPhraseDialog,
                ),
                _SettingItem(
                  icon: Icons.fingerprint,
                  label: isZh ? '指纹 / 面容' : 'Fingerprint / Face ID',
                  value: isZh ? '不可用' : 'Not available',
                ),
                _SettingItem(icon: Icons.enhanced_encryption, label: l10n.encryption, value: 'Double Ratchet'),
                _SettingItem(
                  icon: Icons.timer_outlined,
                  label: l10n.disappearingMessages,
                  value: _disappearingLabel(app.disappearingTime),
                  onTap: _showTimePickerSheet,
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: l10n.appearance,
              items: [
                _SettingItem(
                  icon: currentTheme.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  label: l10n.theme,
                  value: currentTheme.nameZh,
                  onTap: _showThemePickerSheet,
                ),
                _SettingItem(
                  icon: Icons.font_download_outlined,
                  label: l10n.language,
                  value: isZh ? '\u4e2d\u6587' : 'English',
                  onTap: () => _showLanguagePicker(context),
                ),
                _SettingItem(
                  icon: Icons.animation_outlined,
                  label: l10n.animations,
                  value: app.animationsEnabled ? l10n.enabled : l10n.disabled,
                  trailing: Switch(
                    value: app.animationsEnabled,
                    onChanged: (_) => app.toggleAnimations(),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? '数据与存储' : 'Data & Storage',
              items: [
                _SettingItem(
                  icon: Icons.storage_outlined,
                  label: isZh ? '本地存储' : 'Local Storage',
                  value: '12.4 MB',
                ),
                _SettingItem(
                  icon: Icons.cleaning_services_outlined,
                  label: isZh ? '清除缓存' : 'Clear Cache',
                  value: '',
                  onTap: _showClearCacheDialog,
                ),
                _SettingItem(
                  icon: Icons.file_download_outlined,
                  label: isZh ? '导出聊天数据' : 'Export Chat Data',
                  value: '',
                  onTap: _showExportStarted,
                ),
                _SettingItem(
                  icon: Icons.download_outlined,
                  label: isZh ? '自动下载媒体' : 'Auto-download Media',
                  value: '',
                  trailing: Switch(
                    value: _autoDownloadMedia,
                    onChanged: (v) => setState(() => _autoDownloadMedia = v),
                    activeColor: currentTheme.previewAccent,
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? '节点' : 'ZeroNode',
              items: [
                _SettingItem(
                  icon: Icons.dns_outlined,
                  label: isZh ? '部署节点' : 'Deploy Node',
                  value: isZh ? '配置向导' : 'Setup Wizard',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroNodeDeployScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.share_outlined,
                  label: isZh ? '网络拓扑' : 'Network Topology',
                  value: isZh ? 'P2P 可视化' : 'P2P Visual',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroNetworkTopologyScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.monitor_heart_outlined,
                  label: isZh ? '节点监控' : 'Node Monitor',
                  value: isZh ? '实时状态' : 'Live Status',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZeroNodeMonitorScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.router_rounded,
                  label: isZh ? 'NAT 穿透' : 'NAT Traversal',
                  value: isZh ? 'STUN/TURN/ICE' : 'STUN/TURN/ICE',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const NatTraversalScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.cloud_rounded,
                  label: isZh ? '去中心化部署' : 'Deploy to IPFS',
                  value: isZh ? 'IPFS · Arweave' : 'IPFS · Arweave',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const IpfsDeployScreen()),
                  ),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: l10n.about,
              items: [
                _SettingItem(icon: Icons.info_outline, label: l10n.version, value: '0.1.0 (Pre-Alpha)'),
                _SettingItem(icon: Icons.code_outlined, label: l10n.protocol, value: '/zero/1.0.0'),
                _SettingItem(icon: Icons.hub_outlined, label: l10n.networkPeers, value: '12 connected'),
                _SettingItem(
                  icon: Icons.article_outlined,
                  label: isZh ? '开源许可' : 'Open Source Licenses',
                  value: '',
                  onTap: _showOpenSourceLicenses,
                ),
                _SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  label: isZh ? '隐私政策' : 'Privacy Policy',
                  value: '',
                  onTap: () => _showSnackBar('即将推出', 'Coming soon'),
                ),
                _SettingItem(
                  icon: Icons.gavel_outlined,
                  label: isZh ? '服务条款' : 'Terms of Service',
                  value: '',
                  onTap: () => _showSnackBar('即将推出', 'Coming soon'),
                ),
                _SettingItem(
                  icon: Icons.bug_report_outlined,
                  label: isZh ? '报告问题' : 'Report a Bug',
                  value: '',
                  onTap: () => _showSnackBar('即将推出', 'Coming soon'),
                ),
              ],
            ),
            _buildSettingSection(
              context,
              l10n,
              title: isZh ? '开发者与支持' : 'Developer & Support',
              items: [
                _SettingItem(
                  icon: Icons.terminal_rounded,
                  label: isZh ? 'API 控制台' : 'API Console',
                  value: isZh ? '开发者工具' : 'Dev Tools',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ApiConsoleScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.dashboard_rounded,
                  label: isZh ? '系统状态' : 'System Status',
                  value: isZh ? '运行正常 99.97%' : 'Operational 99.97%',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SystemStatusScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.new_releases_rounded,
                  label: isZh ? '更新日志' : 'What\'s New',
                  value: isZh ? 'v0.6.0' : 'v0.6.0',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ChangelogScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.support_agent_rounded,
                  label: isZh ? '帮助与反馈' : 'Help & Feedback',
                  value: isZh ? 'FAQ · 反馈' : 'FAQ · Feedback',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SupportScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeroSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: _DestructiveButton(
                label: l10n.lockAndExit,
                onTap: _showLockConfirm,
              ),
            ),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ZeroAppState app,
    AppLocalizations l10n,
    Color avatarColor,
    _StatusInfo status,
    Color statusColor,
  ) {
    final displayName = app.displayName;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'Z';

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _avatarColorIndex = (_avatarColorIndex + 1) % _avatarColors.length;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [avatarColor, avatarColor.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    color: context.zBg,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.zSurface,
                    border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.md),
        GestureDetector(
          onTap: _showEditNameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.zTextPrimary,
                ),
              ),
              const SizedBox(width: ZeroSpacing.xs),
              Icon(Icons.edit_outlined, size: 16, color: context.zTextTertiary),
            ],
          ),
        ),
        const SizedBox(height: ZeroSpacing.xs),
        Text(
          '@Z8P2K5W1RT',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: context.zTextTertiary,
          ),
        ),
        const SizedBox(height: ZeroSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _statusIndex = (_statusIndex + 1) % _statusList.length;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(color: statusColor.withOpacity(0.25), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: ZeroSpacing.sm),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ZeroSpacing.md),
            GestureDetector(
              onTap: _showEditNameDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                  border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                ),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context, AppLocalizations l10n) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bio,
            style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary),
          ),
          const SizedBox(height: ZeroSpacing.md),
          _buildInfoRow(context, Icons.location_on_outlined, _location, _showLocationEditDialog),
          const SizedBox(height: ZeroSpacing.sm),
          _buildInfoRow(context, Icons.link, _website, _showWebsiteEditDialog),
          const SizedBox(height: ZeroSpacing.sm),
          _buildInfoRow(context, Icons.calendar_today_outlined, 'Joined May 2024', null),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.zTextTertiary),
          const SizedBox(width: ZeroSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: ZeroTypography.caption(context).copyWith(color: context.zTextSecondary),
            ),
          ),
          if (onTap != null)
            Icon(Icons.edit_outlined, size: 14, color: context.zTextDisabled),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _showStatsModal,
      child: ZeroCard(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
        child: Row(
          children: [
            _buildStatColumn(context, _formatCount(_following), 'Following'),
            Container(
              width: 0.5,
              height: 32,
              color: context.zDivider,
            ),
            _buildStatColumn(context, _formatCount(_followers), 'Followers'),
            Container(
              width: 0.5,
              height: 32,
              color: context.zDivider,
            ),
            _buildStatColumn(context, _formatCount(_posts), 'Posts'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.zTextPrimary,
            ),
          ),
          const SizedBox(height: ZeroSpacing.xs),
          Text(
            label,
            style: ZeroTypography.caption(context),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return k == k.roundToDouble() ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _oauthConnectedCount(bool isZh) {
    final service = ZeroOAuthService();
    service.seedOAuthData();
    final count = service.getConnectedApps('did:zero:ZA1B2C3D4E').length;
    return isZh ? '$count 个应用已连接' : '$count apps connected';
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.photo_camera_outlined,
            label: 'Edit Avatar',
            onTap: () {
              setState(() {
                _avatarColorIndex = (_avatarColorIndex + 1) % _avatarColors.length;
              });
            },
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.edit_note,
            label: 'Edit Bio',
            onTap: _showBioEditDialog,
          ),
        ),
        const SizedBox(width: ZeroSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.share_outlined,
            label: 'Share Profile',
            onTap: _showShareProfileSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ZeroSpacing.lg),
        Text(
          title.toUpperCase(),
          style: ZeroTypography.caption(context).copyWith(letterSpacing: 2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ZeroSpacing.sm),
        ZeroCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    onTap: entry.value.trailing != null ? null : entry.value.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 2),
                      child: Row(
                        children: [
                          Icon(entry.value.icon, size: 20, color: context.zTextSecondary),
                          SizedBox(width: ZeroSpacing.md),
                          Expanded(
                            child: Text(
                              entry.value.label,
                              style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary, fontSize: 15),
                            ),
                          ),
                          if (entry.value.trailing != null) ...[
                            if (entry.value.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: ZeroSpacing.sm),
                                child: Text(
                                  entry.value.value,
                                  style: ZeroTypography.caption(context).copyWith(color: context.zTextTertiary),
                                ),
                              ),
                            entry.value.trailing!,
                          ] else ...[
                            Text(
                              entry.value.value,
                              style: ZeroTypography.caption(context).copyWith(color: context.zAccent.withOpacity(0.6)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: context.zTextTertiary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

enum _AvatarColorKind { accent, celadon, success, warning, blue, purple }

enum _StatusColorKind { green, yellow, red, gray }

class _StatusInfo {
  final String label;
  final _StatusColorKind colorKind;
  const _StatusInfo(this.label, this.colorKind);
}

class _SettingItem {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
}

class _DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DestructiveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(color: context.zError.withOpacity(0.3), width: 0.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.zError,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
      child: ZeroCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.md - 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ZeroTypography.body(context).copyWith(color: context.zTextPrimary)),
                  SizedBox(height: 2),
                  Text(subtitle, style: ZeroTypography.caption(context)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.zAccent),
                child: Icon(Icons.check, size: 16, color: context.zBg),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurface,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: context.zAccent),
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              label,
              style: ZeroTypography.caption(context).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: context.zTextSecondary),
            const SizedBox(width: ZeroSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.zTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}