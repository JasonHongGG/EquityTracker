import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/services/voice_recognition_service.dart';

class AiVoiceState {
  final bool isListening;
  final bool hasError;
  final String recognizedText;
  
  const AiVoiceState({
    this.isListening = false,
    this.hasError = false,
    this.recognizedText = '',
  });
  
  AiVoiceState copyWith({
    bool? isListening,
    bool? hasError,
    String? recognizedText,
  }) {
    return AiVoiceState(
      isListening: isListening ?? this.isListening,
      hasError: hasError ?? this.hasError,
      recognizedText: recognizedText ?? this.recognizedText,
    );
  }
}

final voiceRecognitionServiceProvider = Provider((ref) => VoiceRecognitionService());

class AiVoiceController extends Notifier<AiVoiceState> {
  late VoiceRecognitionService _voiceService;
  
  @override
  AiVoiceState build() {
    _voiceService = ref.watch(voiceRecognitionServiceProvider);
    return const AiVoiceState();
  }
  
  Future<void> initialize() async {
    await _voiceService.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          state = state.copyWith(isListening: false);
        } else if (status == 'error') {
          state = state.copyWith(isListening: false, hasError: true);
        }
      }
    );
  }
  
  Future<void> toggleListening() async {
    if (state.isListening) {
      await _voiceService.stopListening();
      state = state.copyWith(isListening: false);
    } else {
      // Clear previous text
      state = state.copyWith(recognizedText: '', hasError: false, isListening: true);
      
      await _voiceService.startListening(
        onResult: (text) {
          state = state.copyWith(recognizedText: text);
        }
      );
    }
  }
  
  Future<void> stopListening() async {
    if (state.isListening) {
      await _voiceService.stopListening();
      state = state.copyWith(isListening: false);
    }
  }

  void clearText() {
    state = state.copyWith(recognizedText: '');
  }
}

final aiVoiceControllerProvider = NotifierProvider<AiVoiceController, AiVoiceState>(() {
  return AiVoiceController();
});
