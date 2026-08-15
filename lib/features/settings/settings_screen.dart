import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/antigravity_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _hostController = TextEditingController(text: settings.serverHost);
    _portController = TextEditingController(text: settings.serverPort.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final client = ref.read(antigravityClientProvider);
    final connectionStatusAsync = ref.watch(connectionStatusProvider);
    final connectionStatus = connectionStatusAsync.value ?? ConnectionStatus.disconnected;

    return Scaffold(
      appBar: AppBar(
        title: Text('Companion Settings', style: AppTypography.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Section: Desktop Companion Connection
          _buildSectionHeader('Desktop Companion Bridge'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: AppTypography.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: connectionStatus == ConnectionStatus.connected
                            ? AppColors.tertiaryContainer
                            : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connectionStatus == ConnectionStatus.connected
                                  ? AppColors.tertiary
                                  : AppColors.statusError,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connectionStatus.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: connectionStatus == ConnectionStatus.connected
                                  ? AppColors.onTertiaryContainer
                                  : AppColors.onErrorContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _hostController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Host IP',
                          labelStyle: AppTypography.labelSmall,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          labelStyle: AppTypography.labelSmall,
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      HapticUtil.medium();
                      final host = _hostController.text.trim();
                      final port = int.tryParse(_portController.text.trim()) ?? 8765;
                      await settingsNotifier.updateServer(host, port);
                      client.connect(host: host, port: port);
                    },
                    child: const Text('Save & Reconnect'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Pairing
          _buildSectionHeader('Pairing'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (settings.isPaired ? AppColors.statusSuccess : AppColors.statusWarning)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      settings.isPaired ? Icons.verified_rounded : Icons.qr_code_scanner_rounded,
                      color: settings.isPaired ? AppColors.statusSuccess : AppColors.statusWarning,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    settings.isPaired ? 'Paired with desktop' : 'Not paired',
                    style: AppTypography.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    settings.isPaired
                        ? 'Scan again if the desktop reports an invalid token'
                        : 'Scan the QR code printed by the companion server',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticUtil.medium();
                    context.push('/pairing');
                  },
                ),
                if (settings.isPaired) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusError.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.link_off_rounded, color: AppColors.statusError, size: 20),
                    ),
                    title: Text('Forget this desktop',
                        style: AppTypography.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: Text('Clears the stored pairing token from this phone',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                    onTap: () async {
                      HapticUtil.medium();
                      await settingsNotifier.clearAuth();
                      await client.disconnect();
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Security & Preferences
          _buildSectionHeader('Security & Preferences'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Biometric App Lock', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  subtitle: Text('Require FaceID / Fingerprint for sensitive approvals', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  value: settings.biometricsEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    HapticUtil.selection();
                    settingsNotifier.setBiometrics(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Haptic Touch Feedback', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  subtitle: Text('Vibrate on approvals, controls, and voice recording', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  value: settings.hapticsEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    HapticUtil.selection();
                    settingsNotifier.setHaptics(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusError.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.statusError, size: 20),
                  ),
                  title: Text('Clear Session & Unpair', style: AppTypography.bodyLarge.copyWith(color: AppColors.statusError, fontSize: 14, fontWeight: FontWeight.w700)),
                  onTap: () {
                    HapticUtil.error();
                    settingsNotifier.clearAuth();
                    client.disconnect();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}
