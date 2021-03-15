import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'linux_bluetooth_service.dart';

class LinuxBluetoothDevice extends BluetoothDevice {
  final BlueZDevice _bluezDevice;
  // ignore: close_sinks
  final _state = BehaviorSubject<BluetoothDeviceState>();

  BehaviorSubject<bool> _isDiscoveringServices = BehaviorSubject.seeded(false);

  BehaviorSubject<List<BluetoothService>> _services =
      BehaviorSubject.seeded([]);

  LinuxBluetoothDevice.fromBluez({required BlueZDevice bluezDevice})
      : _bluezDevice = bluezDevice,
        super(
          id: DeviceIdentifier(bluezDevice.address),
          name: bluezDevice.name,
          type: BluetoothDeviceType.unknown, // TODO
        ) {
    _bluezDevice.propertiesChangedStream.listen((event) {
      _updateState();
    });
    _updateState();
  }

  /// Establishes a connection to the Bluetooth Device.
  Future<void> connect({
    Duration? timeout,
    bool autoConnect = true,
  }) async {
    if (_state.value == BluetoothDeviceState.connected) {
      return;
    }

    Timer? timer;
    if (timeout != null) {
      timer = Timer(timeout, () {
        disconnect();
        throw TimeoutException('Failed to connect in time.', timeout);
      });
    }

    _state.add(BluetoothDeviceState.connecting);

    await _bluezDevice.connect();

    timer?.cancel();

    _updateState();
  }

  Future<void> disconnect() async {
    if (_state.value == BluetoothDeviceState.disconnected) {
      return;
    }
    _state.add(BluetoothDeviceState.disconnecting);
    await _bluezDevice.disconnect();
    _updateState();
  }

  Future<List<BluetoothService>> discoverServices() async {
    final s = _state.value;
    if (s != BluetoothDeviceState.connected) {
      return Future.error(new Exception(
          'Cannot discoverServices while device is not connected. State == $s'));
    }

    _isDiscoveringServices.add(true);

    final list = _bluezDevice.gattServices
        .map((service) => LinuxBluetoothService.fromBluez(
              deviceId: id,
              bluezDevice: _bluezDevice,
              bluezService: service,
            ))
        .toList();

    _services.add(list);
    _isDiscoveringServices.add(false);
    return list;
  }

  @override
  Stream<bool> get isDiscoveringServices => _isDiscoveringServices;

  @override
  // TODO: implement mtu
  Stream<int> get mtu => throw UnimplementedError();

  @override
  Future<void> requestMtu(int desiredMtu) {
    // TODO: implement requestMtu
    throw UnimplementedError();
  }

  @override
  Stream<List<BluetoothService>> get services => _services;

  Stream<BluetoothDeviceState> get state => _state;

  void _updateState() {
    if (_bluezDevice.connected) {
      _state.add(BluetoothDeviceState.connected);
    } else {
      _state.add(BluetoothDeviceState.disconnected);
    }
  }
}
