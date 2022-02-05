// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import '../gen/flutterblue.pb.dart' as protos;
import 'method_channel_bluetooth_characteristic.dart';

class MethodChannelBluetoothService {
  static BluetoothService fromProto(protos.BluetoothService p) =>
      BluetoothService(
          uuid: new Guid(p.uuid),
          deviceId: new DeviceIdentifier(p.remoteId),
          isPrimary: p.isPrimary,
          characteristics: p.characteristics
              .map((c) => MethodChannelBluetoothCharacteristic.fromProto(c))
              .toList(),
          includedServices:
              p.includedServices.map((s) => fromProto(s)).toList());
}
