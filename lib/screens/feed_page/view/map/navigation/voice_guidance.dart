import 'package:flutter_tts/flutter_tts.dart';

/// Speaks turn instructions. The route instructions come back from the
/// routing API in English, so the voice is English (India) to match.
class VoiceGuidance {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool muted = false;

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      // Let the music/order-alert audio duck under the voice on iOS
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await _tts.awaitSpeakCompletion(false);
      _ready = true;
    } catch (_) {
      // No TTS engine on the device: navigation still works without voice
    }
  }

  Future<void> speak(String text) async {
    if (!_ready || muted || text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
