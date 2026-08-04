import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;

  /// Initializes the speech-to-text engine and requests permissions.
  Future<bool> initialize({required void Function(String status) onStatus}) async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: onStatus,
        onError: (error) {
          onStatus('error');
        },
      );
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Starts listening for speech and calls [onResult] with recognized words.
  Future<void> startListening({required void Function(String recognizedWords) onResult}) async {
    if (!_isInitialized) {
      final success = await initialize(onStatus: (_) {});
      if (!success) return;
    }
    
    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: 'zh_TW', // Default to traditional Chinese
      pauseFor: const Duration(seconds: 5), // Allow longer pauses before auto-stopping
    );
  }

  /// Stops listening for speech.
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isInitialized => _isInitialized;
}
