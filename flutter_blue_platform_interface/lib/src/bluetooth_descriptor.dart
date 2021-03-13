// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:rxdart/rxdart.dart';

import 'flutter_blue_platform.dart';
import 'guid.dart';

abstract class BluetoothDescriptor {
  static final Guid cccd = new Guid("00002902-0000-1000-8000-00805f9b34fb");

  final Guid uuid;
  final DeviceIdentifier deviceId;
  final Guid serviceUuid;
  final Guid characteristicUuid;

  BehaviorSubject<List<int>?> _value;

  BluetoothDescriptor(
      this.uuid, this.deviceId, this.serviceUuid, this.characteristicUuid,
      {List<int>? value})
      : _value =
            value != null ? BehaviorSubject.seeded(value) : BehaviorSubject();

  Stream<List<int>?> get value => _value.stream;

  List<int>? get lastValue => _value.value;

  /// Retrieves the value of a specified descriptor
  Future<List<int>> read();

  /// Writes the value of a descriptor
  Future<Null> write(List<int> value);

  @override
  String toString() {
    return 'BluetoothDescriptor{uuid: $uuid, deviceId: $deviceId, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, value: ${_value.value}}';
  }
}
