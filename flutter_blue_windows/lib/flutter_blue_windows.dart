
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';


class FlutterBlueWindows extends FlutterBluePlatform {
  static const MethodChannel _channel =
      const MethodChannel('flutter_blue_windows');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  @override
  // TODO: implement connectedDevices
  Future<List<BluetoothDevice>> get connectedDevices => throw UnimplementedError();

  @override
  // TODO: implement isAvailable
  Future<bool> get isAvailable => throw UnimplementedError();

  @override
  // TODO: implement isOn
  Future<bool> get isOn => throw UnimplementedError();

  @override
  // TODO: implement isScanning
  Stream<bool> get isScanning => throw UnimplementedError();

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency, List<Guid> withServices = const [], List<Guid> withDevices = const [], Duration? timeout, bool allowDuplicates = false}) {
      // TODO: implement scan
      throw UnimplementedError();
    }
  
    @override
    // TODO: implement scanResults
    Stream<List<ScanResult>> get scanResults => throw UnimplementedError();
  
    @override
    void setLogLevel(LogLevel level) {
      // TODO: implement setLogLevel
    }
  
    @override
    Future startScan({ScanMode scanMode = ScanMode.lowLatency, List<Guid> withServices = const [], List<Guid> withDevices = const [], Duration? timeout, bool allowDuplicates = false}) {
    // TODO: implement startScan
    throw UnimplementedError();
  }

  @override
  // TODO: implement state
  Stream<BluetoothState> get state => throw UnimplementedError();

  @override
  Future stopScan() {
    // TODO: implement stopScan
    throw UnimplementedError();
  }
}
