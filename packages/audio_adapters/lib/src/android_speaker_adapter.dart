import 'dart:async';

import 'package:persalone_contracts/persalone_contracts.dart';

import 'android_host_audio_bridge.dart';

/// Android host output adapter. Android's `AudioTrack` handles physical PCM
/// playback; this class exposes only canonical frames and redacted telemetry.
final class AndroidSpeakerAdapter implements AudioOutputAdapter {
  AndroidSpeakerAdapter({
    required AndroidHostAudioBridge bridge,
    int Function()? nowMicros,
  })  : _bridge = bridge,
        _nowMicros = nowMicros ?? _defaultNowMicros;

  static const String revision = 'android-host-audio/1';
  static final Stopwatch _clock = Stopwatch()..start();

  final AndroidHostAudioBridge _bridge;
  final int Function() _nowMicros;
  final StreamController<AudioAdapterSnapshot> _snapshots =
      StreamController<AudioAdapterSnapshot>.broadcast();
  final StreamController<AudioDiagnostic> _diagnostics =
      StreamController<AudioDiagnostic>.broadcast();
  final StreamController<AudioLatencyMeasurement> _latency =
      StreamController<AudioLatencyMeasurement>.broadcast();

  StreamSubscription<Map<Object?, Object?>>? _eventsSubscription;
  AudioAdapterState _state = AudioAdapterState.idle;
  AudioSessionDescriptor? _session;
  AudioFormat? _format;
  bool _disposed = false;

  @override
  String get adapterId => 'android-speaker-adapter';

  @override
  String get sourceRevision => revision;

  @override
  Stream<AudioAdapterSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<AudioDiagnostic> get diagnostics => _diagnostics.stream;

  @override
  Stream<AudioLatencyMeasurement> get latencyMeasurements => _latency.stream;

