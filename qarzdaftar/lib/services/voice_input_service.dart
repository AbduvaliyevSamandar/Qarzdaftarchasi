import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  Future<bool> ensureAvailable() async {
    if (_initialized) return _available;
    _available = await _speech.initialize(onError: (e) {}, onStatus: (_) {});
    _initialized = true;
    return _available;
  }

  bool get isListening => _speech.isListening;

  Future<void> start({
    required void Function(String text) onText,
    String localeId = 'uz_UZ',
  }) async {
    if (!_initialized) await ensureAvailable();
    if (!_available) return;

    final locales = await _speech.locales();
    final picked = locales
        .where((l) => l.localeId.startsWith('uz') || l.localeId.startsWith('ru'))
        .map((l) => l.localeId)
        .firstOrNull;

    await _speech.listen(
      onResult: (result) => onText(result.recognizedWords),
      localeId: picked ?? localeId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
