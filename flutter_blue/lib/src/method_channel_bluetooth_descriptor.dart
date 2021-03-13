// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';
import '../gen/flutterblue.pb.dart' as protos;
import 'method_channel_flutter_blue.dart';

class MethodChannelBluetoothDescriptor extends BluetoothDescriptor {
  BehaviorSubject<List<int>?> _value;
  Stream<List<int>?> get value => _value.stream;

  List<int>? get lastValue => _value.value;

  MethodChannelBluetoothDescriptor.fromProto(protos.BluetoothDescriptor p)
      : _value = BehaviorSubject.seeded(p.value),
        super(
          uuid: Guid(p.uuid),
          deviceId: DeviceIdentifier(p.remoteId),
          serviceUuid: Guid(p.serviceUuid),
          characteristicUuid: Guid(p.characteristicUuid),
        );

  /// Retrieves the value of a specified descriptor
  Future<List<int>> read() async {
    var request = protos.ReadDescriptorRequest.create()
      ..remoteId = deviceId.toString()
      ..descriptorUuid = uuid.toString()
      ..characteristicUuid = characteristicUuid.toString()
      ..serviceUuid = serviceUuid.toString();

    await MethodChannelFlutterBlue.instance.channel
        .invokeMethod('readDescriptor', request.writeToBuffer());

    return MethodChannelFlutterBlue.instance.methodStream
        .where((m) => m.method == "ReadDescriptorResponse")
        .map((m) => m.arguments)
        .map((buffer) => new protos.ReadDescriptorResponse.fromBuffer(buffer))
        .where((p) =>
            (p.request.remoteId == request.remoteId) &&
            (p.request.descriptorUuid == request.descriptorUuid) &&
            (p.request.characteristicUuid == request.characteristicUuid) &&
            (p.request.serviceUuid == request.serviceUuid))
        .map((d) => d.value)
        .first
        .then((d) {
      _value.add(d);
      return d;
    });
  }

  /// Writes the value of a descriptor
  Future<Null> write(List<int> value) async {
    var request = protos.WriteDescriptorRequest.create()
      ..remoteId = deviceId.toString()
      ..descriptorUuid = uuid.toString()
      ..characteristicUuid = characteristicUuid.toString()
      ..serviceUuid = serviceUuid.toString()
      ..value = value;

    await MethodChannelFlutterBlue.instance.channel
        .invokeMethod('writeDescriptor', request.writeToBuffer());

    return MethodChannelFlutterBlue.instance.methodStream
        .where((m) => m.method == "WriteDescriptorResponse")
        .map((m) => m.arguments)
        .map((buffer) => new protos.WriteDescriptorResponse.fromBuffer(buffer))
        .where((p) =>
            (p.request.remoteId == request.remoteId) &&
            (p.request.descriptorUuid == request.descriptorUuid) &&
            (p.request.characteristicUuid == request.characteristicUuid) &&
            (p.request.serviceUuid == request.serviceUuid))
        .first
        .then((w) => w.success)
        .then((success) => (!success)
            ? throw new Exception('Failed to write the descriptor')
            : null)
        .then(((_) => _value.add(value)))
        .then((_) => null);
  }

  void addValue(List<int>? value) {
    _value.add(value);
  }

  @override
  String toString() {
    return 'BluetoothDescriptor{uuid: $uuid, deviceId: $deviceId, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, value: ${_value.value}}';
  }
}
