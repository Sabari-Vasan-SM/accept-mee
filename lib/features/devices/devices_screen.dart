import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/devices_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'desktop':
        return Icons.desktop_mac_rounded;
      case 'server':
        return Icons.dns_rounded;
      case 'laptop':
      default:
        return Icons.laptop_mac_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final devices = devicesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Computers', style: AppTypography.headlineMedium),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Pair New Computer',
            onPressed: () {
              HapticUtil.selection();
              context.push('/pairing');
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: devices.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final device = devices[index];
          final isOnline = device.status == 'online';

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: device.isCurrent ? AppColors.primary : AppColors.outlineVariant,
                width: device.isCurrent ? 2 : 1,
              ),
              boxShadow: device.isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getDeviceIcon(device.type),
                      size: 24,
                      color: isOnline ? AppColors.onPrimaryContainer : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              device.name,
                              style: AppTypography.headlineMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (device.isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'CURRENT',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline ? AppColors.tertiary : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Online • ${device.ip}' : 'Offline',
                              style: AppTypography.labelSmall.copyWith(
                                color: isOnline ? AppColors.tertiary : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateUtil.formatTimeAgo(device.lastSeen),
                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                'Pair New Desktop Computer',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                HapticUtil.selection();
                context.push('/pairing');
              },
            ),
          ),
        ),
      ),
    );
  }
}
