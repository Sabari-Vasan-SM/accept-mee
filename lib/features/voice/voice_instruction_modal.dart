import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/haptic_feedback_util.dart';
import '../../providers/antigravity_provider.dart';
import '../../providers/voice_provider.dart';
import '../../services/speech_service.dart';

class VoiceInstructionModal extends ConsumerStatefulWidget {
  const VoiceInstructionModal({super.key});

  @override
  ConsumerState<VoiceInstructionModal> createState() => _VoiceInstructionModalState();
}

class _VoiceInstructionModalState extends ConsumerState<VoiceInstructionModal> {
  final _textController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceSession();
    });
  }

  void _startVoiceSession() {
    final speech = ref.read(speechServiceProvider);
    speech.startListening();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speechService = ref.read(speechServiceProvider);
    final statusAsync = ref.watch(speechStatusProvider);
    final textAsync = ref.watch(speechTextProvider);
    final ampAsync = ref.watch(speechAmplitudeProvider);
    final client = ref.read(antigravityClientProvider);

    final status = statusAsync.value ?? speechService.currentStatus;
    final liveText = textAsync.value ?? speechService.currentText;
    final amplitude = ampAsync.value ?? 0.5;

    if (!_isEditing && liveText.isNotEmpty && _textController.text != liveText) {
      _textController.text = liveText;
    }

    final isListening = status == SpeechStatus.listening;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Header
          Text(
            isListening ? 'Listening...' : 'Voice Instruction Ready',
            style: AppTypography.headlineMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            isListening
                ? 'Speak instructions naturally into your mic'
                : 'Review transcribed text before sending to Antigravity',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),

          const SizedBox(height: 28),

          // Animated M3 Equalizer / Waveform
          if (isListening) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(14, (index) {
                  final height = 12.0 + (amplitude * 38.0 * (0.4 + (index % 5) * 0.15));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: height.clamp(8.0, 48.0),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Transcribed Text Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isListening ? AppColors.primary : AppColors.outlineVariant,
                width: isListening ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _textController,
              onChanged: (val) {
                setState(() => _isEditing = true);
              },
              maxLines: 4,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isListening ? 'Listening to voice...' : 'Enter or speak instructions...',
                hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Action Controls
          if (isListening) ...[
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHighest,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () async {
                HapticUtil.medium();
                await speechService.stopListening();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stop_circle_rounded, size: 20, color: AppColors.statusError),
                  const SizedBox(width: 8),
                  Text('Stop Recording & Review', style: AppTypography.labelLarge),
                ],
              ),
            ),
          ] else ...[
            // Send or Cancel Confirmation
            Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      HapticUtil.selection();
                      speechService.cancel();
                      Navigator.pop(context);
                    },
                    child: Text('Cancel', style: AppTypography.labelLarge),
                  ),
                ),

                const SizedBox(width: 14),

                // Send
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        HapticUtil.success();
                        client.sendInstruction(text, source: 'voice');
                        speechService.cancel();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceContainerHighest,
                            content: Text(
                              'Voice instruction sent to Antigravity!',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Send to Agent',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
