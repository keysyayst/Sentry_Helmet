import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    print('[SPLASH BINDING] dependencies() called');
    Get.put<SplashController>(SplashController());
    print(
      '[SPLASH BINDING] SplashController created: ${Get.isRegistered<SplashController>()}',
    );
  }
}
