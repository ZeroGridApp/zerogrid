import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/dns/zerodns_service.dart';
import '../../widgets/zero_card.dart';

const _letterColors = <Color>[
  Color(0xFFC89B5E),
  Color(0xFF7B8FC0),
  Color(0xFF6BAF7B),
  Color(0xFFC4615E),
  Color(0xFF937BC0),
  Color(0xFFC0A05A),
  Color(0xFF5E9BAF),
];

Color _colorForLetter(String letter) {
  final code = letter.toUpperCase().codeUnitAt(0);
  final index = (code - 65) % _letterColors.length;
  return _letterColors[index];
}

class ZeroDNSScreen extends StatefulWidget {
  const ZeroDNSScreen({super.key});

  @override
  State<ZeroDNSScreen> createState() => _ZeroDNSScreenState();
}

class _ZeroDNSScreenState extends State<ZeroDNSScreen> {
  final _dns = ZeroDNSService();
  final _searchController = TextEditingController();
  String _currentOwnerId = 'Z000000000';

  bool _seeded = false;
  bool _searching = false;
  bool? _available;
  int _searchPrice = 0;
  bool _searchPremium = false;
  List<ZeroDomain> _myDomains = [];

  @override
  void initState() {
    super.initState();
    _ensureSeeded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureSeeded() {
    if (!_seeded) {
      _dns.seedDemoDomains();
      _seeded = true;
    }
    _refreshDomains();
  }

  void _refreshDomains() {
    setState(() {
      _myDomains = _dns.getMyDomains(_currentOwnerId);
    });
  }

  int get _totalValue {
    return _myDomains.fold(0, (sum, d) => sum + d.price);
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() {
        _searching = false;
        _available = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      final available = _dns.checkAvailability(trimmed);
      final priceInfo = _dns.getPriceInfo(trimmed);
      _available = available;
      _searchPrice = priceInfo.price;
      _searchPremium = priceInfo.isPremium;
    });
  }

