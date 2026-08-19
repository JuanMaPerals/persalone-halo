import 'dart:typed_data';

import 'truth_label.dart';

/// Direction in which a PCM frame travels through an audio adapter.
enum AudioDirection { input, output }

/// Lifecycle states shared by host and wearable audio adapters.
enum AudioAdapterState {
  idle,
  permissionRequired,
  starting,
  streaming,
  stopping,
  stopped,
  failed,
  disposed,
}

/// The only codec admitted to G3/G4. Later codecs require a contract revision.
enum AudioCodec { pcmS16le }

/// Canonical PCM format for the runtime boundary.
final class AudioFormat {
  const AudioFormat({
    required this.sampleRateHz,
    required this.channels,
    this.bytesPerSample = 2,
  })  : assert(sampleRateHz > 0),
        assert(channels > 0),
        assert(bytesPerSample > 0);

  static const AudioFormat voice16kMono = AudioFormat(
    sampleRateHz: 16000,
    channels: 1,
  );

  final int sampleRateHz;
  final int channels;
  final int bytesPerSample;

  int get bytesPerFrame => channels * bytesPerSample;
}

/// Identifies one locally bounded audio session without exposing user identity.
final class AudioSessionDescriptor {
  const AudioSessionDescriptor({
    required this.sessionId,
    required this.streamEpoch,
    required this.streamId,
  });

  final String sessionId;
  final int streamEpoch;
  final String streamId;
}

/// A versioned PCM frame. Payload must never enter diagnostics, telemetry, or
/// logs. [capturedAtMicros] and [presentedAtMicros] use a monotonic timebase.
final class AudioFrame {
  AudioFrame({
    required this.schemaVersion,
    required this.session,
    required this.direction,
    required this.sequence,
    required this.codec,
    required this.format,
    required this.capturedAtMicros,
    required this.receivedAtMicros,
    required this.durationMicros,
    required Uint8List payload,
    this.presentedAtMicros,
    this.discontinuity = false,
  }) : _payload = Uint8List.fromList(payload);

  final String schemaVersion;
  final AudioSessionDescriptor session;
  final AudioDirection direction;
  final int sequence;
  final AudioCodec codec;
  final AudioFormat format;
  final int capturedAtMicros;
  final int receivedAtMicros;
  final int? presentedAtMicros;
  final int durationMicros;
  final bool discontinuity;
  final Uint8List _payload;

  Uint8List get payload => Uint8List.fromList(_payload);
}

/// Coded counters and events that never carry PCM, transcripts, device IDs,
/// provider data, or raw timestamps associated with a person.
enum AudioDiagnosticCode {
  permissionRequested,
  permissionGranted,
  permissionDenied,
  captureStarted,
  captureStopped,
  inputFrame,
  inputDropped,
  captureReadError,
  captureTimestampAvailable,
  captureTimestampUnavailable,
  playbackStarted,
  playbackStopped,
  outputFrameQueued,
  outputPartialWrite,
  outputUnderrun,
  outputTimestampAvailable,
  outputTimestampUnavailable,
  routeChanged,
  capabilityBlocked,
}

/// Structured, redacted diagnostic from an input or output adapter.
final class AudioDiagnostic {
  const AudioDiagnostic({
    required this.code,
    required this.adapterId,
    required this.observedAtMicros,
    this.sequence,
    this.value,
    this.detail,
  });

  final AudioDiagnosticCode code;
  final String adapterId;
  final int observedAtMicros;
  final int? sequence;
  final int? value;
  final String? detail;
}

/// A measurement from an operating system audio timestamp or an explicit human
/// verification procedure. It is not a fabricated latency estimate.
enum AudioLatencyStage { inputCapture, outputPresentation, humanAudible }

final class AudioLatencyMeasurement {
  const AudioLatencyMeasurement({
    required this.stage,
    required this.adapterId,
    required this.observedAtMicros,
    required this.truthLabel,
    required this.method,
    this.latencyMicros,
    this.framePosition,
  });

  final AudioLatencyStage stage;
  final String adapterId;
  final int observedAtMicros;
  final TruthLabel truthLabel;
  final String method;
  final int? latencyMicros;
  final int? framePosition;
}

/// Immutable adapter state suitable for UI and evidence without PCM.
final class AudioAdapterSnapshot {
  const AudioAdapterSnapshot({
    required this.state,
    required this.adapterId,
    required this.sourceRevision,
    required this.truthLabel,
    required this.observedAtMicros,
    this.format,
    this.failureReason,
  });

  final AudioAdapterState state;
  final String adapterId;
  final String sourceRevision;
  final TruthLabel truthLabel;
  final int observedAtMicros;
  final AudioFormat? format;
  final String? failureReason;
}

/// Canonical input port. Android and Halo implementations must use it rather
/// than allowing STT to read directly from platform APIs.
abstract interface class AudioInputAdapter {
  String get adapterId;
  String get sourceRevision;
  Stream<AudioAdapterSnapshot> get snapshots;
  Stream<AudioDiagnostic> get diagnostics;
  Stream<AudioLatencyMeasurement> get latencyMeasurements;
  Stream<AudioFrame> get frames;

  Future<bool> requestPermission();
  Future<void> start(AudioSessionDescriptor session, AudioFormat format);
  Future<void> stop();
  Future<void> dispose();
}

/// Canonical output port. Android and Halo implementations must use it rather
/// than allowing TTS to write directly to platform APIs.
abstract interface class AudioOutputAdapter {
  String get adapterId;
  String get sourceRevision;
  Stream<AudioAdapterSnapshot> get snapshots;
  Stream<AudioDiagnostic> get diagnostics;
  Stream<AudioLatencyMeasurement> get latencyMeasurements;

  Future<void> start(AudioSessionDescriptor session, AudioFormat format);
  Future<void> enqueue(AudioFrame frame);
  Future<void> stop();
  Future<void> dispose();
}
