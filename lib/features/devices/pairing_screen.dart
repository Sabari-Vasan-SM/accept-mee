import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../models/pairing_payload.dart';
import '../../../core/storage/storage_service.dart';
import '../../../providers/antigravity_provider.dart';
import '../../../providers/settings_provider.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  late final TextEditingController _hostController;
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController();

  bool _isManual = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: StorageService.defaultHost);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handlePairingPayload(PairingPayload payload) async {
    setState(() => _isConnecting = true);
    HapticUtil.success();

    // Go through the notifier rather than StorageService directly, so the
    // Settings screen's "paired" state updates with us.
    final settings = ref.read(settingsProvider.notifier);
    await settings.updateServer(payload.host, payload.port);
    await settings.setAuthToken(payload.token);
    await settings.setDeviceName(payload.deviceName);

    final client = ref.read(antigravityClientProvider);
    final success = await client.connect(
      host: payload.host,
      port: payload.port,
      token: payload.token,
    );

    if (mounted) {
      setState(() => _isConnecting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceContainerHighest,
            content: Text(
              'Successfully paired with ${payload.deviceName}!',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.statusSuccess),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text(
              'Failed to connect to ${payload.host}:${payload.port}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.onErrorContainer),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pair Desktop Computer', style: AppTypography.headlineMedium),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(_isManual ? Icons.qr_code_scanner_rounded : Icons.keyboard_rounded),
            onPressed: () {
              HapticUtil.selection();
              setState(() => _isManual = !_isManual);
            },
            tooltip: _isManual ? 'Scan QR Code' : 'Manual Setup',
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _isManual ? _buildManualForm() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final payload = PairingPayload.tryParse(barcode.rawValue!);
                if (payload != null && !_isConnecting) {
                  _handlePairingPayload(payload);
                  break;
                }
              }
            }
          },
        ),

        // Scanning Target Overlay
        Center(
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),

        // Bottom instruction card
        Positioned(
          bottom: 36,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan the QR code printed by the companion server '
                  '(run "npm start" in companion_server).',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'No camera? Use the keyboard button above to enter the host, '
                  'port and token by hand.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isConnecting)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildManualForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Connection Details',
            style: AppTypography.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the IP address and port of your Antigravity companion server.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),

          Text('Host / IP Address', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _hostController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: '192.168.1.100 or 127.0.0.1',
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text('Port', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: '8765',
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text('Pairing Security Token (Optional)',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _tokenController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: 'e.g. 7f8a9c2e...',
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _isConnecting
                  ? null
                  : () {
                      final host = _hostController.text.trim();
                      final port = int.tryParse(_portController.text.trim()) ?? 8765;
                      final token = _tokenController.text.trim();

                      // The token is mandatory now that the server enforces it;
                      // pairing without one would just fail with a 401.
                      if (host.isEmpty || token.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.errorContainer,
                            content: Text(
                              'Enter both a host and the pairing token printed by the server.',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.onErrorContainer),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                        return;
                      }

                      _handlePairingPayload(
                        PairingPayload(
                          version: '2.0',
                          protocol: 'antigravity-bridge',
                          host: host,
                          port: port,
                          token: token,
                          deviceName: 'Custom Host ($host)',
                          wsUrl: 'ws://$host:$port/ws',
                          httpUrl: 'http://$host:$port/api/v1',
                        ),
                      );
                    },
              child: _isConnecting
                  ? const CircularProgressIndicator(color: AppColors.onPrimary)
                  : const Text('Connect to Host'),
            ),
          ),
        ],
      ),
    );
  }
}
