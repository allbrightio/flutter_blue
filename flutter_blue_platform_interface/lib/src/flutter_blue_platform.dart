import 'package:collection/collection.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_device.dart';

abstract class FlutterBluePlatform extends PlatformInterface {
  FlutterBluePlatform() : super(token: _token);

  static final Object _token = Object();

  static late FlutterBluePlatform _instance;

  /// The default instance of [FlutterBluePlatform] to use.
  static FlutterBluePlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [FlutterBluePlatform] when they register themselves.
  static set instance(FlutterBluePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}

/// Log levels for FlutterBlue
enum LogLevel {
  emergency,
  alert,
  critical,
  error,
  warning,
  notice,
  info,
  debug,
}

/// State of the bluetooth adapter.
enum BluetoothState {
  unknown,
  unavailable,
  unauthorized,
  turningOn,
  on,
  turningOff,
  off
}

class ScanMode {
  const ScanMode(this.value);
  static const lowPower = const ScanMode(0);
  static const balanced = const ScanMode(1);
  static const lowLatency = const ScanMode(2);
  static const opportunistic = const ScanMode(-1);
  final int value;
}

class DeviceIdentifier {
  final String id;
  const DeviceIdentifier(this.id);

  @override
  String toString() => id;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) =>
      other is DeviceIdentifier && compareAsciiLowerCase(id, other.id) == 0;
}

class ScanResult {
  const ScanResult({this.device, this.advertisementData, this.rssi});

  final BluetoothDevice? device;
  final AdvertisementData? advertisementData;
  final int? rssi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          device == other.device;

  @override
  int get hashCode => device.hashCode;

  @override
  String toString() {
    return 'ScanResult{device: $device, advertisementData: $advertisementData, rssi: $rssi}';
  }
}

class AdvertisementData {
  final String? localName;
  final int? txPowerLevel;
  final bool? connectable;
  final Map<int, List<int>>? manufacturerData;
  final Map<String, List<int>>? serviceData;
  final List<String>? serviceUuids;

  AdvertisementData(
      {this.localName,
      this.txPowerLevel,
      this.connectable,
      this.manufacturerData,
      this.serviceData,
      this.serviceUuids});

  @override
  String toString() {
    return 'AdvertisementData{localName: $localName, txPowerLevel: $txPowerLevel, connectable: $connectable, manufacturerData: $manufacturerData, serviceData: $serviceData, serviceUuids: $serviceUuids}';
  }
}
