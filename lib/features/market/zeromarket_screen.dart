import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../services/market/zeromarket_service.dart';
import '../../widgets/zero_card.dart';

class ZeroMarketScreen extends StatefulWidget {
  const ZeroMarketScreen({super.key});

  @override
  State<ZeroMarketScreen> createState() => _ZeroMarketScreenState();
}

class _ZeroMarketScreenState extends State<ZeroMarketScreen> {
  final _marketService = ZeroMarketService();

  String _selectedCategory = 'All';
  String _sortBy = 'newest';
  List<MarketListing> _listings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  final _currentUserId = 'did:zero:demo_buyer';
  final _currentUserName = 'ZeroUser';

  List<Uint8List> _selectedImages = [];

  void _pickImage(void Function(Uint8List) onPicked) {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((e) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((_) {
          onPicked(reader.result as Uint8List);
        });
      }
    });
  }

  String _trCategory(String category, bool isZh) {
    switch (category) {
      case 'All': return isZh ? '全部' : 'All';
      case 'Electronics': return isZh ? '电子产品' : 'Electronics';
      case 'Fashion': return isZh ? '时尚' : 'Fashion';
      case 'Collectibles': return isZh ? '收藏品' : 'Collectibles';
      case 'Digital Goods': return isZh ? '数字商品' : 'Digital Goods';
      case 'Services': return isZh ? '服务' : 'Services';
      default: return category;
    }
  }

  String _trStatus(String status, bool isZh) {
    switch (status) {
      case 'Active': return isZh ? '在售' : 'Active';
      case 'Escrow': return isZh ? '托管中' : 'Escrow';
      case 'Completed': return isZh ? '已完成' : 'Completed';
      case 'Locked': return isZh ? '已锁定' : 'Locked';
      case 'Shipped': return isZh ? '已发货' : 'Shipped';
      case 'Delivered': return isZh ? '已签收' : 'Delivered';
      case 'Disputed': return isZh ? '争议中' : 'Disputed';
      default: return status;
    }
  }

  String _trCondition(String condition, bool isZh) {
    switch (condition) {
      case 'New': return isZh ? '全新' : 'New';
      case 'Like New': return isZh ? '几乎全新' : 'Like New';
      case 'Used': return isZh ? '二手' : 'Used';
      default: return condition;
    }
  }

  @override
  void initState() {
    super.initState();
    _marketService.seedDemoListings();
    _loadListings();
  }

  void _loadListings() {
    setState(() {
      _listings = _marketService.getListings(
        category: _selectedCategory,
        sortBy: _sortBy,
      );
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _loadListings();
    setState(() => _isRefreshing = false);
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _loadListings();
    });
  }

  void _onSortChanged(String? sortBy) {
    if (sortBy == null) return;
    setState(() {
      _sortBy = sortBy;
      _loadListings();
    });
  }

  void _showListingDetail(MarketListing listing) {
    final isZh = ZeroTheme.isZh(context);
    final usdPrice = (listing.price * _marketService.zeroUsdRate).toStringAsFixed(2);
    final stars = _buildStarRating(listing.averageRating);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: SingleChildScrollView(
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
              if (listing.images.isNotEmpty && listing.images.first.startsWith('data:image'))
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: listing.images.length,
                    itemBuilder: (_, i) {
                      final img = listing.images[i];
                      final base64Str = img.split(',')[1];
                      return Padding(
                        padding: EdgeInsets.only(right: ZeroSpacing.sm),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                          child: Image.memory(
                            base64Decode(base64Str),
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Text(
                    listing.images.isNotEmpty ? listing.images.first : '📦',
                    style: TextStyle(fontSize: 72),
                  ),
                ),
              SizedBox(height: ZeroSpacing.md),
              Text(
                listing.title,
                style: ZeroTypography.headline(context),
              ),
              SizedBox(height: ZeroSpacing.sm),
              Row(
                children: [
                  Text(
                    '${listing.price.toStringAsFixed(0)} ZERO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.zAccent,
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.sm),
                  Text(
                    '≈ \$$usdPrice',
                    style: ZeroTypography.body(context).copyWith(
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(listing.status, isZh),
                ],
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              Text(
                isZh ? '描述' : 'Description',
                style: ZeroTypography.caption(context).copyWith(
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ZeroSpacing.sm),
              Text(
                listing.description,
                style: ZeroTypography.body(context),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              Row(
                children: [
                  _buildInfoChip(Icons.info_outline, isZh ? _trCondition(listing.condition, isZh) : listing.condition, context.zCeladon),
                  SizedBox(width: ZeroSpacing.sm),
                  _buildInfoChip(Icons.location_on_outlined, listing.location, context.zWarning),
                ],
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          context.zAccent.withOpacity(0.2),
                          context.zAccent.withOpacity(0.08),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      listing.sellerName[0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.zAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.sellerName,
                          style: ZeroTypography.bodyBold(context),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            ...stars,
                            SizedBox(width: ZeroSpacing.xs),
                            Text(
                              '(${listing.totalRatings})',
                              style: ZeroTypography.caption(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ZeroSpacing.lg),
              if (listing.status == 'Active')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showOrderConfirmation(listing);
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
                      isZh ? '用 ZERO 购买' : 'Buy with ZERO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
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
                      side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                    ),
                  ),
                  child: Text(
                    isZh ? '关闭' : 'Close',
                    style: ZeroTypography.bodyBold(context).copyWith(
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderConfirmation(MarketListing listing) {
    final isZh = ZeroTheme.isZh(context);
    final usdPrice = (listing.price * _marketService.zeroUsdRate).toStringAsFixed(2);
    final savedAddresses = _marketService.getSavedAddresses();
    String selectedAddressId = savedAddresses.isNotEmpty ? savedAddresses.first['id'] ?? '' : '';
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String deliveryMethod = 'express';
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(ZeroSpacing.md),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isUseCustomAddress = selectedAddressId.isEmpty;
            final selectedAddr = isUseCustomAddress
                ? null
                : savedAddresses.firstWhere(
                    (a) => a['id'] == selectedAddressId,
                    orElse: () => <String, String>{},
                  );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              padding: EdgeInsets.all(ZeroSpacing.lg),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          context.zAccent.withOpacity(0.2),
                          context.zCeladon.withOpacity(0.08),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.lock_outline,
                      size: 28,
                      color: context.zAccent,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Text(
                    isZh ? '确认订单' : 'Confirm Order',
                    style: ZeroTypography.title(context).copyWith(
                      color: context.zAccent,
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  Text(
                    isZh ? '你将购买：' : 'You are about to purchase:',
                    style: ZeroTypography.caption(context),
                  ),
                  SizedBox(height: ZeroSpacing.sm),
                  Text(
                    listing.title,
                    style: ZeroTypography.bodyBold(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${listing.price.toStringAsFixed(0)} ZERO',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.zAccent,
                        ),
                      ),
                      SizedBox(width: ZeroSpacing.sm),
                      Text(
                        '≈ \$$usdPrice',
                        style: ZeroTypography.body(context).copyWith(
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  ZeroCard(
                    padding: EdgeInsets.all(ZeroSpacing.md),
                    borderRadius: ZeroSpacing.cardRadiusSm,
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 18, color: context.zAccent),
                        SizedBox(width: ZeroSpacing.sm),
                        Expanded(
                          child: Text(
                            isZh ? 'ZERO 已锁定在托管中，确认收货后释放' : 'ZERO locked in escrow until delivery confirmed',
                            style: ZeroTypography.caption(context).copyWith(
                              color: context.zAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
                          SizedBox(height: ZeroSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: context.zAccent),
                              SizedBox(width: ZeroSpacing.xs),
                              Text(
                                isZh ? '收货地址' : 'Shipping Address',
                                style: ZeroTypography.caption(context).copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  await _showAddressManager();
                                  _showOrderConfirmation(listing);
                                },
                                child: Text(
                                  isZh ? '管理地址' : 'Manage Addresses',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.zCeladon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
                          if (savedAddresses.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(bottom: ZeroSpacing.sm),
                              decoration: BoxDecoration(
                                color: context.zSurfaceOverlay.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
                                border: Border.all(
                                  color: context.zFrostWhiteStrong,
                                  width: 0.5,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedAddressId,
                                  isExpanded: true,
                                  dropdownColor: context.zSurfaceRaised,
                                  style: ZeroTypography.body(context).copyWith(
                                    color: context.zTextPrimary,
                                    fontSize: 13,
                                  ),
                                  items: [
                                    ...savedAddresses.map((addr) {
                                      final name = addr['name'] ?? '';
                                      final street = addr['street'] ?? '';
                                      final isDefault = addr['isDefault'] == 'true';
                                      return DropdownMenuItem<String>(
                                        value: addr['id'],
                                        child: Row(
                                          children: [
                                            Icon(Icons.home_outlined, size: 14, color: context.zTextTertiary),
                                            SizedBox(width: ZeroSpacing.xs),
                                            Expanded(
                                              child: Text(
                                                '$name${isDefault ? ' 🏷️' : ''} - $street',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const DropdownMenuItem<String>(
                                      value: '',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFFC2A050)),
                                          SizedBox(width: 4),
                                          Text('✏️ Custom / 自定义', style: TextStyle(fontSize: 12, color: Color(0xFFC2A050))),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setDialogState(() {
                                      selectedAddressId = val ?? '';
                                    });
                                  },
                                ),
                              ),
                            ),
                          if (isUseCustomAddress)
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
                                controller: addressController,
                                maxLines: 2,
                                style: ZeroTypography.body(context).copyWith(
                                  color: context.zTextPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: isZh ? '输入详细收货地址' : 'Enter shipping address',
                                  hintStyle: ZeroTypography.body(context).copyWith(
                                    color: context.zTextTertiary,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: ZeroSpacing.md,
                                    vertical: ZeroSpacing.md,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: ZeroSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 16, color: context.zCeladon),
                              SizedBox(width: ZeroSpacing.xs),
                              Text(
                                isZh ? '联系电话' : 'Contact Phone',
                                style: ZeroTypography.caption(context).copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
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
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: ZeroTypography.body(context).copyWith(
                                color: context.zTextPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: isZh ? '+86 138-0000-0000' : '+1 415-555-0000',
                                hintStyle: ZeroTypography.body(context).copyWith(
                                  color: context.zTextTertiary,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(Icons.phone_outlined, size: 18, color: context.zTextTertiary),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.md,
                                  vertical: ZeroSpacing.md,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: ZeroSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: context.zCeladon),
                              SizedBox(width: ZeroSpacing.xs),
                              Text(
                                isZh ? '电子邮箱' : 'Email',
                                style: ZeroTypography.caption(context).copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
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
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: ZeroTypography.body(context).copyWith(
                                color: context.zTextPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: isZh ? 'your@email.com' : 'your@email.com',
                                hintStyle: ZeroTypography.body(context).copyWith(
                                  color: context.zTextTertiary,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(Icons.email_outlined, size: 18, color: context.zTextTertiary),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.md,
                                  vertical: ZeroSpacing.md,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: ZeroSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 16, color: context.zAccent),
                              SizedBox(width: ZeroSpacing.xs),
                              Text(
                                isZh ? '配送方式' : 'Delivery Method',
                                style: ZeroTypography.caption(context).copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
                          Wrap(
                            spacing: ZeroSpacing.sm,
                            runSpacing: ZeroSpacing.sm,
                            children: [
                              _buildDeliveryChip(
                                Icons.local_shipping,
                                isZh ? '快递' : 'Express',
                                'express',
                                deliveryMethod == 'express',
                                context.zAccent,
                                () => setDialogState(() => deliveryMethod = 'express'),
                              ),
                              _buildDeliveryChip(
                                Icons.cloud_download_outlined,
                                isZh ? '数字' : 'Digital',
                                'digital',
                                deliveryMethod == 'digital',
                                context.zCeladon,
                                () => setDialogState(() => deliveryMethod = 'digital'),
                              ),
                              _buildDeliveryChip(
                                Icons.store_outlined,
                                isZh ? '自提' : 'Pickup',
                                'pickup',
                                deliveryMethod == 'pickup',
                                context.zWarning,
                                () => setDialogState(() => deliveryMethod = 'pickup'),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.notes_outlined, size: 16, color: context.zTextTertiary),
                              SizedBox(width: ZeroSpacing.xs),
                              Text(
                                isZh ? '订单备注（可选）' : 'Order Note (optional)',
                                style: ZeroTypography.caption(context).copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.sm),
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
                              controller: noteController,
                              maxLines: 2,
                              style: ZeroTypography.body(context).copyWith(
                                color: context.zTextPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: isZh ? '给卖家的留言...' : 'Message to seller...',
                                hintStyle: ZeroTypography.body(context).copyWith(
                                  color: context.zTextTertiary,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.md,
                                  vertical: ZeroSpacing.md,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: ZeroSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final shippingAddr = isUseCustomAddress
                            ? addressController.text.trim()
                            : '${selectedAddr?['name'] ?? ''}, ${selectedAddr?['phone'] ?? ''}, ${selectedAddr?['provinceCity'] ?? ''}, ${selectedAddr?['street'] ?? ''}';
                        try {
                          final order = _marketService.placeOrder(
                            listing.id,
                            _currentUserId,
                            _currentUserName,
                            shippingAddress: shippingAddr.isNotEmpty ? shippingAddr : null,
                            contactPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                            contactEmail: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                            deliveryMethod: deliveryMethod,
                            orderNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                          );
                          Navigator.of(ctx).pop();
                          _loadListings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isZh ? '订单已创建！${order.escrowedZero.toStringAsFixed(0)} ZERO 已锁定在托管中。' : 'Order placed! ${order.escrowedZero.toStringAsFixed(0)} ZERO locked in escrow.',
                                style: ZeroTypography.caption(context).copyWith(
                                  color: context.zTextPrimary,
                                ),
                              ),
                              backgroundColor: context.zSurfaceRaised,
                              duration: const Duration(seconds: 3),
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
                                isZh ? '错误：$e' : 'Error: $e',
                                style: ZeroTypography.caption(context).copyWith(
                                  color: context.zError,
                                ),
                              ),
                              backgroundColor: context.zSurfaceRaised,
                              duration: const Duration(seconds: 3),
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
                        isZh ? '确认购买' : 'Confirm Purchase',
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
                          side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                        ),
                      ),
                      child: Text(
                        isZh ? '取消' : 'Cancel',
                        style: ZeroTypography.bodyBold(context).copyWith(
                          color: context.zTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSellItemModal() {
    final isZh = ZeroTheme.isZh(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = ZeroMarketService.categories.first;
    String selectedCondition = 'New';
    _selectedImages = [];

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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: SingleChildScrollView(
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
                      'Sell Item',
                      style: ZeroTypography.title(context).copyWith(
                        color: context.zAccent,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    Text(
                      isZh ? '商品图片' : 'Product Images',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Row(
                      children: List.generate(3, (index) {
                        if (index < _selectedImages.length) {
                          return Container(
                            width: 72,
                            height: 72,
                            margin: EdgeInsets.only(right: ZeroSpacing.sm),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                                  child: Image.memory(
                                    _selectedImages[index],
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() {
                                      _selectedImages.removeAt(index);
                                    }),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: context.zError,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: context.zBg,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: () {
                            _pickImage((bytes) {
                              setModalState(() {
                                _selectedImages.add(bytes);
                              });
                            });
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            margin: EdgeInsets.only(right: ZeroSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              size: 28,
                              color: context.zTextTertiary,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '标题' : 'Title',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
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
                        controller: titleController,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '你要卖什么？' : 'What are you selling?',
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
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '描述' : 'Description',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
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
                        controller: descriptionController,
                        maxLines: 3,
                        style: ZeroTypography.body(context).copyWith(
                          color: context.zTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isZh ? '描述你的物品...' : 'Describe your item...',
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
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? 'ZERO 价格' : 'Price in ZERO',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
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
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.zAccent,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.zTextTertiary,
                          ),
                          suffixText: 'ZERO',
                          suffixStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.zAccent,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ZeroSpacing.md,
                            vertical: ZeroSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '分类' : 'Category',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Wrap(
                      spacing: ZeroSpacing.sm,
                      runSpacing: ZeroSpacing.sm,
                      children: ZeroMarketService.categories.map((cat) {
                        final isSelected = cat == selectedCategory;
                        final emoji = ZeroMarketService.getCategoryEmoji(cat);
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = cat),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.zAccent.withOpacity(0.15)
                                  : context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: isSelected
                                    ? context.zAccent.withOpacity(0.4)
                                    : context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '$emoji ${_trCategory(cat, isZh)}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? context.zAccent
                                    : context.zTextTertiary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '成色' : 'Condition',
                      style: ZeroTypography.caption(context).copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Wrap(
                      spacing: ZeroSpacing.sm,
                      runSpacing: ZeroSpacing.sm,
                      children: ['New', 'Like New', 'Used'].map((cond) {
                        final isSelected = cond == selectedCondition;
                        final displayCond = _trCondition(cond, isZh);
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCondition = cond),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.zCeladon.withOpacity(0.15)
                                  : context.zSurfaceOverlay.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: isSelected
                                    ? context.zCeladon.withOpacity(0.4)
                                    : context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              displayCond,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? context.zCeladon
                                    : context.zTextTertiary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: ZeroSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          final price = double.tryParse(priceController.text.trim());

                          if (title.isEmpty || description.isEmpty || price == null || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isZh ? '请填写所有字段并确保数值有效' : 'Please fill in all fields with valid values',
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
                            return;
                          }

                          _marketService.createListing(
                            title: title,
                            description: description,
                            price: price,
                            sellerId: _currentUserId,
                            sellerName: _currentUserName,
                            category: selectedCategory,
                            images: _selectedImages.map((img) => 'data:image/png;base64,${base64Encode(img)}').toList(),
                            condition: selectedCondition,
                            location: 'Global',
                          );

                          Navigator.of(ctx).pop();
                          _loadListings();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isZh ? '列表创建成功！' : 'Listing created successfully!',
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
                          backgroundColor: context.zAccent,
                          foregroundColor: context.zBg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                          ),
                        ),
                        child: Text(
                          isZh ? '创建列表' : 'Create Listing',
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
                            side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                          ),
                        ),
                        child: Text(
                          isZh ? '取消' : 'Cancel',
                          style: ZeroTypography.bodyBold(context).copyWith(
                            color: context.zTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMyOrders() {
    final isZh = ZeroTheme.isZh(context);
    final orders = _marketService.getMyOrders(_currentUserId);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: context.zBg,
          appBar: AppBar(
            backgroundColor: context.zBg,
            elevation: 0,
            title: Text(
              isZh ? '我的订单' : 'My Orders',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
          ),
          body: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: context.zTextDisabled,
                      ),
                      SizedBox(height: ZeroSpacing.md),
                      Text(
                        isZh ? '暂无订单' : 'No orders yet',
                        style: ZeroTypography.body(context),
                      ),
                      SizedBox(height: ZeroSpacing.xs),
                      Text(
                        isZh ? '开始在 ZeroMarket 购买' : 'Start buying on ZeroMarket',
                        style: ZeroTypography.caption(context),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: ZeroSpacing.screenHorizontal,
                    vertical: ZeroSpacing.md,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final order = orders[i];
                    final listing = _marketService.getListings().where(
                      (l) => l.id == order.listingId,
                    ).toList();

                    final listingTitle = listing.isNotEmpty
                        ? listing.first.title
                        : order.listingId;

                    final listingImage = listing.isNotEmpty && listing.first.images.isNotEmpty
                        ? listing.first.images.first
                        : '📦';

                    return GestureDetector(
                      onTap: () => _showOrderDetail(order, listingTitle, listingImage),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: ZeroSpacing.sm),
                        child: ZeroCard(
                          padding: EdgeInsets.all(ZeroSpacing.md),
                          borderRadius: ZeroSpacing.cardRadiusSm,
                          child: Row(
                            children: [
                              if (listingImage.startsWith('data:image'))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(listingImage.split(',')[1]),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Text(listingImage, style: TextStyle(fontSize: 32)),
                              SizedBox(width: ZeroSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listingTitle,
                                      style: ZeroTypography.bodyBold(context).copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: ZeroSpacing.xs),
                                    Row(
                                      children: [
                                        Text(
                                          '${order.price.toStringAsFixed(0)} ZERO',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.zAccent,
                                          ),
                                        ),
                                        SizedBox(width: ZeroSpacing.sm),
                                        _buildOrderStatusBadge(order.status, isZh),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (order.status == 'Locked')
                                GestureDetector(
                                  onTap: () {
                                    _marketService.updateOrderStatus(order.id, 'Shipped');
                                    Navigator.of(context).pop();
                                    _showMyOrders();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ZeroSpacing.md,
                                      vertical: ZeroSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.zAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                                      border: Border.all(
                                        color: context.zAccent.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      isZh ? '发货' : 'Ship',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.zAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              if (order.status == 'Shipped')
                                GestureDetector(
                                  onTap: () {
                                    _marketService.updateOrderStatus(order.id, 'Delivered');
                                    Navigator.of(context).pop();
                                    _showMyOrders();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ZeroSpacing.md,
                                      vertical: ZeroSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.zSuccess.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                                      border: Border.all(
                                        color: context.zSuccess.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      isZh ? '确认收货' : 'Confirm',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.zSuccess,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showOrderDetail(MarketOrder order, String listingTitle, String listingImage) {
    final isZh = ZeroTheme.isZh(context);
    final usdPrice = (order.price * _marketService.zeroUsdRate).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(ZeroSpacing.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.zSurfaceRaised,
          borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
          border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
        ),
        child: SingleChildScrollView(
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
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            context.zAccent.withOpacity(0.2),
                            context.zCeladon.withOpacity(0.08),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        listingImage.startsWith('data:image') ? '📦' : listingImage,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.md),
                    Text(
                      isZh ? '订单详情' : 'Order Detail',
                      style: ZeroTypography.title(context).copyWith(
                        color: context.zAccent,
                      ),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      listingTitle,
                      style: ZeroTypography.bodyBold(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      order.id,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: context.zTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${order.price.toStringAsFixed(0)} ZERO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: context.zAccent,
                    ),
                  ),
                  SizedBox(width: ZeroSpacing.sm),
                  Text(
                    '≈ \$$usdPrice',
                    style: ZeroTypography.body(context).copyWith(
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              SizedBox(height: ZeroSpacing.sm),
              Center(
                child: _buildOrderStatusBadge(order.status, isZh),
              ),
              SizedBox(height: ZeroSpacing.md),
              ZeroCard(
                padding: EdgeInsets.all(ZeroSpacing.md),
                borderRadius: ZeroSpacing.cardRadiusSm,
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: context.zAccent),
                    SizedBox(width: ZeroSpacing.sm),
                    Expanded(
                      child: Text(
                        isZh ? '${order.escrowedZero.toStringAsFixed(0)} ZERO 锁定在托管中' : '${order.escrowedZero.toStringAsFixed(0)} ZERO locked in escrow',
                        style: ZeroTypography.caption(context).copyWith(
                          color: context.zAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              if (order.deliveryMethod != 'digital')
                _buildOrderDetailSection(
                  Icons.local_shipping_outlined,
                  isZh ? '配送方式' : 'Delivery Method',
                  Row(
                    children: [
                      _buildDeliveryBadge(order.deliveryMethod, isZh),
                    ],
                  ),
                ),
              if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty)
                _buildOrderDetailSection(
                  Icons.location_on_outlined,
                  isZh ? '收货地址' : 'Shipping Address',
                  Text(
                    order.shippingAddress!,
                    style: ZeroTypography.body(context).copyWith(fontSize: 13),
                  ),
                ),
              if (order.contactPhone != null && order.contactPhone!.isNotEmpty)
                _buildOrderDetailSection(
                  Icons.phone_outlined,
                  isZh ? '联系电话' : 'Contact Phone',
                  Text(
                    order.contactPhone!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: context.zTextPrimary,
                    ),
                  ),
                ),
              if (order.contactEmail != null && order.contactEmail!.isNotEmpty)
                _buildOrderDetailSection(
                  Icons.email_outlined,
                  isZh ? '电子邮箱' : 'Email',
                  Text(
                    order.contactEmail!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: context.zTextPrimary,
                    ),
                  ),
                ),
              if (order.orderNote != null && order.orderNote!.isNotEmpty)
                _buildOrderDetailSection(
                  Icons.notes_outlined,
                  isZh ? '订单备注' : 'Order Note',
                  Text(
                    order.orderNote!,
                    style: ZeroTypography.body(context).copyWith(
                      fontSize: 13,
                      color: context.zTextSecondary,
                    ),
                  ),
                ),
              SizedBox(height: ZeroSpacing.lg),
              Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
              SizedBox(height: ZeroSpacing.lg),
              _buildOrderDetailSection(
                Icons.calendar_today,
                isZh ? '创建时间' : 'Created',
                Text(
                  '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: context.zTextSecondary,
                  ),
                ),
              ),
              SizedBox(height: ZeroSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailSection(IconData icon, String label, Widget content) {
    return Padding(
      padding: EdgeInsets.only(bottom: ZeroSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.zSurfaceOverlay.withOpacity(0.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: context.zAccent),
          ),
          SizedBox(width: ZeroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ZeroTypography.caption(context).copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ZeroSpacing.xs),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBadge(String method, bool isZh) {
    String label;
    IconData icon;
    Color color;
    switch (method) {
      case 'express':
        label = isZh ? '🚚 快递配送' : '🚚 Express';
        icon = Icons.local_shipping;
        color = context.zAccent;
        break;
      case 'digital':
        label = isZh ? '💾 数字交付' : '💾 Digital';
        icon = Icons.cloud_download_outlined;
        color = context.zCeladon;
        break;
      case 'pickup':
        label = isZh ? '🏪 到店自提' : '🏪 Pickup';
        icon = Icons.store_outlined;
        color = context.zWarning;
        break;
      default:
        label = method;
        icon = Icons.help_outline;
        color = context.zTextTertiary;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ZeroSpacing.md,
        vertical: ZeroSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: ZeroSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddressManager() async {
    final isZh = ZeroTheme.isZh(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final addresses = _marketService.getSavedAddresses();

            return Container(
              margin: EdgeInsets.all(ZeroSpacing.md),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: context.zSurfaceRaised,
                borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(ZeroSpacing.lg),
                    child: Row(
                      children: [
                        Text(
                          isZh ? '管理地址' : 'Manage Addresses',
                          style: ZeroTypography.title(context).copyWith(
                            color: context.zAccent,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            final nameController = TextEditingController();
                            final phoneController = TextEditingController();
                            final provinceCityController = TextEditingController();
                            final streetController = TextEditingController();
                            final postalCodeController = TextEditingController();

                            showDialog(
                              context: ctx,
                              builder: (dialogCtx) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.all(ZeroSpacing.md),
                                child: Container(
                                  padding: EdgeInsets.all(ZeroSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: context.zSurfaceRaised,
                                    borderRadius: BorderRadius.circular(ZeroSpacing.cardRadius),
                                    border: Border.all(color: context.zFrostWhiteStrong, width: 0.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isZh ? '新增地址' : 'Add New Address',
                                          style: ZeroTypography.title(context).copyWith(
                                            color: context.zAccent,
                                          ),
                                        ),
                                        SizedBox(height: ZeroSpacing.lg),
                                        _buildAddressField(
                                          isZh ? '姓名' : 'Name',
                                          nameController,
                                          isZh ? '收件人姓名' : 'Recipient name',
                                          ctx,
                                        ),
                                        SizedBox(height: ZeroSpacing.sm),
                                        _buildAddressField(
                                          isZh ? '电话' : 'Phone',
                                          phoneController,
                                          isZh ? '联系电话' : 'Contact phone',
                                          ctx,
                                          TextInputType.phone,
                                        ),
                                        SizedBox(height: ZeroSpacing.sm),
                                        _buildAddressField(
                                          isZh ? '省市' : 'Province / City',
                                          provinceCityController,
                                          isZh ? '例如：浙江省 杭州市' : 'e.g. California, SF',
                                          ctx,
                                        ),
                                        SizedBox(height: ZeroSpacing.sm),
                                        _buildAddressField(
                                          isZh ? '详细地址' : 'Street Address',
                                          streetController,
                                          isZh ? '街道、门牌号' : 'Street, building number',
                                          ctx,
                                        ),
                                        SizedBox(height: ZeroSpacing.sm),
                                        _buildAddressField(
                                          isZh ? '邮政编码' : 'Postal Code',
                                          postalCodeController,
                                          isZh ? '邮编' : 'ZIP code',
                                          ctx,
                                          TextInputType.number,
                                        ),
                                        SizedBox(height: ZeroSpacing.lg),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              final name = nameController.text.trim();
                                              final phone = phoneController.text.trim();
                                              final provinceCity = provinceCityController.text.trim();
                                              final street = streetController.text.trim();
                                              final postalCode = postalCodeController.text.trim();

                                              if (name.isEmpty || phone.isEmpty || provinceCity.isEmpty || street.isEmpty) {
                                                return;
                                              }

                                              _marketService.saveAddress({
                                                'id': 'addr_${DateTime.now().millisecondsSinceEpoch}',
                                                'name': name,
                                                'phone': phone,
                                                'provinceCity': provinceCity,
                                                'street': street,
                                                'postalCode': postalCode,
                                                'isDefault': addresses.isEmpty ? 'true' : 'false',
                                              });

                                              Navigator.of(dialogCtx).pop();
                                              setSheetState(() {});
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
                                              isZh ? '保存地址' : 'Save Address',
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
                                            onPressed: () => Navigator.of(dialogCtx).pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: context.zSurfaceOverlay,
                                              foregroundColor: context.zTextSecondary,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(vertical: ZeroSpacing.md),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                                                side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              isZh ? '取消' : 'Cancel',
                                              style: ZeroTypography.bodyBold(context).copyWith(
                                                color: context.zTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: context.zAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
                              border: Border.all(
                                color: context.zAccent.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              isZh ? '+ 新增' : '+ Add',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.zAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.5, color: context.zDivider.withOpacity(0.3)),
                  if (addresses.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, size: 48, color: context.zTextDisabled),
                            SizedBox(height: ZeroSpacing.md),
                            Text(
                              isZh ? '还没有保存的地址' : 'No saved addresses',
                              style: ZeroTypography.body(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: ZeroSpacing.sm),
                        itemCount: addresses.length,
                        itemBuilder: (_, i) {
                          final addr = addresses[i];
                          final name = addr['name'] ?? '';
                          final phone = addr['phone'] ?? '';
                          final provinceCity = addr['provinceCity'] ?? '';
                          final street = addr['street'] ?? '';
                          final postalCode = addr['postalCode'] ?? '';
                          final isDefault = addr['isDefault'] == 'true';

                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: ZeroSpacing.md,
                              vertical: ZeroSpacing.xs,
                            ),
                            padding: EdgeInsets.all(ZeroSpacing.md),
                            decoration: BoxDecoration(
                              color: context.zSurfaceOverlay.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(ZeroSpacing.cardRadiusSm),
                              border: Border.all(
                                color: isDefault
                                    ? context.zAccent.withOpacity(0.3)
                                    : context.zFrostWhiteStrong,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      colors: [
                                        context.zAccent.withOpacity(0.15),
                                        context.zCeladon.withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: context.zAccent,
                                  ),
                                ),
                                SizedBox(width: ZeroSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                                          ),
                                          SizedBox(width: ZeroSpacing.xs),
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: context.zTextTertiary,
                                            ),
                                          ),
                                          if (isDefault) ...[
                                            SizedBox(width: ZeroSpacing.xs),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: ZeroSpacing.xs,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: context.zAccent.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isZh ? '默认' : 'Default',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.zAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '$provinceCity $street',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.zTextSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (postalCode.isNotEmpty)
                                        Text(
                                          isZh ? '邮编: $postalCode' : 'ZIP: $postalCode',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: context.zTextTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _marketService.deleteAddress(i);
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: context.zError.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: context.zError,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + ZeroSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddressField(String label, TextEditingController controller, String hint, BuildContext ctx, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(ctx).copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ZeroSpacing.xs),
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
            keyboardType: keyboardType,
            style: ZeroTypography.body(ctx).copyWith(
              color: context.zTextPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: ZeroTypography.body(ctx).copyWith(
                color: context.zTextTertiary,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.md,
                vertical: ZeroSpacing.md,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStarRating(double rating) {
    final stars = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(Icon(Icons.star, size: 14, color: context.zWarning));
      } else if (rating >= i - 0.5) {
        stars.add(Icon(Icons.star_half, size: 14, color: context.zWarning));
      } else {
        stars.add(Icon(Icons.star_border, size: 14, color: context.zTextDisabled));
      }
    }
    return stars;
  }

  Widget _buildStatusBadge(String status, bool isZh) {
    final isActive = status == 'Active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: ZeroSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? context.zSuccess.withOpacity(0.1) : context.zError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? context.zSuccess.withOpacity(0.3) : context.zError.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        _trStatus(status, isZh),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? context.zSuccess : context.zError,
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status, bool isZh) {
    Color badgeColor;
    switch (status) {
      case 'Locked':
        badgeColor = context.zWarning;
        break;
      case 'Shipped':
        badgeColor = context.zCeladon;
        break;
      case 'Delivered':
        badgeColor = context.zSuccess;
        break;
      case 'Disputed':
        badgeColor = context.zError;
        break;
      default:
        badgeColor = context.zTextTertiary;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        _trStatus(status, isZh),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildDeliveryChip(IconData icon, String label, String value, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : context.zSurfaceOverlay.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.4)
                : context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : context.zTextTertiary),
            SizedBox(width: ZeroSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : context.zTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md, vertical: ZeroSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: ZeroSpacing.xs),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isZh = ZeroTheme.isZh(context);
    final isSelected = category == _selectedCategory;
    final emoji = category == 'All'
        ? '🌐'
        : ZeroMarketService.getCategoryEmoji(category);

    return GestureDetector(
      onTap: () => _onCategoryChanged(category),
      child: Container(
        margin: EdgeInsets.only(right: ZeroSpacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.md,
          vertical: ZeroSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.zAccent.withOpacity(0.15)
              : context.zSurfaceOverlay.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
          border: Border.all(
            color: isSelected
                ? context.zAccent.withOpacity(0.4)
                : context.zFrostWhiteStrong,
            width: 0.5,
          ),
        ),
        child: Text(
          '$emoji ${_trCategory(category, isZh)}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? context.zAccent : context.zTextTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildListingImage(String imageStr) {
    if (imageStr.startsWith('data:image')) {
      final base64Str = imageStr.split(',')[1];
      return ClipRRect(
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
        child: Image.memory(
          base64Decode(base64Str),
          width: double.infinity,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: context.zSurfaceOverlay.withOpacity(0.4),
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
            ),
            alignment: Alignment.center,
            child: Text('🖼️', style: TextStyle(fontSize: 40)),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: context.zSurfaceOverlay.withOpacity(0.4),
        borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
      ),
      alignment: Alignment.center,
      child: Text(imageStr, style: TextStyle(fontSize: 60)),
    );
  }

  Widget _buildListingCard(MarketListing listing) {
    final isZh = ZeroTheme.isZh(context);
    final usdPrice = (listing.price * _marketService.zeroUsdRate).toStringAsFixed(2);
    final stars = _buildStarRating(listing.averageRating);
    final categoryColor = _getCategoryColor(listing.category);

    return GestureDetector(
      onTap: () => _showListingDetail(listing),
      child: ZeroCard(
        padding: EdgeInsets.all(ZeroSpacing.md),
        borderRadius: ZeroSpacing.cardRadiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildListingImage(listing.images.isNotEmpty ? listing.images.first : '📦'),
                Positioned(
                  top: ZeroSpacing.xs,
                  left: ZeroSpacing.xs,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ZeroSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      listing.category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: ZeroSpacing.xs,
                  right: ZeroSpacing.xs,
                  child: _buildStatusBadge(listing.status, isZh),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.sm),
            Text(
              listing.title,
              style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ZeroSpacing.xs),
            Row(
              children: [
                Text(
                  '${listing.price.toStringAsFixed(0)} ZERO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.zAccent,
                  ),
                ),
                SizedBox(width: ZeroSpacing.xs),
                Text(
                  '\$$usdPrice',
                  style: ZeroTypography.caption(context).copyWith(
                    fontFamily: 'Inter',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.xs),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: context.zTextTertiary),
                SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${listing.sellerName} · ${listing.location}',
                    style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ZeroSpacing.xs),
            Row(
              children: [
                ...stars,
                SizedBox(width: ZeroSpacing.xs),
                Text(
                  '(${listing.totalRatings})',
                  style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Electronics':
        return const Color(0xFF6B9FFF);
      case 'Fashion':
        return const Color(0xFFC77DFF);
      case 'Collectibles':
        return const Color(0xFFC2A050);
      case 'Digital Goods':
        return context.zCeladon;
      case 'Services':
        return const Color(0xFFE07B5A);
      default:
        return context.zTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.zBg,
        appBar: AppBar(
          backgroundColor: context.zBg,
          elevation: 0,
          title: Text(
            'ZeroMarket',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: context.zTextPrimary,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.zTextSecondary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final categories = ['All', ...ZeroMarketService.categories];

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'ZeroMarket',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.zTextPrimary,
              ),
            ),
            SizedBox(width: ZeroSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ZeroSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.zSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.zSuccess.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🟢', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Text(
                    '1 ZERO ≈ \$0.50',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.zSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: context.zTextSecondary, size: 20),
            color: context.zSurfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ZeroSpacing.chipRadius),
              side: BorderSide(color: context.zFrostWhiteStrong, width: 0.5),
            ),
            onSelected: _onSortChanged,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'newest',
                child: Text(
                  isZh ? '最新' : 'Newest',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: _sortBy == 'newest' ? FontWeight.w600 : FontWeight.w400,
                    color: _sortBy == 'newest' ? context.zAccent : context.zTextPrimary,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'priceLow',
                child: Text(
                  isZh ? '价格低→高' : 'Price Low → High',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: _sortBy == 'priceLow' ? FontWeight.w600 : FontWeight.w400,
                    color: _sortBy == 'priceLow' ? context.zAccent : context.zTextPrimary,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'priceHigh',
                child: Text(
                  isZh ? '价格高→低' : 'Price High → Low',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: _sortBy == 'priceHigh' ? FontWeight.w600 : FontWeight.w400,
                    color: _sortBy == 'priceHigh' ? context.zAccent : context.zTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: ZeroSpacing.xs),
            child: IconButton(
              icon: Icon(Icons.receipt_long_outlined, color: context.zTextSecondary, size: 22),
              onPressed: _showMyOrders,
              tooltip: isZh ? '我的订单' : 'My Orders',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.zAccent,
        backgroundColor: context.zSurfaceRaised,
        displacement: 20,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                margin: EdgeInsets.only(top: ZeroSpacing.sm),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
                  itemCount: categories.length,
                  itemBuilder: (_, i) => _buildCategoryChip(categories[i]),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: ZeroSpacing.sm)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildListingCard(_listings[i]),
                  childCount: _listings.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: ZeroSpacing.xxl)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSellItemModal,
        backgroundColor: context.zAccent,
        elevation: 0,
        child: Icon(
          Icons.add_rounded,
          color: context.zBg,
          size: 28,
        ),
      ),
    );
  }
}