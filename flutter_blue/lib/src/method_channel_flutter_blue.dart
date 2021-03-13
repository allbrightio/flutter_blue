import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import '../gen/flutterblue.pb.dart' as protos;
import 'constants.dart';
import 'method_channel_bluetooth_device.dart';

class MethodChannelFlutterBlue extends FlutterBluePlatform {
  final MethodChannel channel = const MethodChannel('$NAMESPACE/methods');
  final EventChannel stateChannel = const EventChannel('$NAMESPACE/state');
  final StreamController<MethodCall> methodStreamController =
      new StreamController.broadcast(); // ignore: close_sinks
  Stream<MethodCall> get methodStream => methodStreamController
      .stream; // Used internally to dispatch methods from platform.

  /// Singleton boilerplate
  MethodChannelFlutterBlue._() {
    channel.setMethodCallHandler((MethodCall call) async {
      methodStreamController.add(call);
    });

    _setLogLevelIfAvailable();
  }

  static MethodChannelFlutterBlue _instance = MethodChannelFlutterBlue._();
  static MethodChannelFlutterBlue get instance => _instance;

  /// Log level of the instance, default is all messages (debug).
  LogLevel _logLevel = LogLevel.debug;
  LogLevel get logLevel => _logLevel;

  /// Checks whether the device supports Bluetooth
  Future<bool> get isAvailable =>
      channel.invokeMethod('isAvailable').then<bool>((d) => d);

  /// Checks if Bluetooth functionality is turned on
  Future<bool> get isOn => channel.invokeMethod('isOn').then<bool>((d) => d);

  BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);
  Stream<bool> get isScanning => _isScanning.stream;

  BehaviorSubject<List<ScanResult>> _scanResults = BehaviorSubject.seeded([]);

  /// Returns a stream that is a list of [ScanResult] results while a scan is in progress.
  ///
  /// The list emitted is all the scanned results as of the last initiated scan. When a scan is
  /// first started, an empty list is emitted. The returned stream is never closed.
  ///
  /// One use for [scanResults] is as the stream in a StreamBuilder to display the
  /// results of a scan in real time while the scan is in progress.
  Stream<List<ScanResult>> get scanResults => _scanResults.stream;

  PublishSubject _stopScanPill = PublishSubject();

  /// Gets the current state of the Bluetooth module
  Stream<BluetoothState> get state async* {
    yield await channel
        .invokeMethod('state')
        .then((buffer) => protos.BluetoothState.fromBuffer(buffer))
        .then((s) => BluetoothState.values[s.state.value]);

    yield* stateChannel
        .receiveBroadcastStream()
        .map((buffer) => protos.BluetoothState.fromBuffer(buffer))
        .map((s) => BluetoothState.values[s.state.value]);
  }

  /// Retrieve a list of connected devices
  Future<List<BluetoothDevice>> get connectedDevices {
    return channel
        .invokeMethod('getConnectedDevices')
        .then((buffer) => protos.ConnectedDevicesResponse.fromBuffer(buffer))
        .then((p) => p.devices)
        .then((p) =>
            p.map((d) => MethodChannelBluetoothDevice.fromProto(d)).toList());
  }

  _setLogLevelIfAvailable() async {
    if (await isAvailable) {
      // Send the log level to the underlying platforms.
      setLogLevel(logLevel);
    }
  }

  /// Starts a scan for Bluetooth Low Energy devices and returns a stream
  /// of the [ScanResult] results as they are received.
  ///
  /// timeout calls stopStream after a specified [Duration].
  /// You can also get a list of ongoing results in the [scanResults] stream.
  /// If scanning is already in progress, this will throw an [Exception].
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) async* {
    var settings = protos.ScanSettings.create()
      ..androidScanMode = scanMode.value
      ..allowDuplicates = allowDuplicates
      ..serviceUuids.addAll(withServices.map((g) => g.toString()).toList());

    if (_isScanning.value == true) {
      throw Exception('Another scan is already in progress.');
    }

    // Emit to isScanning
    _isScanning.add(true);

    final killStreams = <Stream>[];
    killStreams.add(_stopScanPill);
    if (timeout != null) {
      killStreams.add(Rx.timer(null, timeout));
    }

    // Clear scan results list
    _scanResults.add(<ScanResult>[]);

    try {
      await channel.invokeMethod('startScan', settings.writeToBuffer());
    } catch (e) {
      print('Error starting scan.');
      _stopScanPill.add(null);
      _isScanning.add(false);
      throw e;
    }

    yield* methodStream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
        .map((buffer) => protos.ScanResult.fromBuffer(buffer))
        .map((p) {
      final result = MethodChannelScanResult.fromProto(p);
      final list = _scanResults.value!;
      int index = list.indexOf(result);
      if (index != -1) {
        list[index] = result;
      } else {
        list.add(result);
      }
      _scanResults.add(list);
      return result;
    });
  }

  /// Starts a scan and returns a future that will complete once the scan has finished.
  ///
  /// Once a scan is started, call [stopScan] to stop the scan and complete the returned future.
  ///
  /// timeout automatically stops the scan after a specified [Duration].
  ///
  /// To observe the results while the scan is in progress, listen to the [scanResults] stream,
  /// or call [scan] instead.
  Future startScan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) async {
    await scan(
            scanMode: scanMode,
            withServices: withServices,
            withDevices: withDevices,
            timeout: timeout,
            allowDuplicates: allowDuplicates)
        .drain();
    return _scanResults.value;
  }

  /// Stops a scan for Bluetooth Low Energy devices
  Future stopScan() async {
    await channel.invokeMethod('stopScan');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  /// The list of connected peripherals can include those that are connected
  /// by other apps and that will need to be connected locally using the
  /// device.connect() method before they can be used.
//  Stream<List<BluetoothDevice>> connectedDevices({
//    List<Guid> withServices = const [],
//  }) =>
//      throw UnimplementedError();

  /// Sets the log level of the FlutterBlue instance
  /// Messages equal or below the log level specified are stored/forwarded,
  /// messages above are dropped.
  void setLogLevel(LogLevel level) async {
    await channel.invokeMethod('setLogLevel', level.index);
    _logLevel = level;
  }

  void log(LogLevel level, String message) {
    if (level.index <= _logLevel.index) {
      print(message);
    }
  }
}

class MethodChannelScanResult {
  static ScanResult fromProto(protos.ScanResult p) => ScanResult(
      device: MethodChannelBluetoothDevice.fromProto(p.device),
      advertisementData:
          MethodChannelAdvertisementData.fromProto(p.advertisementData),
      rssi: p.rssi);
}

class MethodChannelAdvertisementData {
  static AdvertisementData fromProto(protos.AdvertisementData p) =>
      AdvertisementData(
          localName: p.localName,
          txPowerLevel:
              (p.txPowerLevel.hasValue()) ? p.txPowerLevel.value : null,
          connectable: p.connectable,
          manufacturerData: p.manufacturerData,
          serviceData: p.serviceData,
          serviceUuids: p.serviceUuids);
}
