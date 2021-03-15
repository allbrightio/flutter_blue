import 'package:bluez/bluez.dart';
import 'package:flutter_blue_platform_interface/flutter_blue_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

class LinuxBluetoothCharacteristic extends BluetoothCharacteristic {
  final BlueZGattCharacteristic _blueZCharacteristic;

  LinuxBluetoothCharacteristic.fromBluez({
    required BlueZGattCharacteristic blueZCharacteristic,
    required DeviceIdentifier deviceId,
    required Guid serviceUuid,
  })   : this._blueZCharacteristic = blueZCharacteristic,
        super(
          uuid: Guid(blueZCharacteristic.uuid.id),
          serviceUuid: serviceUuid,
          deviceId: deviceId,
          properties: CharacteristicProperties(),
          descriptors: [],
          secondaryServiceUuid: null,
        ) {
    _blueZCharacteristic.propertiesChangedStream.listen((properties) {
      if (properties.any((property) => property == "Value")) {
        final value = _blueZCharacteristic.value;
        _value.add(value);
      }
    });
  }

  List<int> get lastValue => _value.value ?? [];

  final _value = BehaviorSubject<List<int>>();
  Stream<List<int>> get value => _value;

  bool get canNotifyValue =>
      _blueZCharacteristic.flags.contains(BlueZGattCharacteristicFlag.notify);

  @override
  Future<bool> setNotifyValue(bool notify) async {
    if (canNotifyValue) {
      if (notify) {
        await _blueZCharacteristic.startNotify();
      } else {
        await _blueZCharacteristic.stopNotify();
      }
      return true;
    }
    return false;
  }

  @override
  Future<List<int>> read() async {
    final value = await _blueZCharacteristic.readValue();
    return value.toList();
  }

  @override
  Future<Null> write(List<int> value, {bool withoutResponse = false}) async {
    await _blueZCharacteristic.writeValue(value);
  }
}
