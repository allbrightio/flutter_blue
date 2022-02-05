import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';

import 'linux_bluetooth_characteristic.dart';

class LinuxBluetoothService extends BluetoothService {
  // ignore: unused_field
  final BlueZDevice? _bluezDevice;
  // ignore: unused_field
  final BlueZGattService _blueZService;

  LinuxBluetoothService.fromBluez({
    required BlueZDevice bluezDevice,
    required BlueZGattService bluezService,
    required DeviceIdentifier deviceId,
  })   : this._bluezDevice = bluezDevice,
        this._blueZService = bluezService,
        super(
          uuid: Guid(bluezService.uuid.id),
          deviceId: deviceId,
          characteristics: bluezService.gattCharacteristics
              .map((characteristic) => LinuxBluetoothCharacteristic.fromBluez(
                    deviceId: deviceId,
                    serviceUuid: Guid(bluezService.uuid.id),
                    blueZCharacteristic: characteristic,
                  ))
              .toList(),
          isPrimary: bluezService.primary,
          includedServices: [], // TODO add included services
        );

  @override
  String toString() {
    return 'BluetoothService{uuid: $uuid, deviceId: $deviceId, isPrimary: $isPrimary, characteristics: $characteristics}';
  }
}
