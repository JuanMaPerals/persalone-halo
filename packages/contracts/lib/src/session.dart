import 'runtime_error.dart';

/// Direction of one translated conversational turn.
enum TranslationDirection { englishToSpanish, spanishToEnglish }

/// Transport-neutral audio metadata. Audio payloads are intentionally absent
/// from the shared contract and must never enter logs or telemetry by default.
final class AudioFrameMetadata {
  const AudioFrameMetadata({
    required this.sessionId,
    required this.streamId,
    required this.streamEpoch,
    required this.sequence,
    required this.capturedAtMicros,
    required this.sampleRateHz,
    required this.channels,
    required this.durationMicros,
    required this.codec,
    this.discontinuity = false,
  });

  final String sessionId;
  final String streamId;
  final int streamEpoch;
  final int sequence;
  final int capturedAtMicros;
  final int sampleRateHz;
  final int channels;
  final int durationMicros;
  final String codec;
  final bool discontinuity;
}

/// Session identity and cancellation generation for a translation turn.
final class TranslationSession {
  const TranslationSession({
    required this.sessionId,
    required this.streamEpoch,
    required this.direction,
    required this.privacyGeneration,
  });

  final String sessionId;
  final int streamEpoch;
  final TranslationDirection direction;
  final int privacyGeneration;

  void validateFrame(AudioFrameMetadata frame) {
    if (frame.sessionId != sessionId || frame.streamEpoch != streamEpoch) {
      throw const RuntimeError(
        RuntimeErrorCode.staleStreamEpoch,
        'Frame belongs to an inactive session generation.',
      );
    }
  }
}
