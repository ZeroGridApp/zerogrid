import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class IpfsDeployScreen extends StatefulWidget {
  const IpfsDeployScreen({super.key});

  @override
  State<IpfsDeployScreen> createState() => _IpfsDeployScreenState();
}

class _IpfsDeployScreenState extends State<IpfsDeployScreen> {

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Text(
          isZh ? 'IPFS 部署' : 'IPFS Deploy',
          style: TextStyle(
            fontFamily: isZh ? 'NotoSansSC' : 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.zTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: ZeroSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ZeroSpacing.md),
            _buildDeploymentMethodIpfs(isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildDeploymentMethodArweave(isZh),
            SizedBox(height: ZeroSpacing.md),
            _buildDeploymentMethodSelfHosted(isZh),
            SizedBox(height: ZeroSpacing.lg),
            _buildBuildStats(isZh),
            SizedBox(height: ZeroSpacing.lg),
            _buildProductionChecklist(isZh),
            SizedBox(height: ZeroSpacing.lg),
            _buildDeploymentHistory(isZh),
            SizedBox(height: ZeroSpacing.xxl + ZeroSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentMethodIpfs(bool isZh) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.zAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_rounded,
                  color: context.zAccent,
                  size: 28,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? 'IPFS (推荐)' : 'IPFS (Recommended)',
                      style: ZeroTypography.title(context),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh
                          ? '通过 Pinata/Web3.Storage 固定到 IPFS 网络。可通过任何 IPFS 网关或 .zero 域名访问。'
                          : 'Pin to IPFS network via Pinata/Web3.Storage. Accessible via any IPFS gateway or .zero domain.',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          _buildSteps(
            [
              isZh ? '构建: flutter build web --release' : 'Build: flutter build web --release',
              isZh ? '上传: 上传 build/web 到 Pinata/Web3.Storage' : 'Upload: Upload build/web to Pinata/Web3.Storage',
              isZh ? '固定: 获取 CID (例如 QmXxx...)' : 'Pin: Get CID (e.g. QmXxx...)',
              isZh ? '网关: 通过 https://ipfs.io/ipfs/QmXxx... 或 https://app.zero.eth 访问' : 'Gateway: Access at https://ipfs.io/ipfs/QmXxx... or https://app.zero.eth',
            ],
            isZh,
          ),
          SizedBox(height: ZeroSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onDeployTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.zAccent,
                foregroundColor: context.zBg,
                padding: EdgeInsets.symmetric(vertical: ZeroSpacing.sm + 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ZeroSpacing.buttonRadius),
                ),
              ),
              child: Text(
                isZh ? '部署' : 'Deploy',
                style: TextStyle(
                  fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentMethodArweave(bool isZh) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.zCeladon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.archive_rounded,
                  color: context.zCeladon,
                  size: 28,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? 'Arweave (永久存储)' : 'Arweave (Permanent)',
                      style: ZeroTypography.title(context),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh
                          ? '永久存储在 Arweave 上。一次性付费，永久存储。典型 SPA 大约 \$5-20。'
                          : 'Permanently store on Arweave. Pay once, store forever. ~\$5-20 for a typical SPA.',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          _buildSteps(
            [
              isZh ? '安装: npm i -g arkb' : 'Install: npm i -g arkb',
              isZh ? '部署: arkb deploy build/web --wallet arweave-key.json' : 'Deploy: arkb deploy build/web --wallet arweave-key.json',
              isZh ? '访问: https://arweave.net/TX_ID' : 'Access: https://arweave.net/TX_ID',
            ],
            isZh,
          ),
          SizedBox(height: ZeroSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ZeroSpacing.sm + 4),
            decoration: BoxDecoration(
              color: context.zCeladon.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.zCeladon.withOpacity(0.2),
              ),
            ),
            child: Text(
              isZh
                  ? '价格估算: ~0.05 AR 对应 15MB 构建 / ~¥35'
                  : 'Price estimate: ~0.05 AR for 15MB build / ~¥35',
              style: ZeroTypography.bodyBold(context).copyWith(
                color: context.zCeladon,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentMethodSelfHosted(bool isZh) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.zWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dns_rounded,
                  color: context.zWarning,
                  size: 28,
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? '自托管 / 社区镜像' : 'Self-Hosted / Community Mirror',
                      style: ZeroTypography.title(context),
                    ),
                    SizedBox(height: ZeroSpacing.xs),
                    Text(
                      isZh
                          ? '运行自己的网关。完全控制。最适合社区和 DAO。'
                          : 'Run your own gateway. Full control. Best for communities and DAOs.',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          _buildSteps(
            [
              isZh ? 'Nginx 配置提供静态文件' : 'Nginx config to serve static files',
              isZh ? "通过 Let's Encrypt 获取 SSL" : "SSL via Let's Encrypt",
              isZh ? 'DNS: 将您的 .zero 域名指向网关 IP' : 'DNS: point your .zero domain to gateway IP',
              isZh ? '社区可以运行镜像以实现冗余' : 'Community can run mirrors for redundancy',
            ],
            isZh,
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(List<String> steps, bool isZh) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.zAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: isZh ? 'NotoSansSC' : 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.zBg,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ZeroSpacing.sm),
              Expanded(
                child: _buildStepCode(step, isZh),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepCode(String step, bool isZh) {
    final isCommand = step.contains('flutter build') ||
        step.contains('npm i') ||
        step.contains('arkb deploy');

    if (!isCommand) {
      return Text(
        step,
        style: ZeroTypography.body(context),
      );
    }

    final parts = step.split(':');
    final label = parts.first.trim();
    final cmd = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: ZeroTypography.body(context),
        ),
        SizedBox(height: ZeroSpacing.xs),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: cmd));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isZh ? '命令已复制到剪贴板' : 'Command copied to clipboard',
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: ZeroSpacing.sm + 4,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: context.zSurfaceOverlay.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.zFrostWhiteStrong),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cmd,
                    style: ZeroTypography.mono(context).copyWith(
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: context.zTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuildStats(bool isZh) {
    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '当前构建统计' : 'Current Build Stats',
            style: ZeroTypography.title(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isZh ? '构建大小' : 'Build size',
                  '15.2 MB',
                  isZh,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Gzip',
                  '4.8 MB',
                  isZh,
                ),
              ),
            ],
          ),
          SizedBox(height: ZeroSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  isZh ? '文件数' : 'Files',
                  '87',
                  isZh,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  isZh ? 'Service Worker' : 'Service worker',
                  isZh ? '已禁用 (无缓存)' : 'Disabled (no-cache)',
                  isZh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isZh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ZeroTypography.caption(context),
        ),
        SizedBox(height: ZeroSpacing.xs),
        Text(
          value,
          style: ZeroTypography.bodyBold(context),
        ),
      ],
    );
  }

  Widget _buildProductionChecklist(bool isZh) {
    final items = [
      (isZh ? 'Service worker 已禁用 (适用于 IPFS)' : 'Service worker disabled (for IPFS)', true),
      (isZh ? 'Cache-Control 头已设置' : 'Cache-Control headers set', true),
      (isZh ? 'Content-Security-Policy 已配置' : 'Content-Security-Policy configured', false),
      (isZh ? 'CORS 头用于 API 访问' : 'CORS headers for API access', false),
      (isZh ? 'DNS TXT 验证 .zero 域名' : 'DNS TXT verification for .zero domain', false),
      (isZh ? 'IPFS 固定服务付费计划' : 'IPFS pinning service paid plan', false),
      (isZh ? '多区域固定 (至少 3 个区域)' : 'Multi-region pin (at least 3 regions)', false),
    ];

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '生产环境检查清单' : 'Production Checklist',
            style: ZeroTypography.title(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          ...items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: ZeroSpacing.sm + 4),
              child: Row(
                children: [
                  Icon(
                    item.$2
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.$2 ? context.zSuccess : context.zTextTertiary,
                    size: 22,
                  ),
                  SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: ZeroTypography.body(context).copyWith(
                        color: item.$2 ? context.zTextPrimary : context.zTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDeploymentHistory(bool isZh) {
    final history = [
      (version: 'v0.6.0', cid: 'QmAbc123...', method: 'IPFS + Arweave', time: isZh ? '3 天前' : '3 days ago'),
      (version: 'v0.5.0', cid: 'QmDef456...', method: 'IPFS', time: isZh ? '7 天前' : '7 days ago'),
      (version: 'v0.4.0', cid: 'QmGhi789...', method: 'IPFS', time: isZh ? '14 天前' : '14 days ago'),
      (version: 'v0.3.0', cid: 'QmJkl012...', method: 'IPFS', time: isZh ? '21 天前' : '21 days ago'),
    ];

    return ZeroCard(
      padding: EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '部署历史' : 'Deployment History',
            style: ZeroTypography.title(context),
          ),
          SizedBox(height: ZeroSpacing.md),
          ...history.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: ZeroSpacing.sm + 4),
              child: Container(
                padding: EdgeInsets.all(ZeroSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: context.zFrostWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.version,
                                style: ZeroTypography.bodyBold(context),
                              ),
                              SizedBox(width: ZeroSpacing.xs),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ZeroSpacing.xs + 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.zAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.method,
                                  style: ZeroTypography.caption(context).copyWith(
                                    color: context.zAccent,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ZeroSpacing.xs),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: entry.cid),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isZh ? 'CID 已复制' : 'CID copied',
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'CID: ${entry.cid}',
                                  style: ZeroTypography.monoSmall(context).copyWith(
                                    color: context.zTextSecondary,
                                  ),
                                ),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: context.zTextSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      entry.time,
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _onDeployTap() async {
    final isZh = ZeroTheme.isZh(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? 'IPFS 部署即将推出' : 'IPFS deployment coming soon'),
        backgroundColor: context.zAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}