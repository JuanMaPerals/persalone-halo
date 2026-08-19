import 'dart:async';

import 'package:flutter/services.dart';
import 'package:persalone_contracts/persalone_contracts.dart';

/// Testable boundary over Android's AudioRecord and AudioTrack channels.
abstract interface class AndroidHostAudioBridge {
  Stream<Map<Object?, Object?>> get inputEvents;
  Stream<Map<Object?, Object?>> get outputEvents;

  Future<bool> requestMicrophonePermission();
  Future<void> startInput(AudioFormat format);
  Future<void> stopInput();
  Future<void> startOutput(AudioFormat format);
  Future<Map<Object?, Object?>> writeOutput(
    Uint8List pcm, {
    required int capturedAtMicros,
    required int durationMicros,
  });
  Future<void> stopOutput();
}

/// Production bridge used only by the Android host application.
final class MethodChannelAndroidHostAudioBridge implements AndroidHostAudioBridge {
  MethodChannelAndroidHostAudioBridge({
    MethodChannel? inputChannel,
    MethodChannel? outputChannel,
    EventChannel? inputEventChannel,
    EventChannel? outputEventChannel,
  })  : _inputChannel = inputChannel ?? const MethodChannel(_inputChannelName),
        _outputChannel = outputChannel ?? const MethodChannel(_outputChannelName),
        _inputEventChannel =
            inputEventChannel ?? const EventChannel(_inputEventsChannelName),
        _outputEventChannel =
            outputEventChannel ?? const EventChannel(_outputEventsChannelName);

  static const String _inputChannelName = 'persalone.audio/input';
  static const String _outputChannelName = 'persalone.audio/output';
  static const String _inputEventsChannelName = 'persalone.audio/input_events';
  static const String _outputEventsChannelName = 'persalone.audio/output_events';

  final MethodChannel _inputChannel;
  final MethodChannel _outputChannel;
  final EventChannel _inputEventChannel;
  final EventChannel _outputEventChannel;

  @override
  Stream<Map<Object?, Object?>> get inputEvents => _inputEventChannel
      .receiveBroadcastStream()
      .map(_mapEvent);

  @override
  Stream<Map<Object?, Object?>> get outputEvents => _outputEventChannel
      .receiveBroadcastStream()
      .map(_mapEvent);

  @override
  Future<bool> requestMicrophonePermission() async {
    return await _inputChannel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<void> startInput(AudioFormat format) {
    return _inputChannel.invokeMethod<void>('start', _formatArguments(format));
  }

  @override
  Future<void> stopInput() {
    return _inputChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> startOutput(AudioFormat format) {
    return _outputChannel.invokeMethod<void>('start', _formatArguments(format));
  }

  @override
  Future<Map<Object?, Object?>> writeOutput(
    Uint8List pcm, {
    required int capturedAtMicros,
    required int durationMicros,
  }) async {
    final Map<Object?, Object?>? result =
        await _outputChannel.invokeMapMethod<Object?, Object?>('write', <String, Object?>{
      'pcm': pcm,
      'capturedAtMicros': capturedAtMicros,
      'durationMicros': durationMicros,
    });
    return result ?? const <Object?, Object?>{};
  }

  @override
  Future<void> stopOutput() {
    return _outputChannel.invokeMethod<void>('stop');
  }

  static Map<Object?, Object?> _mapEvent(dynamic event) {
    if (event is! Map<Object?, Object?>) {
      throw PlatformException(
        code: 'invalid_audio_event',
        message: 'Native Android audio event is not a map.',
      );
    }
    return event;
  }

  static Map<String, Object> _formatArguments(AudioFormat format) {
    return <String, Object>{
      'sampleRateHz': format.sampleRateHz,
      'channels': format.channels,
      'bytesPerSample': format.bytesPerSample,
    };
  }
}
