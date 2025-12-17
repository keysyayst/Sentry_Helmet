import 'package:get/get.dart';
import '../controllers/helmet_security_controller.dart';

class HelmetSecurityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelmetSecurityController>(() => HelmetSecurityController());
  }
}
