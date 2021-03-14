// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:flutter_blue_platform_interface/src/bluetooth_characteristic.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_descriptor.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_device.dart';
export 'package:flutter_blue_platform_interface/src/bluetooth_service.dart';
export 'package:flutter_blue_platform_interface/src/flutter_blue_platform.dart';

export 'src/method_channel_flutter_blue.dart';

import 'dart:io';

import 'package:flutter_blue_linux/flutter_blue_linux.dart';
import 'package:flutter_blue_windows/flutter_blue_windows.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';

import 'src/method_channel_flutter_blue.dart';

bool _manualDartRegistrationNeeded = true;

class FlutterBlue {
  static FlutterBluePlatform get instance => _platform;

  static FlutterBluePlatform get _platform {
    // This is to manually endorse Dart implementations until automatic
    // registration of Dart plugins is implemented. For details see
    // https://github.com/flutter/flutter/issues/52267.
    // and https://github.com/flutter/plugins/blob/master/packages/path_provider/path_provider/lib/path_provider.dart
    if (_manualDartRegistrationNeeded) {
      // Only do the initial registration if it hasn't already been overridden
      // with a non-default instance.
      if (Platform.isLinux) {
        FlutterBluePlatform.instance = FlutterBlueLinux();
      } else  if (Platform.isWindows) {
        FlutterBluePlatform.instance = FlutterBlueWindows();
      } else {
        FlutterBluePlatform.instance = MethodChannelFlutterBlue.instance;
      }

      _manualDartRegistrationNeeded = false;
    }

    return FlutterBluePlatform.instance;
  }
}
