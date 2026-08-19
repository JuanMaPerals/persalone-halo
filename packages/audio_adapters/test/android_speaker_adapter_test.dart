import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:persalone_audio_adapters/persalone_audio_adapters.dart';
import 'package:persalone_contracts/persalone_contracts.dart';

const AudioSessionDescriptor testSession = AudioSessionDescriptor(
  sessionId: 'test-session',
  streamEpoch: 2,
  streamId: 'output-1',
);

void main() {
  test('writes canonical PCM frames through the output bridge', () async {
    final _OutputBridge bridge = _OutputBridge();
    final AndroidSpeakerAdapter adapter = AndroidSpeakerAdapter(
      bridge: bridge,
      nowMicros: () => 400,
    );
    addTearDown(adapter.dispose);

    await adapter.start(testSession, AudioFormat.voice16kMono);
    await adapter.enqueue(_frame());

    expect(bridge.startedOutput, isTrue);
    expect(bridge.writtenPcm, Uint8List.fromList(<int>[1, 0, 2, 0]));
  });

  test('rejects mismatched output frames instead of writing them', () async {
    final _OutputBridge bridge = _OutputBridge();
    final AndroidSpeakerAdapter adapter = AndroidSpeakerAdapter(
      bridge: bridge,
      nowMicros: () => 500,
    );
    addTearDown(adapter.dispose);

    await adapter.start(testSession, AudioFormat.voice16kMono);
    final AudioFrame mismatched = AudioFrame(
      schemaVersion: CapabilityManifest.currentSchemaVersion,
      session: testSession,
      direction: AudioDirection.input,
      sequence: 1,
      codec: AudioCodec.pcmS16le,
      format: AudioFormat.voice16kMono,
      capturedAtMicros: 1,
      receivedAtMicros: 1,
      durationMicros: 125,
      payload: Uint8List.fromList(<int>[1, 0]),
    );

    expect(
      adapter.enqueue(mismatched),
      throwsA(
        isA<RuntimeError>().having(
          (RuntimeError error) => error.code,
          'code',
          RuntimeErrorCode.invalidContract,
        ),
      ),
    );
  });

  test('records real-device timestamp metadata as prepared evidence', () async {
    final _OutputBridge bridge = _OutputBridge(
      writeResult: <Object?, Object?>{
        'writtenBytes': 4,
        'underrunCount': 1,
        'presentationTimestampMicros': 800,
        'framePosition': 12,
      },
    );
    final AndroidSpeakerAdapter adapter = AndroidSpeakerAdapter(
      bridge: bridge,
      nowMicros: () => 600,
    );
    addTearDown(adapter.dispose);

    await adapter.start(testSession, AudioFormat.voice16kMono);
    final Future<AudioLatencyMeasurement> measurement = adapter.latencyMeasurements
        .where((AudioLatencyMeasurement value) =>
            value.stage == AudioLatencyStage.outputPresentation)
        .first;
    await adapter.enqueue(_frame());

    expect((await measurement).truthLabel, TruthLabel.prepared);
  });
}

AudioFrame _frame() {
  return AudioFrame(
    schemaVersion: CapabilityManifest.currentSchemaVersion,
    session: testSession,
    direction: AudioDirection.output,
    sequence: 1,
    codec: AudioCodec.pcmS16le,
    format: AudioFormat.voice16kMono,
    capturedAtMicros: 10,
    receivedAtMicros: 20,
    durationMicros: 125,
    payload: Uint8List.fromList(<int>[1, 0, 2, 0]),
  );
}

final class _OutputBridge implements AndroidHostAudioBridge {
  _OutputBridge({Map<Object?, Object?>? writeResult})
      : _writeResult = writeResult ?? const <Object?, Object?>{'writtenBytes': 4};

  final Map<Object?, Object?> _writeResult;
  final StreamController<Map<Object?, Object?>> _input =
      StreamController<Map<Object?, Object?>>.broadcast();
  final StreamController<Map<Object?, Object?>> _output =
      StreamController<Map<Object?, Object?>>.broadcast();
  bool startedOutput = false;
  Uint8List? writtenPcm;

  @override
  Stream<Map<Object?, Object?>> get inputEvents => _input.stream;

  @override
  Stream<Map<Object?, Object?>> get outputEvents => _output.stream;

  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<void> startInput(AudioFormat format) async {}

  @override
  Future<void> stopInput() async {}

  @override
  Future<void> startOutput(AudioFormat format) async {
    startedOutput = true;
  }

  @override
  Future<void> stopOutput() async {
    startedOutput = false;
  }

  @override
  Future<Map<Object?, Object?>> writeOutput(
    Uint8List pcm, {
    required int capturedAtMicros,
    required int durationMicros,
  }) async {
    writtenPcm = Uint8List.fromList(pcm);
    return _writeResult;
  }
}
