import 'dart:typed_data';

import 'capability.dart';
import 'truth_label.dart';

/// Lifecycle states observable by a device adapter.
enum DeviceConnectionState {
  idle,
  discovering,
  connecting,
  ready,
  disconnecting,
  disconnected,
  failed,
}

/// A device surfaced by discovery. [deviceId] must be a platform-scoped,
/// redacted identifier suitable only for local reconnection lookup.
final class DeviceDiscovery {
  const DeviceDiscovery({
    required this.deviceId,
    required this.displayName,
    required this.truthLabel,
    required this.discoveredAtMicros,
    this.rssi,
  });

  final String deviceId;
  final String displayName;
  final TruthLabel truthLabel;
  final int discoveredAtMicros;
  final int? rssi;
}

/// Device metadata returned through an allow-listed, read-only query.
///
/// An EUI or platform identifier must be transformed to [redactedId] before it
/// enters this contract, diagnostics, persistence, or the user interface.
final class DeviceIdentity {
  const DeviceIdentity({
    required this.redactedId,
    required this.hardwareVersion,
    required this.firmwareVersion,
    required this.sourceRevision,
    required this.truthLabel,
  });

  final String redactedId;
  final String hardwareVersion;
  final String firmwareVersion;
  final String sourceRevision;
  final TruthLabel truthLabel;
}

/// Battery data collected from a standard GATT service or a read-only,
/// allow-listed device query.
final class BatterySnapshot {
  const BatterySnapshot({
    required this.levelPercent,
    required this.observedAtMicros,
    required this.sourceRevision,
    required this.truthLabel,
    this.isCharging,
    this.voltageMillivolts,
  });

  final int levelPercent;
  final bool? isCharging;
  final int? voltageMillivolts;
  final int observedAtMicros;
  final String sourceRevision;
  final TruthLabel truthLabel;
}

/// Coded diagnostics that contain no audio, transcript, raw identifier, Lua,
/// or USERDATA payload.
enum AdapterDiagnosticCode {
  scanStarted,
  scanResult,
  scanFailed,
  connectStarted,
  servicesReady,
  disconnectObserved,
  reconnectScheduled,
  reconnectFailed,
  pairingRequired,
  mtuUpdated,
  capabilityBlocked,
  protocolRejected,
}

/// Structured, redacted diagnostic event emitted by a device adapter.
final class AdapterDiagnostic {
  const AdapterDiagnostic({
    required this.code,
    required this.observedAtMicros,
    required this.adapterId,
    this.detail,
  });

  final AdapterDiagnosticCode code;
  final int observedAtMicros;
  final String adapterId;
  final String? detail;
}

/// Stable snapshot of one adapter session.
final class DeviceAdapterSnapshot {
  const DeviceAdapterSnapshot({
    required this.state,
    required this.adapterId,
    required this.sourceRevision,
    required this.truthLabel,
    required this.observedAtMicros,
    this.selectedDevice,
    this.failureReason,
  });

  final DeviceConnectionState state;
  final String adapterId;
  final String sourceRevision;
  final TruthLabel truthLabel;
  final int observedAtMicros;
  final DeviceDiscovery? selectedDevice;
  final String? failureReason;
}

/// Query identifiers that are safe to translate into an implementation-owned
/// Lua allow-list. Arbitrary Lua text is intentionally absent.
enum HaloLuaQuery {
  identity,
  battery,
  clearDisplay,
  displayText,
}

/// Typed result returned by an allow-listed Lua query.
final class HaloLuaResult {
  const HaloLuaResult({
    required this.query,
    required this.value,
    required this.sourceRevision,
    required this.truthLabel,
  });

  final HaloLuaQuery query;
  final String value;
  final String sourceRevision;
  final TruthLabel truthLabel;
}

/// Versioned USERDATA message. Its binary content stays out of diagnostics and
/// logs; users of this contract own framing semantics above BLE fragmentation.
final class UserDataMessage {
  UserDataMessage({
    required this.schemaVersion,
    required this.type,
    required Uint8List payload,
  }) : _payload = Uint8List.fromList(payload);

  final String schemaVersion;
  final int type;
  final Uint8List _payload;

  Uint8List get payload => Uint8List.fromList(_payload);
}

/// Product-level port for a physical or deterministic device implementation.
abstract interface class DeviceAdapterPort {
  String get adapterId;
  String get sourceRevision;
  Stream<DeviceAdapterSnapshot> get snapshots;
  Stream<AdapterDiagnostic> get diagnostics;

  Future<void> startDiscovery();
  Stream<DeviceDiscovery> get discoveries;
  Future<void> stopDiscovery();
  Future<void> connect(DeviceDiscovery device);
  Future<void> reconnect();
  Future<void> disconnect();
  Future<CapabilityManifest> capabilityManifest();
  Future<DeviceIdentity> readIdentity();
  Future<BatterySnapshot> readBattery();
  Future<HaloLuaResult> executeAllowedLua(
    HaloLuaQuery query, {
    String? text,
  });
  Future<void> sendUserData(UserDataMessage message);
  Future<void> dispose();
}
