import 'package:get/get.dart';
import '../controllers/ble_connect_controller.dart';

class BleConnectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BleConnectController>(() => BleConnectController());
  }
}
