// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'flutter_blue_platform.dart';
import 'guid.dart';

abstract class BluetoothDescriptor {
  static final Guid cccd = Guid("00002902-0000-1000-8000-00805f9b34fb");

  final Guid uuid;
  final DeviceIdentifier deviceId;
  final Guid serviceUuid;
  final Guid characteristicUuid;

  BluetoothDescriptor(
      {required this.uuid,
      required this.deviceId,
      required this.serviceUuid,
      required this.characteristicUuid});

  Stream<List<int>?> get value;

  List<int>? get lastValue;

  /// Retrieves the value of a specified descriptor
  Future<List<int>> read();

  /// Writes the value of a descriptor
  Future<Null> write(List<int> value);
}
