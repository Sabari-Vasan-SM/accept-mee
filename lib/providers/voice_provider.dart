import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/speech_service.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(() => service.dispose());
  return service;
});

final speechStatusProvider = StreamProvider<SpeechStatus>((ref) {
  final service = ref.watch(speechServiceProvider);
  return service.statusStream;
});

final speechTextProvider = StreamProvider<String>((ref) {
  final service = ref.watch(speechServiceProvider);
  return service.textStream;
});

final speechAmplitudeProvider = StreamProvider<double>((ref) {
  final service = ref.watch(speechServiceProvider);
  return service.amplitudeStream;
});
