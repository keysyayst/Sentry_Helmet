import 'package:get/get.dart';
import '../controllers/rider_safety_controller.dart';

class RiderSafetyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RiderSafetyController>(() => RiderSafetyController());
  }
}
