import 'package:flutter/material.dart';
import 'package:persalone_contracts/persalone_contracts.dart';

void main() {
  runApp(const PersalOneApp());
}

/// Minimal mobile shell for G0/G1 validation.
///
/// This application deliberately has no Bluetooth, microphone, audio,
/// provider, agent, or OTA integration.
class PersalOneApp extends StatelessWidget {
  const PersalOneApp({super.key});

  static const CapabilityManifest capabilityManifest = CapabilityManifest(
    schemaVersion: CapabilityManifest.currentSchemaVersion,
    adapterId: 'g1-shell',
    states: <Capability, CapabilityState>{
      Capability.display: CapabilityState(
        capability: Capability.display,
        truthLabel: TruthLabel.prepared,
        sourceRevision: 'g1-shell',
        reason: 'No physical adapter is integrated in G1.',
      ),
    },
  );

  @override
  Widget build(BuildContext context) {
    final CapabilityState display = capabilityManifest.stateFor(
      Capability.display,
    );

    return MaterialApp(
      title: 'PersalOne Halo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('PersalOne Halo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'G1 foundation',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Display capability: ${display.truthLabel.name}'),
                const SizedBox(height: 8),
                const Text(
                  'No physical Halo, Bluetooth, audio, provider, agent, or OTA '
                  'capability is enabled in this build.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