  @override
  Future<void> start(AudioSessionDescriptor session, AudioFormat format) async {
    _ensureNotDisposed();
    if (_state == AudioAdapterState.streaming) {
      throw const RuntimeError(
        RuntimeErrorCode.deviceNotReady,
        'Android speaker playback is already streaming.',
      );
    }
    _session = session;
    _format = format;
    _transition(AudioAdapterState.starting);
    try {
      _eventsSubscription = _bridge.outputEvents.listen(
        _onNativeEvent,
        onError: _onNativeError,
      );
      await _bridge.startOutput(format);
      _transition(AudioAdapterState.streaming);
      _emitDiagnostic(AudioDiagnosticCode.playbackStarted);
    } catch (error) {
      await _eventsSubscription?.cancel();
      _eventsSubscription = null;
      _transition(
        AudioAdapterState.failed,
        failureReason: 'Android speaker playback failed to start.',
      );
      _emitDiagnostic(
        AudioDiagnosticCode.outputPartialWrite,
        detail: error.runtimeType.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<void> enqueue(AudioFrame frame) async {
    _ensureStreaming();
    final AudioSessionDescriptor session = _session!;
    final AudioFormat format = _format!;
    if (frame.direction != AudioDirection.output ||
        !_sameSession(frame.session, session) ||
        !_sameFormat(frame.format, format) ||
        frame.codec != AudioCodec.pcmS16le ||
        frame.payload.isEmpty ||
        frame.payload.length % format.bytesPerFrame != 0) {
      _emitDiagnostic(
        AudioDiagnosticCode.outputPartialWrite,
        sequence: frame.sequence,
        detail: 'invalid_output_frame',
      );
      throw const RuntimeError(
        RuntimeErrorCode.invalidContract,
        'Output frame does not match the active Android audio session.',
      );
    }
    final Map<Object?, Object?> result = await _bridge.writeOutput(
      frame.payload,
      capturedAtMicros: frame.capturedAtMicros,
      durationMicros: frame.durationMicros,
    );
    final int writtenBytes = _asInt(result['writtenBytes']) ?? 0;
    _emitDiagnostic(
      AudioDiagnosticCode.outputFrameQueued,
      sequence: frame.sequence,
      value: writtenBytes,
    );
    if (writtenBytes != frame.payload.length) {
      _emitDiagnostic(
        AudioDiagnosticCode.outputPartialWrite,
        sequence: frame.sequence,
        value: writtenBytes,
      );
    }
    final int? underruns = _asInt(result['underrunCount']);
    if (underruns != null && underruns > 0) {
      _emitDiagnostic(AudioDiagnosticCode.outputUnderrun, value: underruns);
    }
    final int? presentation = _asInt(result['presentationTimestampMicros']);
    if (presentation != null) {
      _emitDiagnostic(AudioDiagnosticCode.outputTimestampAvailable);
      _latency.add(
        AudioLatencyMeasurement(
          stage: AudioLatencyStage.outputPresentation,
          adapterId: adapterId,
          observedAtMicros: _nowMicros(),
          truthLabel: TruthLabel.prepared,
          method: 'AudioTrack.getTimestamp; presentation requires real-device verification',
          framePosition: _asInt(result['framePosition']),
        ),
      );
    } else {
      _emitDiagnostic(AudioDiagnosticCode.outputTimestampUnavailable);
    }
  }

  @override
  Future<void> stop() async {
    _ensureNotDisposed();
    if (_state != AudioAdapterState.streaming &&
        _state != AudioAdapterState.starting) {
      return;
    }
    _transition(AudioAdapterState.stopping);
    await _bridge.stopOutput();
    await _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _transition(AudioAdapterState.stopped);
    _emitDiagnostic(AudioDiagnosticCode.playbackStopped);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    if (_state == AudioAdapterState.streaming ||
        _state == AudioAdapterState.starting) {
      await stop();
    }
    _disposed = true;
    _transition(AudioAdapterState.disposed);
    await _snapshots.close();
    await _diagnostics.close();
    await _latency.close();
  }

  void _onNativeEvent(Map<Object?, Object?> event) {
    switch (event['type'] as String? ?? 'unknown') {
      case 'output_underrun':
        _emitDiagnostic(
          AudioDiagnosticCode.outputUnderrun,
          value: _asInt(event['underrunCount']),
        );
      case 'output_timestamp':
        _emitDiagnostic(AudioDiagnosticCode.outputTimestampAvailable);
        _latency.add(
          AudioLatencyMeasurement(
            stage: AudioLatencyStage.outputPresentation,
            adapterId: adapterId,
            observedAtMicros: _nowMicros(),
            truthLabel: TruthLabel.prepared,
            method: 'AudioTrack.getTimestamp(TIMEBASE_MONOTONIC)',
            framePosition: _asInt(event['framePosition']),
          ),
        );
      case 'output_timestamp_unavailable':
        _emitDiagnostic(AudioDiagnosticCode.outputTimestampUnavailable);
      case 'route_changed':
        _emitDiagnostic(AudioDiagnosticCode.routeChanged);
      default:
        _emitDiagnostic(
          AudioDiagnosticCode.outputPartialWrite,
          detail: 'unknown_native_event',
        );
    }
  }

  void _onNativeError(Object error, StackTrace stackTrace) {
    _transition(
      AudioAdapterState.failed,
      failureReason: 'Android speaker event stream failed.',
    );
    _emitDiagnostic(
      AudioDiagnosticCode.outputPartialWrite,
      detail: error.runtimeType.toString(),
    );
  }

  void _ensureStreaming() {
    _ensureNotDisposed();
    if (_state != AudioAdapterState.streaming ||
        _session == null ||
        _format == null) {
      throw const RuntimeError(
        RuntimeErrorCode.deviceNotReady,
        'Android speaker must be streaming before it accepts output frames.',
      );
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const RuntimeError(
        RuntimeErrorCode.sessionClosed,
        'Android speaker adapter has been disposed.',
      );
    }
  }

  void _transition(AudioAdapterState next, {String? failureReason}) {
    _state = next;
    _snapshots.add(
      AudioAdapterSnapshot(
        state: next,
        adapterId: adapterId,
        sourceRevision: sourceRevision,
        truthLabel: TruthLabel.prepared,
        observedAtMicros: _nowMicros(),
        format: _format,
        failureReason: failureReason,
      ),
    );
  }

  void _emitDiagnostic(
    AudioDiagnosticCode code, {
    int? sequence,
    int? value,
    String? detail,
  }) {
    _diagnostics.add(
      AudioDiagnostic(
        code: code,
        adapterId: adapterId,
        observedAtMicros: _nowMicros(),
        sequence: sequence,
        value: value,
        detail: detail,
      ),
    );
  }

  static bool _sameSession(
    AudioSessionDescriptor first,
    AudioSessionDescriptor second,
  ) {
    return first.sessionId == second.sessionId &&
        first.streamEpoch == second.streamEpoch &&
        first.streamId == second.streamId;
  }

  static bool _sameFormat(AudioFormat first, AudioFormat second) {
    return first.sampleRateHz == second.sampleRateHz &&
        first.channels == second.channels &&
        first.bytesPerSample == second.bytesPerSample;
  }

  static int? _asInt(Object? value) => value is int ? value : null;

  static int _defaultNowMicros() => _clock.elapsedMicroseconds;
}
