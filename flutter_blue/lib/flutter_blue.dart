// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:flutter_blue_platform_interface/src/bluetooth_characteristic.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_descriptor.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_device.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_service.dart';
export 'package:flutter_blue_platform_interface/src/flutter_blue_platform.dart';

export 'src/method_channel_flutter_blue.dart';

import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'src/method_channel_flutter_blue.dart';

class FlutterBlue {
  static FlutterBluePlatform get instance => MethodChannelFlutterBlue.instance;
}