  void _onRegister(String name) {
    try {
      final domain = _dns.registerDomain(name, _currentOwnerId);
      setState(() {
        _searching = false;
        _available = null;
        _searchController.clear();
        _myDomains = _dns.getMyDomains(_currentOwnerId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${domain.name}.zero registered successfully!',
            style: ZeroTypography.caption(context).copyWith(
              color: context.zTextPrimary,
            ),
          ),
          backgroundColor: context.zSurfaceRaised,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.screenHorizontal,
            vertical: ZeroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: ZeroTypography.caption(context).copyWith(
              color: context.zTextPrimary,
            ),
          ),
          backgroundColor: context.zSurfaceRaised,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(
            horizontal: ZeroSpacing.screenHorizontal,
            vertical: ZeroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          ),
        ),
      );
    }
  }

  void _showDomainMenu(ZeroDomain domain) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.zTextDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Text(
              '${domain.name}.zero',
              style: ZeroTypography.headline(context).copyWith(
                color: context.zAccent,
              ),
            ),
            SizedBox(height: ZeroSpacing.md),
            _menuItem(
              ctx,
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onTap: () {
                Navigator.of(ctx).pop();
                _showTransferDialog(domain);
              },
            ),
            _menuItem(
              ctx,
              icon: Icons.copy,
              label: 'Copy Name',
              onTap: () {
                Clipboard.setData(ClipboardData(text: '${domain.name}.zero'));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Copied to clipboard',
                      style: ZeroTypography.caption(context).copyWith(
                        color: context.zTextPrimary,
                      ),
                    ),
                    backgroundColor: context.zSurfaceRaised,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.screenHorizontal,
                      vertical: ZeroSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    ),
                  ),
                );
              },
            ),
            _menuItem(
              ctx,
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteDomain(domain);
              },
            ),
            SizedBox(height: ZeroSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zSurfaceOverlay,
                  foregroundColor: context.zTextSecondary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    side: BorderSide(
                      color: context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).cancel,
                  style: ZeroTypography.bodyBold(context).copyWith(
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.md,
        ),
        margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
        decoration: BoxDecoration(
          color: context.zSurfaceOverlay.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
          border: Border.all(
            color: context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? context.zError : context.zTextSecondary,
            ),
            SizedBox(width: ZeroSpacing.md),
            Text(
              label,
              style: ZeroTypography.bodyBold(ctx).copyWith(
                color: isDestructive ? context.zError : context.zTextPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDialog(ZeroDomain domain) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(ZeroSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.zTextDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Text(
                'Transfer ${domain.name}.zero',
                style: ZeroTypography.title(context).copyWith(
                  color: context.zAccent,
                ),
              ),
              SizedBox(height: ZeroSpacing.xs),
              Text(
                'Enter the ZeroID of the new owner',
                style: ZeroTypography.body(context),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: context.zSurfaceOverlay.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                  border: Border.all(
                    color: context.zFrostWhiteStrong,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style: ZeroTypography.body(context).copyWith(
                    color: context.zTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter ZeroID (e.g. Z3K7M2N8XP)',
                    hintStyle: ZeroTypography.body(context).copyWith(
                      color: context.zTextTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.md,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newOwner = controller.text.trim();
                    if (newOwner.isEmpty) return;
                    try {
                      _dns.transferDomain(domain.name, newOwner);
                      Navigator.of(ctx).pop();
                      _refreshDomains();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${domain.name}.zero transferred to $newOwner',
                            style: ZeroTypography.caption(context).copyWith(
                              color: context.zTextPrimary,
                            ),
                          ),
                          backgroundColor: context.zSurfaceRaised,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.screenHorizontal,
                            vertical: ZeroSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString(),
                            style: ZeroTypography.caption(context).copyWith(
                              color: context.zTextPrimary,
                            ),
                          ),
                          backgroundColor: context.zSurfaceRaised,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.screenHorizontal,
                            vertical: ZeroSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zAccent,
                    foregroundColor: context.zBg,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Transfer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.zBg,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.zSurfaceOverlay,
                    foregroundColor: context.zTextSecondary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                      side: BorderSide(
                        color: context.zFrostWhiteStrong,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: ZeroTypography.bodyBold(context).copyWith(
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDomain(ZeroDomain domain) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        padding: EdgeInsets.all(ZeroSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.zTextDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ZeroSpacing.lg),
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: context.zError.withOpacity(0.7),
            ),
            SizedBox(height: ZeroSpacing.md),
            Text(
              'Delete ${domain.name}.zero?',
              style: ZeroTypography.headline(context).copyWith(
                color: context.zError,
              ),
            ),
            SizedBox(height: ZeroSpacing.sm),
            Text(
              'This action cannot be undone.',
              style: ZeroTypography.body(context),
            ),
            SizedBox(height: ZeroSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _dns.deleteDomain(domain.name);
                  Navigator.of(ctx).pop();
                  _refreshDomains();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${domain.name}.zero deleted',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                      ),
                      backgroundColor: context.zSurfaceRaised,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.symmetric(
                        horizontal: ZeroSpacing.screenHorizontal,
                        vertical: ZeroSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zError,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: ZeroSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.zSurfaceOverlay,
                  foregroundColor: context.zTextSecondary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                    side: BorderSide(
                      color: context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).cancel,
                  style: ZeroTypography.bodyBold(context).copyWith(
                    color: context.zTextSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterModal() {
    final controller = TextEditingController();
    int price = 0;
    bool premium = false;
    bool available = false;
    String name = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: EdgeInsets.all(ZeroSpacing.md),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(ZeroSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.zTextDisabled,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      'Register New Domain',
                      style: ZeroTypography.headline(context).copyWith(
                        color: context.zAccent,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      'Choose your .zero domain name',
                      style: ZeroTypography.body(context),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Container(
                      decoration: BoxDecoration(
                        color: context.zSurfaceOverlay.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                        border: Border.all(
                          color: name.isNotEmpty && available
                              ? context.zSuccess.withOpacity(0.5)
                              : name.isNotEmpty
                                  ? context.zError.withOpacity(0.5)
                                  : context.zFrostWhiteStrong,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        style: ZeroTypography.mono(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'yourname',
                          hintStyle: ZeroTypography.mono(context).copyWith(
                            color: context.zTextTertiary,
                          ),
                          suffixText: '.zero',
                          suffixStyle: ZeroTypography.mono(context).copyWith(
                            color: context.zAccent,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.md,
                          ),
                        ),
                        onChanged: (value) {
                          final trimmed = value.trim().toLowerCase();
                          final avail =
                              trimmed.isNotEmpty ? _dns.checkAvailability(trimmed) : false;
                          final info =
                              trimmed.isNotEmpty ? _dns.getPriceInfo(trimmed) : null;
                          setModalState(() {
                            name = trimmed;
                            available = avail;
                            premium = info?.isPremium ?? false;
                            price = info?.price ?? 0;
                          });
                        },
                      ),
                    ),
                    if (name.isNotEmpty) ...[
                      SizedBox(height: ZeroSpacing.md),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.md,
                          vertical: ZeroSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? context.zSuccess.withOpacity(0.08)
                              : context.zError.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                          border: Border.all(
                            color: available
                                ? context.zSuccess.withOpacity(0.3)
                                : context.zError.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              available
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 18,
                              color: available
                                  ? context.zSuccess
                                  : context.zError,
                            ),
                            SizedBox(width: ZeroSpacing.sm),
                            Expanded(
                              child: Text(
                                available
                                    ? '${name}.zero is available'
                                    : '${name}.zero is already taken',
                                style: ZeroTypography.bodyBold(context).copyWith(
                                  fontSize: 13,
                                  color: available
                                      ? context.zSuccess
                                      : context.zError,
                                ),
                              ),
                            ),
                            if (available) ...[
                              if (premium)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ZeroSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.zWarning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: context.zWarning,
                                    ),
                                  ),
                                ),
                              SizedBox(width: ZeroSpacing.sm),
                              Text(
                                '$price ZERO',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: context.zAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: ZeroSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (available && name.isNotEmpty)
                            ? () {
                                final domainName = name;
                                Navigator.of(ctx).pop();
                                _onRegister(domainName);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zAccent,
                          foregroundColor: context.zBg,
                          disabledBackgroundColor: context.zTextDisabled,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (available && name.isNotEmpty)
                                ? context.zBg
                                : context.zTextTertiary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.zSurfaceOverlay,
                          foregroundColor: context.zTextSecondary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                            side: BorderSide(
                              color: context.zFrostWhiteStrong,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: context.zTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [context.zAccent, context.zCeladon],
          ).createShader(bounds),
          child: Text(
            'ZeroDNS · .zero Domains',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterModal,
        backgroundColor: context.zSurface,
        foregroundColor: context.zAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
          side: BorderSide(
            color: context.zAccentMuted.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        icon: Icon(Icons.add, size: 20, color: context.zAccent),
        label: Text(
          'Register New Domain',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.zAccent,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildStatsHeader()),
          SliverToBoxAdapter(child: _buildSearchSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: ZeroSpacing.screenHorizontal,
                right: ZeroSpacing.screenHorizontal,
                top: ZeroSpacing.lg,
                bottom: ZeroSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'MY DOMAINS',
                    style: ZeroTypography.title(context).copyWith(
                      color: context.zTextSecondary,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_myDomains.length} domains',
                    style: ZeroTypography.caption(context).copyWith(
                      color: context.zAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_myDomains.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ZeroSpacing.screenHorizontal,
                  vertical: ZeroSpacing.xxl,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.language_outlined,
                      size: 56,
                      color: context.zTextDisabled,
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      'No domains yet',
                      style: ZeroTypography.bodyBold(context).copyWith(
                        color: context.zTextTertiary,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      'Register your first .zero domain',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildDomainTile(_myDomains[i]),
                childCount: _myDomains.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.md,
        ZeroSpacing.screenHorizontal,
        ZeroSpacing.sm,
      ),
      child: ZeroCard(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.lg,
          vertical: ZeroSpacing.md,
        ),
        borderRadius: ZeroSpacing.cardRadius,
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                Icons.language,
                '${_myDomains.length}',
                'Total Domains',
              ),
            ),
            Container(
              width: 0.5,
              height: 48,
              color: context.zDivider.withOpacity(0.3),
            ),
            Expanded(
              child: _statItem(
                Icons.monetization_on_outlined,
                '$_totalValue ZERO',
                'Total Value',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.zAccent.withOpacity(0.7)),
        SizedBox(height: ZeroSpacing.xs),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [context.zTextPrimary, context.zTextSecondary.withOpacity(0.6)],
          ).createShader(bounds),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              color: context.zTextPrimary,
            ),
          ),
        ),
        SizedBox(height: ZeroSpacing.xs),
        Text(
          label,
          style: ZeroTypography.caption(context).copyWith(
            letterSpacing: 1,
            color: context.zTextTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.zSurface,
              borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
              border: Border.all(
                color: context.zFrostWhiteStrong,
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search .zero domain...',
                hintStyle: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: context.zTextTertiary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: context.zTextTertiary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ZeroSpacing.md,
                ),
              ),
            ),
          ),
          if (_searching) SizedBox(height: ZeroSpacing.sm),
          if (_searching) _buildSearchResult(),
        ],
      ),
    );
  }

  Widget _buildSearchResult() {
    final name = _searchController.text.trim().toLowerCase();
    final isTaken = !(_available ?? false);

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      borderRadius: ZeroSpacing.cardRadiusSm,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _colorForLetter(name.isNotEmpty ? name[0] : 'a').withOpacity(0.2),
                  _colorForLetter(name.isNotEmpty ? name[0] : 'a').withOpacity(0.08),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _colorForLetter(name.isNotEmpty ? name[0] : 'a'),
              ),
            ),
          ),
          SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name.zero',
                  style: ZeroTypography.mono(context).copyWith(
                    color: context.zTextPrimary,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isTaken ? Icons.close : Icons.check,
                      size: 14,
                      color: isTaken ? context.zError : context.zSuccess,
                    ),
                    SizedBox(width: ZeroSpacing.xs),
                    Text(
                      isTaken ? 'Already registered' : 'Available',
                      style: ZeroTypography.caption(context).copyWith(
                        color: isTaken ? context.zError : context.zSuccess,
                      ),
                    ),
                    if (!isTaken && _searchPremium) ...[
                      SizedBox(width: ZeroSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.zWarning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.zWarning.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: context.zWarning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isTaken) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_searchPrice ZERO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.zAccent,
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _onRegister(name),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.md,
                      vertical: ZeroSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.zAccent, context.zCeladon],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.zBg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDomainTile(ZeroDomain domain) {
    final isActive = domain.expiresAt.isAfter(DateTime.now());
    final daysUntilExpiry = domain.expiresAt.difference(DateTime.now()).inDays;
    final isGrace = !isActive && daysUntilExpiry > -90;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.screenHorizontal,
        vertical: ZeroSpacing.xs,
      ),
      child: ZeroCard(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.md,
        ),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _colorForLetter(domain.name[0]).withOpacity(0.2),
                    _colorForLetter(domain.name[0]).withOpacity(0.08),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                domain.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _colorForLetter(domain.name[0]),
                ),
              ),
            ),
            SizedBox(width: ZeroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.name,
                    style: ZeroTypography.mono(context).copyWith(
                      color: context.zTextPrimary,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ZeroSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? context.zSuccess.withOpacity(0.08)
                              : isGrace
                                  ? context.zWarning.withOpacity(0.1)
                                  : context.zError.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isActive
                                ? context.zSuccess.withOpacity(0.3)
                                : isGrace
                                    ? context.zWarning.withOpacity(0.3)
                                    : context.zError.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          isActive ? 'Active' : isGrace ? 'Grace' : 'Expired',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? context.zSuccess
                                : isGrace
                                    ? context.zWarning
                                    : context.zError,
                          ),
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Text(
                        _formatDate(domain.expiresAt),
                        style: ZeroTypography.caption(context).copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'DID: ${domain.resolution['zeroId'] ?? '—'}',
                    style: ZeroTypography.monoSmall(context).copyWith(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (domain.isPremium)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.zWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: context.zWarning,
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'transfer':
                        _showTransferDialog(domain);
                        break;
                      case 'delete':
                        _confirmDeleteDomain(domain);
                        break;
                      case 'copy':
                        Clipboard.setData(
                          ClipboardData(text: '${domain.name}.zero'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${domain.name}.zero copied',
                              style: ZeroTypography.caption(context).copyWith(
                                color: context.zTextPrimary,
                              ),
                            ),
                            backgroundColor: context.zSurfaceRaised,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.screenHorizontal,
                              vertical: ZeroSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ZeroSpacing.chipRadius,
                              ),
                            ),
                          ),
                        );
                        break;
                    }
                  },
                  color: context.zSurfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                    side: BorderSide(
                      color: context.zFrostWhiteStrong,
                      width: 0.5,
                    ),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'transfer',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 18,
                            color: context.zTextSecondary,
                          ),
                          SizedBox(width: ZeroSpacing.sm),
                          Text(
                            'Transfer',
                            style: ZeroTypography.body(context).copyWith(
                              color: context.zTextPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18, color: context.zTextSecondary),
                          SizedBox(width: ZeroSpacing.sm),
                          Text(
                            'Copy',
                            style: ZeroTypography.body(context).copyWith(
                              color: context.zTextPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: context.zError),
                          SizedBox(width: ZeroSpacing.sm),
                          Text(
                            'Delete',
                            style: ZeroTypography.body(context).copyWith(
                              color: context.zError,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: context.zTextTertiary,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}