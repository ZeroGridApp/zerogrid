class ZeroConstants {
  ZeroConstants._();

  static const String appName = 'Zero';
  static const String appNameZh = '零界';
  static const String tagline = 'Zero trace. Zero limit. Zero compromise.';
  static const String taglineZh = '零界 · 无界';

  static const String website = 'https://zero.im';

  static const int minPasswordLength = 8;
  static const int mnemonicWordCount = 12;
  static const int zeroIdLength = 10;

  static const bootstrapNodes = [
    '/dns4/bootstrap.zero.im/tcp/4001',
    '/dns4/bootstrap2.zero.im/tcp/4001',
  ];

  static const feePolicy = 'Zero-fee P2P transfers between Zero IDs';
}