import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import 'antigravity_provider.dart';

final devicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final client = ref.watch(antigravityClientProvider);
  return client.devicesStream;
});

final currentConnectedDeviceProvider = Provider<DeviceModel?>((ref) {
  final devicesAsync = ref.watch(devicesStreamProvider);
  return devicesAsync.maybeWhen(
    data: (devices) {
      try {
        return devices.firstWhere((d) => d.isCurrent);
      } catch (_) {
        return devices.isNotEmpty ? devices.first : null;
      }
    },
    orElse: () => null,
  );
});
