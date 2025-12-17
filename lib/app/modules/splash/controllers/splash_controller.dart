import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/utils/constants.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    // Check if first time opening app
    bool isFirstTime = _storage.read(AppConstants.keyFirstTime) ?? true;

    if (isFirstTime) {
      // Go to onboarding or setup page
      Get.offAllNamed(Routes.HOME); // Change to onboarding if you have one
      _storage.write(AppConstants.keyFirstTime, false);
    } else {
      // Go to home
      Get.offAllNamed(Routes.HOME);
    }
  }
}
