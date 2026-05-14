import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/zero_theme.dart';
import '../../widgets/zero_card.dart';

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ZeroTheme.isZh(context);

    return Scaffold(
      backgroundColor: context.zBg,
      appBar: AppBar(
        backgroundColor: context.zBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              isZh ? '系统状态' : 'System Status',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: ZeroSpacing.sm),
            _buildPulseDot(context.zSuccess),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ZeroSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallBanner(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildServiceGrid(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildNetworkStatsRow(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildRegionHealthMap(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildUptimeChart(isZh),
            const SizedBox(height: ZeroSpacing.lg),
            _buildRecentIncidents(isZh),
            const SizedBox(height: ZeroSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseDot(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 10 + _pulseController.value * 4,
          height: 10 + _pulseController.value * 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.6 - _pulseController.value * 0.3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 - _pulseController.value * 0.2),
                blurRadius: 6 + _pulseController.value * 4,
                spreadRadius: 1 + _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBanner(bool isZh) {
    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPulseDot(context.zSuccess),
              const SizedBox(width: ZeroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? '所有系统正常运行' : 'All Systems Operational',
                      style: ZeroTypography.headline(context).copyWith(
                        color: context.zSuccess,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isZh ? 'Zero Protocol 网络运行状况良好' : 'Zero Protocol network is healthy',
                      style: ZeroTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.md),
          Container(
            padding: const EdgeInsets.all(ZeroSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.zSuccess.withOpacity(0.1),
                  context.zSuccess.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isZh ? '90 天正常运行率' : '90-Day Uptime',
                  style: ZeroTypography.body(context),
                ),
                Text(
                  '99.97%',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: context.zSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(bool isZh) {
    final services = [
      _ServiceInfo(
        icon: Icons.chat_rounded,
        name: 'ZeroChat',
        subtitle: isZh ? '端到端加密消息' : 'E2EE Messaging',
        uptime: '99.99%',
        latency: '12ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.payments_rounded,
        name: 'ZeroPay',
        subtitle: isZh ? '支付' : 'Payments',
        uptime: '99.98%',
        latency: '8ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.cloud_rounded,
        name: 'ZeroStore',
        subtitle: 'DASN',
        uptime: '99.95%',
        latency: '18ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.language_rounded,
        name: 'ZeroDNS',
        subtitle: isZh ? '域名服务' : 'Name Service',
        uptime: '100%',
        latency: '5ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.account_tree_rounded,
        name: 'ZeroChain',
        subtitle: isZh ? '共识' : 'Consensus',
        uptime: '99.92%',
        latency: '22ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.swap_horiz_rounded,
        name: 'ZeroBridge',
        subtitle: isZh ? '跨链桥' : 'Bridge',
        uptime: '98.5%',
        latency: '145ms',
        statusColor: context.zWarning,
        note: isZh ? 'SOL→ETH 方向延迟' : 'Experiencing delays on SOL→ETH',
      ),
      _ServiceInfo(
        icon: Icons.how_to_vote_rounded,
        name: 'ZeroDAO',
        subtitle: isZh ? '治理' : 'Governance',
        uptime: '99.99%',
        latency: '10ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.hub_rounded,
        name: 'ZeroNode',
        subtitle: 'P2P',
        uptime: '99.96%',
        latency: '15ms',
        statusColor: context.zSuccess,
        note: null,
      ),
      _ServiceInfo(
        icon: Icons.fingerprint_rounded,
        name: 'ZeroID',
        subtitle: isZh ? '认证' : 'Auth',
        uptime: '100%',
        latency: '6ms',
        statusColor: context.zSuccess,
        note: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '服务状态' : 'Service Status',
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ZeroSpacing.sm,
            crossAxisSpacing: ZeroSpacing.sm,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index], isZh);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(_ServiceInfo service, bool isZh) {
    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadiusSm,
      padding: const EdgeInsets.all(ZeroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          service.statusColor.withOpacity(0.2),
                          service.statusColor.withOpacity(0.06),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      service.icon,
                      size: 18,
                      color: service.statusColor,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          service.subtitle,
                          style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ZeroSpacing.sm),
          Row(
            children: [
              _buildStatusDot(service.statusColor),
              const SizedBox(width: ZeroSpacing.xs),
              Text(
                service.uptime,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: service.statusColor,
                ),
              ),
              const Spacer(),
              Text(
                '${service.latency}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.zTextTertiary,
                ),
              ),
            ],
          ),
          if (service.note != null) ...[
            const SizedBox(height: ZeroSpacing.xs),
            Text(
              service.note!,
              style: ZeroTypography.caption(context).copyWith(
                fontSize: 9,
                color: context.zWarning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkStatsRow(bool isZh) {
    final stats = [
      _StatInfo(
        label: isZh ? '活跃节点' : 'Active Nodes',
        value: '1,247',
        icon: Icons.hub_rounded,
        color: context.zAccent,
      ),
      _StatInfo(
        label: isZh ? '平均延迟' : 'Avg Latency',
        value: '18ms',
        icon: Icons.speed_rounded,
        color: context.zSuccess,
      ),
      _StatInfo(
        label: isZh ? 'ZERO 质押' : 'ZERO Staked',
        value: '150M',
        icon: Icons.shield_rounded,
        color: context.zCeladon,
      ),
      _StatInfo(
        label: isZh ? '24h 交易' : '24h Txs',
        value: '847,293',
        icon: Icons.swap_vert_rounded,
        color: const Color(0xFFC77DFF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '网络统计' : 'Network Stats',
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        Row(
          children: stats.map((stat) {
            return Expanded(
              child: ZeroCard(
                borderRadius: ZeroSpacing.cardRadiusSm,
                padding: const EdgeInsets.all(ZeroSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stat.icon, size: 20, color: stat.color.withOpacity(0.7)),
                    const SizedBox(height: ZeroSpacing.sm),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: stat.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.label,
                      style: ZeroTypography.caption(context).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRegionHealthMap(bool isZh) {
    final regions = [
      _RegionInfo('US East', '12ms', context.zSuccess),
      _RegionInfo('US West', '15ms', context.zSuccess),
      _RegionInfo('EU West', '22ms', context.zSuccess),
      _RegionInfo(isZh ? '亚洲东部' : 'Asia East', '28ms', context.zSuccess),
      _RegionInfo(isZh ? '亚洲东南' : 'Asia SE', '35ms', context.zWarning),
      _RegionInfo(isZh ? '南美' : 'South America', '45ms', context.zWarning),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '区域健康' : 'Region Health',
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: regions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: ZeroSpacing.sm,
            crossAxisSpacing: ZeroSpacing.sm,
            childAspectRatio: 2.0,
          ),
          itemBuilder: (context, index) {
            final region = regions[index];
            return ZeroCard(
              borderRadius: ZeroSpacing.cardRadiusSm,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              child: Row(
                children: [
                  _buildStatusDot(region.statusColor),
                  const SizedBox(width: ZeroSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          region.name,
                          style: ZeroTypography.bodyBold(context).copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          region.latency,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: region.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUptimeChart(bool isZh) {
    final days = [
      _DayUptime('Mon', 99.98, isZh ? '周一' : 'Mon'),
      _DayUptime('Tue', 100.0, isZh ? '周二' : 'Tue'),
      _DayUptime('Wed', 99.95, isZh ? '周三' : 'Wed'),
      _DayUptime('Thu', 99.97, isZh ? '周四' : 'Thu'),
      _DayUptime('Fri', 97.50, isZh ? '周五' : 'Fri'),
      _DayUptime('Sat', 99.99, isZh ? '周六' : 'Sat'),
      _DayUptime('Sun', 100.0, isZh ? '周日' : 'Sun'),
    ];

    return ZeroCard(
      borderRadius: ZeroSpacing.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '7 天运行时间' : '7-Day Uptime',
            style: ZeroTypography.title(context),
          ),
          const SizedBox(height: ZeroSpacing.lg),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final barColor = day.uptime >= 99.0
                    ? context.zSuccess
                    : day.uptime >= 97.0
                        ? context.zWarning
                        : context.zError;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${day.uptime.toStringAsFixed(day.uptime == 100.0 ? 0 : 2)}%',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: barColor,
                                ),
                              ),
                              const SizedBox(height: ZeroSpacing.xs),
                              Flexible(
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxWidth: 36),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        barColor,
                                        barColor.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                  height: double.infinity,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ZeroSpacing.sm),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: barColor.withOpacity(0.3 + _pulseController.value * 0.4),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: ZeroSpacing.xs),
                        Text(
                          day.shortLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.zTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIncidents(bool isZh) {
    final incidents = [
      _IncidentInfo(
        date: '2026-05-14',
        title: isZh ? 'SOL→ETH 跨链桥延迟' : 'SOL→ETH Bridge Latency',
        status: isZh ? '已解决' : 'Resolved',
        statusColor: context.zSuccess,
        duration: '2h 15m',
      ),
      _IncidentInfo(
        date: '2026-05-12',
        title: isZh ? 'DASN 存储节点同步延迟' : 'DASN Storage Node Sync Delay',
        status: isZh ? '已解决' : 'Resolved',
        statusColor: context.zSuccess,
        duration: '45m',
      ),
      _IncidentInfo(
        date: '2026-05-10',
        title: isZh ? 'API 速率限制触发' : 'API Rate Limiting Triggered',
        status: isZh ? '已解决' : 'Resolved',
        statusColor: context.zSuccess,
        duration: '30m',
      ),
      _IncidentInfo(
        date: '2026-05-09',
        title: isZh ? '欧洲区域连接问题' : 'EU Region Connectivity Issue',
        status: isZh ? '监控中' : 'Monitoring',
        statusColor: context.zWarning,
        duration: isZh ? '进行中' : 'Ongoing',
      ),
      _IncidentInfo(
        date: '2026-05-07',
        title: isZh ? '计划维护：ZeroDNS 升级' : 'Scheduled Maintenance: ZeroDNS upgrade',
        status: isZh ? '已完成' : 'Completed',
        statusColor: context.zSuccess,
        duration: '1h 30m',
      ),
      _IncidentInfo(
        date: '2026-05-03',
        title: isZh ? 'ZeroChain 共识节点重启' : 'ZeroChain Consensus Node Restart',
        status: isZh ? '已解决' : 'Resolved',
        statusColor: context.zSuccess,
        duration: '15m',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '近期事件' : 'Recent Incidents',
          style: ZeroTypography.title(context),
        ),
        const SizedBox(height: ZeroSpacing.md),
        ...incidents.map((incident) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ZeroSpacing.sm),
            child: ZeroCard(
              borderRadius: ZeroSpacing.cardRadiusSm,
              padding: const EdgeInsets.all(ZeroSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          incident.statusColor.withOpacity(0.2),
                          incident.statusColor.withOpacity(0.06),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      incident.statusColor == context.zSuccess
                          ? Icons.check_circle_outline
                          : Icons.monitor_heart_outlined,
                      size: 20,
                      color: incident.statusColor,
                    ),
                  ),
                  const SizedBox(width: ZeroSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.title,
                          style: ZeroTypography.bodyBold(context).copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              incident.date,
                              style: ZeroTypography.monoSmall(context),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: ZeroSpacing.sm),
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white24,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ZeroSpacing.xs,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: incident.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: incident.statusColor.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                incident.status,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: incident.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    incident.duration,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.zTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ServiceInfo {
  final IconData icon;
  final String name;
  final String subtitle;
  final String uptime;
  final String latency;
  final Color statusColor;
  final String? note;

  const _ServiceInfo({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.uptime,
    required this.latency,
    required this.statusColor,
    this.note,
  });
}

class _StatInfo {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _RegionInfo {
  final String name;
  final String latency;
  final Color statusColor;

  const _RegionInfo(this.name, this.latency, this.statusColor);
}

class _DayUptime {
  final String shortLabel;
  final double uptime;
  final String zhLabel;

  const _DayUptime(this.shortLabel, this.uptime, this.zhLabel);
}

class _IncidentInfo {
  final String date;
  final String title;
  final String status;
  final Color statusColor;
  final String duration;

  const _IncidentInfo({
    required this.date,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.duration,
  });
}