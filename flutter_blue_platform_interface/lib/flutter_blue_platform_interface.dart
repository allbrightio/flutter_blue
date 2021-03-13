import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlutterBluePlatform extends PlatformInterface {
  FlutterBluePlatform() : super(token: _token);

  static final Object _token = Object();
}
