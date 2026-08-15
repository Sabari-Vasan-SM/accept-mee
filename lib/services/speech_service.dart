import 'dart:async';
import 'dart:math';

enum SpeechStatus {
  idle,
  listening,
  processing,
  recognized,
  error;
}

class SpeechService {
  final _statusController = StreamController<SpeechStatus>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  SpeechStatus _status = SpeechStatus.idle;
  String _recognizedText = '';
  Timer? _waveformTimer;
  Timer? _recognitionTimer;

  Stream<SpeechStatus> get statusStream => _statusController.stream;
  Stream<String> get textStream => _textController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  SpeechStatus get currentStatus => _status;
  String get currentText => _recognizedText;

  void _setStatus(SpeechStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Start voice listening with real-time waveform and realistic natural speech simulation
  Future<void> startListening({String? presetPhrase}) async {
    _recognizedText = '';
    _textController.add('');
    _setStatus(SpeechStatus.listening);

    // Simulate animated audio waveform amplitudes
    final random = Random();
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_status == SpeechStatus.listening) {
        final amp = 0.2 + random.nextDouble() * 0.8;
        _amplitudeController.add(amp);
      }
    });

    // Simulate speech-to-text live stream
    final phrase = presetPhrase ?? _getRandomVoicePrompt();
    final words = phrase.split(' ');
    int wordIdx = 0;

    _recognitionTimer?.cancel();
    _recognitionTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_status == SpeechStatus.listening && wordIdx < words.length) {
        if (_recognizedText.isEmpty) {
          _recognizedText = words[wordIdx];
        } else {
          _recognizedText += ' ${words[wordIdx]}';
        }
        _textController.add(_recognizedText);
        wordIdx++;
      } else if (wordIdx >= words.length) {
        timer.cancel();
      }
    });
  }

  String _getRandomVoicePrompt() {
    final prompts = [
      'Fix the login API error and run the tests.',
      'Refactor user authentication to support Google and GitHub OAuth2.',
      'Optimize database queries in the products endpoint and add caching.',
      'Run unit tests for all components and generate a test coverage report.',
      'Add dark mode support to the checkout page layout.',
    ];
    final random = Random();
    return prompts[random.nextInt(prompts.length)];
  }

  Future<String> stopListening() async {
    _waveformTimer?.cancel();
    _recognitionTimer?.cancel();
    _setStatus(SpeechStatus.processing);

    await Future.delayed(const Duration(milliseconds: 350));
    _setStatus(SpeechStatus.recognized);
    return _recognizedText;
  }

  void cancel() {
    _waveformTimer?.cancel();
    _recognitionTimer?.cancel();
    _recognizedText = '';
    _setStatus(SpeechStatus.idle);
  }

  void dispose() {
    cancel();
    _statusController.close();
    _textController.close();
    _amplitudeController.close();
  }
}
