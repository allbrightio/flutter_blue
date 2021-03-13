import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_blue_linux/src/linux_bluetooth_device.dart';

class FlutterBlueLinux extends FlutterBluePlatform {
  static FlutterBlueLinux _instance = new FlutterBlueLinux._();
  static FlutterBlueLinux get instance => _instance;

  late BlueZClient _bluezClient;
  BlueZAdapter? _bluezAdapter;

  final _stopScanPill = new PublishSubject();

  FlutterBlueLinux._() {
    _setLogLevelIfAvailable();
    _bluezClient = BlueZClient();
  }

  Future<void> init() async {
    await _bluezClient.connect();
    if (_bluezClient.adapters.isEmpty) {
      print('No Bluetooth adapters found');
    } else {
      _bluezAdapter = _bluezClient.adapters.first;
    }
  }

  Future<void> dispose() async {
    _bluezClient.close();
  }

  /// Log level of the instance, default is all messages (debug).
  LogLevel _logLevel = LogLevel.debug;
  LogLevel get logLevel => _logLevel;

  @override
  Future<List<BluetoothDevice>> get connectedDevices async =>
      _bluezClient.devices
          .where((device) => device.connected)
          .map((device) => LinuxBluetoothDevice.fromBluez(bluezDevice: device))
          .toList();

  /// Checks whether the device supports Bluetooth
  Future<bool> get isAvailable async => _bluezAdapter != null;

  /// Checks if Bluetooth functionality is turned on
  Future<bool> get isOn async => _bluezAdapter != null;

  BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);
  @override
  Stream<bool> get isScanning => _isScanning.stream;

  @override
  Stream<ScanResult> scan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) async* {
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

    final results = _bluezClient.devices
        .map((device) => ScanResult(
            device: LinuxBluetoothDevice.fromBluez(bluezDevice: device),
            advertisementData: null,
            rssi: device.rssi))
        .toList();
    _scanResults.add(results);

    _bluezClient.deviceAddedStream.listen((device) {
      final list = _scanResults.value!;
      final result = ScanResult(
          device: LinuxBluetoothDevice.fromBluez(bluezDevice: device),
          advertisementData: null,
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

  BehaviorSubject<List<ScanResult>> _scanResults = BehaviorSubject.seeded([]);

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

  _setLogLevelIfAvailable() async {
    if (await isAvailable) {
      // Send the log level to the underlying platforms.
      setLogLevel(logLevel);
    }
  }
}
