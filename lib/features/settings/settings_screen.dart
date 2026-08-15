import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: Text('Companion Settings', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Section: Desktop Companion Connection
          _buildSectionHeader('Desktop Companion Bridge'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: AppTypography.bodyMedium),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connectionStatus == ConnectionStatus.connected
                                ? AppColors.statusSuccess
                                : AppColors.statusError,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connectionStatus.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: connectionStatus == ConnectionStatus.connected
                                ? AppColors.statusSuccess
                                : AppColors.statusError,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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

          // Section: Simulation & Testing Modes
          _buildSectionHeader('Testing & Simulation Scenarios'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Offline Simulator Client', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  subtitle: Text('Run standalone interactive simulation without desktop server', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  value: settings.useMockClient,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    HapticUtil.selection();
                    settingsNotifier.setUseMockClient(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bolt_rounded, color: AppColors.statusWarning),
                  title: Text('Trigger DB Migration Approval', style: AppTypography.bodyLarge.copyWith(fontSize: 14)),
                  subtitle: Text('Simulates arrival of a high-risk approval request', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticUtil.medium();
                    client.triggerDemoScenario('db_migration');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated approval request sent! Check the Approvals tab.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.build_circle_rounded, color: AppColors.primary),
                  title: Text('Trigger Production Build Approval', style: AppTypography.bodyLarge.copyWith(fontSize: 14)),
                  subtitle: Text('Simulates npm run build permission request', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticUtil.medium();
                    client.triggerDemoScenario('build');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated build approval sent!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Security & Preferences
          _buildSectionHeader('Security & Preferences'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
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
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.statusError),
                  title: Text('Clear Session & Unpair', style: AppTypography.bodyLarge.copyWith(color: AppColors.statusError, fontSize: 14)),
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
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }
}
