import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_blue_linux/src/linux_bluetooth_device.dart';
import 'dart:async';

export 'package:flutter_blue_platform_interface/src/bluetooth_characteristic.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_descriptor.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_device.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_service.dart';
export 'package:flutter_blue_platform_interface/src/flutter_blue_platform.dart';

class FlutterBlueLinux extends FlutterBluePlatform {
  BlueZClient? _bluezClient;
  BlueZAdapter? _bluezAdapter;

  final _stopScanPill = new PublishSubject();
  final _isScanning = BehaviorSubject.seeded(false);
  final _scanResults = BehaviorSubject<List<ScanResult>>.seeded([]);

  /// Registers this class as the default instance of [FlutterBluePlatform].
  static void registerWith(dynamic registrar) {
    FlutterBluePlatform.instance = FlutterBlueLinux();
  }

  FlutterBlueLinux() {
    _setLogLevelIfAvailable();
  }

  Future<BlueZClient> get _client async {
    if (_bluezClient == null) {
      _bluezClient = BlueZClient();
      await _bluezClient!.connect();
      if (_bluezClient!.adapters.isEmpty) {
        print('No Bluetooth adapters found');
      } else {
        _bluezAdapter = _bluezClient!.adapters.first;
      }
    }
    return _bluezClient!;
  }

  /// Log level of the instance, default is all messages (debug).
  LogLevel _logLevel = LogLevel.debug;
  LogLevel get logLevel => _logLevel;

  @override
  Future<List<BluetoothDevice>> get connectedDevices async => (await _client)
      .devices
      .where((device) => device.connected)
      .map((device) => LinuxBluetoothDevice.fromBluez(bluezDevice: device))
      .toList();

  /// Checks whether the device supports Bluetooth
  @override
  Future<bool> get isAvailable async => _bluezAdapter != null;

  /// Checks if Bluetooth functionality is turned on
  @override
  Future<bool> get isOn async => _bluezAdapter != null;

  @override
  Stream<bool> get isScanning => _isScanning.stream;

  @override
  Stream<ScanResult> scan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) async* {
    final client = await _client;

    if (_isScanning.value == true) {
      throw Exception('Another scan is already in progress.');
    }

    if (_bluezAdapter == null) {
      throw Exception('No Active Adapters');
    }

    // Emit to isScanning
    _isScanning.add(true);

    // Clear scan results list
    _scanResults.add(<ScanResult>[]);

    final results = client.devices
        .map((device) => ScanResult(
            device: LinuxBluetoothDevice.fromBluez(bluezDevice: device),
            advertisementData: AdvertisementData(
              connectable: true,
              localName: "",
              manufacturerData: {},
              serviceData: {},
              serviceUuids: [],
              txPowerLevel: 0,
            ),
            rssi: device.rssi))
        .toList();
    _scanResults.add(results);

    client.deviceAddedStream.listen((device) {
      final list = _scanResults.value!;
      final result = ScanResult(
          device: LinuxBluetoothDevice.fromBluez(bluezDevice: device),
          advertisementData: AdvertisementData(
            connectable: true,
            localName: "",
            manufacturerData: {},
            serviceData: {},
            serviceUuids: [],
            txPowerLevel: 0,
          ),
          rssi: device.rssi);
      int index = list.indexOf(result);
      if (index != -1) {
        list[index] = result;
      } else {
        list.add(result);
      }
      _scanResults.add(list);
    });

    await _bluezAdapter!.startDiscovery();
    await Future.delayed(timeout ?? const Duration(seconds: 5));
    await _bluezAdapter!.stopDiscovery();
    _isScanning.add(false);

    yield* Stream.fromIterable(_scanResults.value!);
  }

  @override
  Stream<List<ScanResult>> get scanResults => _scanResults.stream;

  @override
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  @override
  Future startScan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) async {
    await scan(
            scanMode: scanMode,
            withServices: withServices,
            withDevices: withDevices,
            timeout: timeout ?? const Duration(seconds: 5),
            allowDuplicates: allowDuplicates)
        .drain();
    return _scanResults.value!;
  }

  @override
  Stream<BluetoothState> get state =>
      Stream.value(BluetoothState.on); // TODO get proper state

  @override
  Future stopScan() async {
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  // TODO when ?
  Future<void> dispose() async {
    _bluezClient?.close();
  }

  Future<void> _setLogLevelIfAvailable() async {
    if (await isAvailable) {
      // Send the log level to the underlying platforms.
      setLogLevel(logLevel);
    }
  }
}
