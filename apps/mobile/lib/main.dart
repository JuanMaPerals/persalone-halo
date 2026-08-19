import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:persalone_audio_adapters/persalone_audio_adapters.dart';
import 'package:persalone_contracts/persalone_contracts.dart';

void main() {
  runApp(const PersalOneApp());
}

/// Android-first G3/G4 shell. It uses the real platform audio path when run on
/// Android. The app never promotes audio capability to MEASURED by itself.
class PersalOneApp extends StatelessWidget {
  const PersalOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PersalOne HORIZON',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const AndroidHostAudioScreen(),
    );
  }
}

class AndroidHostAudioScreen extends StatefulWidget {
  const AndroidHostAudioScreen({super.key});

  @override
  State<AndroidHostAudioScreen> createState() => _AndroidHostAudioScreenState();
}

class _AndroidHostAudioScreenState extends State<AndroidHostAudioScreen> {
  static const AudioFormat _format = AudioFormat.voice16kMono;
  static const int _maxSampleBytes = 32000;
  static final Stopwatch _clock = Stopwatch()..start();

  late final AndroidMicrophoneAdapter _microphone;
  late final AndroidSpeakerAdapter _speaker;
  final BytesBuilder _sample = BytesBuilder(copy: false);
  StreamSubscription<AudioFrame>? _frameSubscription;
  StreamSubscription<AudioDiagnostic>? _inputDiagnosticSubscription;
  StreamSubscription<AudioDiagnostic>? _outputDiagnosticSubscription;

  bool _permissionGranted = false;
  bool _capturing = false;
  bool _playing = false;
  int _inputFrames = 0;
  int _inputDrops = 0;
  int _outputWrites = 0;
  int _underruns = 0;
  String _status = 'Preparado para validar audio Android con evidencia real.';

