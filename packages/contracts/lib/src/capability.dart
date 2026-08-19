import 'truth_label.dart';

/// Stable identifiers for capabilities that must be declared by a device or
/// fixture before the runtime can attempt to use them.
enum Capability {
  display,
  microphoneCapture,
  speakerPlayback,
  echoCancellation,
  voiceMode,
  batteryStatus,
}

/// Verifiable declaration of one capability for a concrete device and
/// firmware/adapter revision.
final class CapabilityState {
  const CapabilityState({
    required this.capability,
    required this.truthLabel,
    required this.sourceRevision,
    this.reason,
  });

  final Capability capability;
  final TruthLabel truthLabel;
  final String sourceRevision;
  final String? reason;

  bool get isUsable => truthLabel == TruthLabel.measured;
}

/// Capability declaration exchanged between a device adapter and the runtime.
final class CapabilityManifest {
  const CapabilityManifest({
    required this.schemaVersion,
    required this.adapterId,
    required this.states,
  });

  static const String currentSchemaVersion = 'persalone.contracts/1';

  final String schemaVersion;
  final String adapterId;
  final Map<Capability, CapabilityState> states;

  CapabilityState stateFor(Capability capability) {
    return states[capability] ??
        CapabilityState(
          capability: capability,
          truthLabel: TruthLabel.blocked,
          sourceRevision: adapterId,
          reason: 'Capability is not declared by this adapter.',
        );
  }
}
