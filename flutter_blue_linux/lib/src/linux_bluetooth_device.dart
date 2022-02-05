import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'linux_bluetooth_service.dart';

class LinuxBluetoothDevice extends BluetoothDevice {
  final BlueZDevice _bluezDevice;
  // ignore: close_sinks
  final _state = BehaviorSubject<BluetoothDeviceState>();

  final _isDiscoveringServices = BehaviorSubject<bool>.seeded(false);

  // ignore: close_sinks
  final _mtu = BehaviorSubject<int>.seeded(0);

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
      _updateConnectionState();
    });
    _updateConnectionState();
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
    _updateConnectionState();
  }

  Future<void> disconnect() async {
    if (_state.value == BluetoothDeviceState.disconnected) {
      return;
    }
    _state.add(BluetoothDeviceState.disconnecting);
    await _bluezDevice.disconnect();
    _updateConnectionState();
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
  Stream<int> get mtu => _mtu;

  @override
  Future<void> requestMtu(int desiredMtu) async {
    // Not implemened
    // TODO add "mtu" parameter when calling bluez read/write/acquire methods.
    _mtu.add(desiredMtu);
  }

  @override
  Stream<List<BluetoothService>> get services => _services;

  Stream<BluetoothDeviceState> get state => _state;

  void _updateConnectionState() {
    if (_bluezDevice.connected) {
      _state.add(BluetoothDeviceState.connected);
    } else {
      _state.add(BluetoothDeviceState.disconnected);
    }
  }
}
