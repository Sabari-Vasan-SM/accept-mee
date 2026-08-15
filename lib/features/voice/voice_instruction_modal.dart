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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.surfaceBorderHighlight, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorderHighlight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Header
          Text(
            isListening ? 'Listening to Instruction...' : 'Voice Instruction Ready',
            style: AppTypography.titleLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            isListening
                ? 'Speak clearly into your phone mic'
                : 'Review transcribed instruction before sending',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),

          const SizedBox(height: 28),

          // Animated Audio Waveform
          if (isListening) ...[
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(14, (index) {
                  final height = 10.0 + (amplitude * 38.0 * (0.4 + (index % 5) * 0.15));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4,
                    height: height.clamp(8.0, 48.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
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
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isListening ? AppColors.primary : AppColors.surfaceBorder,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _textController,
              onChanged: (val) {
                setState(() => _isEditing = true);
              },
              maxLines: 4,
              style: AppTypography.bodyLarge.copyWith(fontSize: 16, height: 1.4),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isListening ? 'Speaking...' : 'Enter or speak instructions...',
                hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Action Controls
          if (isListening) ...[
            // Stop & Review Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceBorderHighlight,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('Stop Recording & Review'),
              onPressed: () async {
                HapticUtil.medium();
                await speechService.stopListening();
              },
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            backgroundColor: AppColors.surfaceElevated,
                            content: Text(
                              'Voice instruction sent to Antigravity!',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryLight),
                            ),
                            behavior: SnackBarBehavior.floating,
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
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w800,
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
