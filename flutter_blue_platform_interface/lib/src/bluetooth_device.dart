// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'bluetooth_service.dart';
import 'flutter_blue_platform.dart';

abstract class BluetoothDevice {
  final DeviceIdentifier id;
  final String name;
  final BluetoothDeviceType type;

  BluetoothDevice({required this.id, required this.name, required this.type});

  Stream<bool> get isDiscoveringServices;

  /// Establishes a connection to the Bluetooth Device.
  Future<void> connect({
    Duration? timeout,
    bool autoConnect = true,
  });

  /// Cancels connection to the Bluetooth Device
  Future disconnect();

  /// Discovers services offered by the remote device as well as their characteristics and descriptors
  Future<List<BluetoothService>> discoverServices();

  /// Returns a list of Bluetooth GATT services offered by the remote device
  /// This function requires that discoverServices has been completed for this device
  Stream<List<BluetoothService>> get services;

  /// The current connection state of the device
  Stream<BluetoothDeviceState> get state;

  /// The MTU size in bytes
  Stream<int> get mtu;

  /// Request to change the MTU Size
  /// Throws error if request did not complete successfully
  Future<void> requestMtu(int desiredMtu);

  /// Indicates whether the Bluetooth Device can send a write without response
  Future<bool> get canSendWriteWithoutResponse =>
      new Future.error(new UnimplementedError());
}

enum BluetoothDeviceType { unknown, classic, le, dual }

enum BluetoothDeviceState { disconnected, connecting, connected, disconnecting }
