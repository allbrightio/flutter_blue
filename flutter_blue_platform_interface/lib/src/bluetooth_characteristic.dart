// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:rxdart/rxdart.dart';

import 'bluetooth_descriptor.dart';
import 'flutter_blue_platform.dart';
import 'guid.dart';

abstract class BluetoothCharacteristic {
  final Guid uuid;
  final DeviceIdentifier deviceId;
  final Guid serviceUuid;
  final Guid? secondaryServiceUuid;
  final CharacteristicProperties properties;
  final List<BluetoothDescriptor> descriptors;

  BluetoothCharacteristic(this.uuid, this.deviceId, this.serviceUuid,
      this.secondaryServiceUuid, this.properties, this.descriptors,
      {List<int>? value})
      : _value =
            value != null ? BehaviorSubject.seeded(value) : BehaviorSubject();

  bool get isNotifying {
    try {
      var cccd =
          descriptors.singleWhere((d) => d.uuid == BluetoothDescriptor.cccd);
      return ((cccd.lastValue![0] & 0x01) > 0 ||
          (cccd.lastValue![0] & 0x02) > 0);
    } catch (e) {
      return false;
    }
  }

  BehaviorSubject<List<int>> _value;
  Stream<List<int>?> get value => Rx.merge([
        _value.stream,
        _onValueChangedStream,
      ]);

  List<int>? get lastValue => _value.value;

  Stream<BluetoothCharacteristic> get _onCharacteristicChangedStream;

  Stream<List<int>?> get _onValueChangedStream =>
      _onCharacteristicChangedStream.map((c) => c.lastValue);

  /// Retrieves the value of the characteristic
  Future<List<int>> read();

  /// Writes the value of a characteristic.
  /// [CharacteristicWriteType.withoutResponse]: the write is not
  /// guaranteed and will return immediately with success.
  /// [CharacteristicWriteType.withResponse]: the method will return after the
  /// write operation has either passed or failed.
  Future<Null> write(List<int> value, {bool withoutResponse = false});

  /// Sets notifications or indications for the value of a specified characteristic
  Future<bool> setNotifyValue(bool notify);

  @override
  String toString() {
    return 'BluetoothCharacteristic{uuid: $uuid, deviceId: $deviceId, serviceUuid: $serviceUuid, secondaryServiceUuid: $secondaryServiceUuid, properties: $properties, descriptors: $descriptors, value: ${_value.value}';
  }
}

enum CharacteristicWriteType { withResponse, withoutResponse }

class CharacteristicProperties {
  final bool broadcast;
  final bool read;
  final bool writeWithoutResponse;
  final bool write;
  final bool notify;
  final bool indicate;
  final bool authenticatedSignedWrites;
  final bool extendedProperties;
  final bool notifyEncryptionRequired;
  final bool indicateEncryptionRequired;

  CharacteristicProperties(
      {this.broadcast = false,
      this.read = false,
      this.writeWithoutResponse = false,
      this.write = false,
      this.notify = false,
      this.indicate = false,
      this.authenticatedSignedWrites = false,
      this.extendedProperties = false,
      this.notifyEncryptionRequired = false,
      this.indicateEncryptionRequired = false});

  @override
  String toString() {
    return 'CharacteristicProperties{broadcast: $broadcast, read: $read, writeWithoutResponse: $writeWithoutResponse, write: $write, notify: $notify, indicate: $indicate, authenticatedSignedWrites: $authenticatedSignedWrites, extendedProperties: $extendedProperties, notifyEncryptionRequired: $notifyEncryptionRequired, indicateEncryptionRequired: $indicateEncryptionRequired}';
  }
}
