import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/services/voice_recognition_service.dart';

class VoiceBufferAccumulator {
  final List<String> _confirmedChunks = [];
  String _activeChunk = '';

  String get fullText {
    if (_confirmedChunks.isEmpty) return _activeChunk;
    if (_activeChunk.isEmpty) return _confirmedChunks.join(' ');
    return '${_confirmedChunks.join(' ')} $_activeChunk';
  }

  void onNewText(String newText, bool isFinal) {
    newText = newText.trim();
    if (newText.isEmpty) return;

    if (isFinal) {
      _commit(newText);
      return;
    }

    if (_activeChunk.isEmpty) {
      _activeChunk = newText;
      return;
    }

    if (_isNewChunk(newText)) {
      _commit(_activeChunk);
      _activeChunk = newText;
    } else {
      _activeChunk = newText;
    }
  }

  void _commit(String text) {
    if (text.isNotEmpty) {
      _confirmedChunks.add(text);
      _activeChunk = '';
    }
  }

  bool _isNewChunk(String newText) {
    int commonLen = 0;
    int minLen = math.min(_activeChunk.length, newText.length);
    for (int i = 0; i < minLen; i++) {
      if (_activeChunk[i] == newText[i]) {
        commonLen++;
      } else {
        break;
      }
    }
    // 如果連前兩個字都不一樣 (或長度不足但全不同)，代表 OS 已經清空緩衝區，這是一個全新的句子
    if (commonLen < 2 && _activeChunk.length >= 2) return true;
    if (commonLen == 0) return true;
    return false;
  }
}

class AiVoiceState {
  final bool isListening;
  final bool hasError;
  final String recognizedText; // 本次麥克風連線的純語音文字
  
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
  VoiceBufferAccumulator _accumulator = VoiceBufferAccumulator();
  
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
    } else {
      _accumulator = VoiceBufferAccumulator();
      state = const AiVoiceState(isListening: true, hasError: false, recognizedText: '');
      
      await _voiceService.startListening(
        onResult: (text, isFinal) {
          _accumulator.onNewText(text, isFinal);
          state = state.copyWith(recognizedText: _accumulator.fullText);
        }
      );
    }
  }
  
  Future<void> stopListening() async {
    if (state.isListening) {
      await _voiceService.stopListening();
    }
  }

  void clearText() {
    _accumulator = VoiceBufferAccumulator();
    state = state.copyWith(recognizedText: '');
  }
}

final aiVoiceControllerProvider = NotifierProvider<AiVoiceController, AiVoiceState>(() {
  return AiVoiceController();
});