  @override
  void initState() {
    super.initState();
    final MethodChannelAndroidHostAudioBridge bridge =
        MethodChannelAndroidHostAudioBridge();
    _microphone = AndroidMicrophoneAdapter(bridge: bridge);
    _speaker = AndroidSpeakerAdapter(bridge: bridge);
    _frameSubscription = _microphone.frames.listen(_collectInputFrame);
    _inputDiagnosticSubscription = _microphone.diagnostics.listen(
      _observeInputDiagnostic,
    );
    _outputDiagnosticSubscription = _speaker.diagnostics.listen(
      _observeOutputDiagnostic,
    );
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _inputDiagnosticSubscription?.cancel();
    _outputDiagnosticSubscription?.cancel();
    _microphone.dispose();
    _speaker.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    try {
      final bool granted = await _microphone.requestPermission();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionGranted = granted;
        _status = granted
            ? 'Permiso concedido. La captura sigue PREPARED hasta el ensayo físico.'
            : 'Se necesita permiso de micrófono para G3.';
      });
    } catch (error) {
      _setFailure('No se pudo solicitar permiso: ${error.runtimeType}.');
    }
  }

  Future<void> _toggleCapture() async {
    if (_capturing) {
      try {
        await _microphone.stop();
        if (!mounted) {
          return;
        }
        setState(() {
          _capturing = false;
          _status = _sample.length > 0
              ? 'Captura detenida. Hay una muestra real local lista para reproducir.'
              : 'Captura detenida sin frames PCM válidos.';
        });
      } catch (error) {
        _setFailure('No se pudo detener la captura: ${error.runtimeType}.');
      }
      return;
    }

    try {
      _sample.clear();
      _inputFrames = 0;
      _inputDrops = 0;
      final AudioSessionDescriptor session = AudioSessionDescriptor(
        sessionId: 'android-host-audio-check',
        streamEpoch: DateTime.now().microsecondsSinceEpoch,
        streamId: 'android-microphone',
      );
      await _microphone.start(session, _format);
      if (!mounted) {
        return;
      }
      setState(() {
        _capturing = true;
        _status = 'Capturando PCM real desde el micrófono Android. No se guarda en disco.';
      });
    } catch (error) {
      _setFailure('No se pudo iniciar la captura: ${error.runtimeType}.');
    }
  }

  Future<void> _playCapturedSample() async {
    if (_sample.length == 0) {
      _setFailure('Primero captura una muestra real de micrófono.');
      return;
    }
    try {
      final Uint8List pcm = _sample.takeBytes();
      final AudioSessionDescriptor session = AudioSessionDescriptor(
        sessionId: 'android-host-audio-check',
        streamEpoch: DateTime.now().microsecondsSinceEpoch,
        streamId: 'android-speaker',
      );
      await _speaker.start(session, _format);
      if (!mounted) {
        return;
      }
      setState(() => _playing = true);
      await _speaker.enqueue(
        AudioFrame(
          schemaVersion: CapabilityManifest.currentSchemaVersion,
          session: session,
          direction: AudioDirection.output,
          sequence: 0,
          codec: AudioCodec.pcmS16le,
          format: _format,
          capturedAtMicros: _clock.elapsedMicroseconds,
          receivedAtMicros: _clock.elapsedMicroseconds,
          durationMicros: (pcm.length ~/ _format.bytesPerFrame) *
              1000000 ~/
              _format.sampleRateHz,
          payload: pcm,
        ),
      );
      await Future<void>.delayed(
        Duration(
          microseconds: (pcm.length ~/ _format.bytesPerFrame) *
              1000000 ~/
              _format.sampleRateHz,
        ),
      );
      await _speaker.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _playing = false;
        _status = 'Reproducción completada. Confirma de forma humana la audibilidad según el procedimiento G4.';
      });
    } catch (error) {
      _setFailure('No se pudo reproducir la muestra: ${error.runtimeType}.');
    }
  }

  void _collectInputFrame(AudioFrame frame) {
    if (!_capturing) {
      return;
    }
    final Uint8List pcm = frame.payload;
    if (_sample.length + pcm.length <= _maxSampleBytes) {
      _sample.add(pcm);
    }
    if (mounted) {
      setState(() => _inputFrames += 1);
    }
  }

  void _observeInputDiagnostic(AudioDiagnostic diagnostic) {
    if (diagnostic.code == AudioDiagnosticCode.inputDropped && mounted) {
      setState(() => _inputDrops += diagnostic.value ?? 1);
    }
  }

  void _observeOutputDiagnostic(AudioDiagnostic diagnostic) {
    if (!mounted) {
      return;
    }
    switch (diagnostic.code) {
      case AudioDiagnosticCode.outputFrameQueued:
        setState(() => _outputWrites += 1);
      case AudioDiagnosticCode.outputUnderrun:
        setState(() => _underruns = diagnostic.value ?? _underruns + 1);
      default:
        break;
    }
  }

  void _setFailure(String message) {
    if (mounted) {
      setState(() => _status = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PersalOne HORIZON — Android audio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'G3/G4: host audio real',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta ruta usa AudioRecord y AudioTrack en Android. Los frames se mantienen '
            'en memoria de forma acotada sólo para la verificación local y no se guardan en disco.',
          ),
          const SizedBox(height: 16),
          _EvidenceCard(
            title: 'Estado de evidencia',
            value: 'PREPARED — se requiere dispositivo Android físico para MEASURED',
          ),
          _EvidenceCard(
            title: 'Halo audio',
            value: 'BLOCKED — pendiente de validación física de las gafas',
          ),
          _EvidenceCard(title: 'Estado', value: _status),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              ElevatedButton(
                onPressed: _permissionGranted ? null : _requestPermission,
                child: const Text('Solicitar micrófono'),
              ),
              ElevatedButton(
                onPressed: _permissionGranted && !_playing ? _toggleCapture : null,
                child: Text(_capturing ? 'Detener captura' : 'Iniciar captura real'),
              ),
              ElevatedButton(
                onPressed: !_capturing && !_playing && _sample.length > 0
                    ? _playCapturedSample
                    : null,
                child: const Text('Reproducir muestra real'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Telemetría local', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Frames de entrada: $_inputFrames'),
          Text('Drops de entrada: $_inputDrops'),
          Text('Escrituras de salida: $_outputWrites'),
          Text('Underruns de salida: $_underruns'),
          const SizedBox(height: 20),
          const Text(
            'Procedimiento G4: captura una frase corta en Android físico, detén la '
            'captura, reproduce la muestra y confirma que fue audible. Registra modelo, '
            'versión Android, ruta de audio, fecha y métricas exportadas. La UI no promueve '
            'la capacidad a MEASURED por sí sola.',
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}
