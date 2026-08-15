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
        return Icons.desktop_windows_rounded;
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
        title: Text('Connected Computers', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Pair New Computer',
            onPressed: () {
              HapticUtil.selection();
              context.push('/pairing');
            },
          ),
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
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: device.isCurrent ? AppColors.primary : AppColors.surfaceBorder,
                width: device.isCurrent ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getDeviceIcon(device.type),
                      size: 24,
                      color: isOnline ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              device.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (device.isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CURRENT',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
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
                                color: isOnline ? AppColors.statusSuccess : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Online • ${device.ip}' : 'Offline',
                              style: AppTypography.labelSmall.copyWith(
                                color: isOnline ? AppColors.statusSuccess : AppColors.textMuted,
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
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Pair New Desktop Computer'),
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
