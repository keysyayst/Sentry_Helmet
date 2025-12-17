import 'package:get/get.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/helmet_security/bindings/helmet_security_binding.dart';
import '../modules/helmet_security/views/helmet_security_view.dart';
import '../modules/rider_safety/bindings/rider_safety_binding.dart';
import '../modules/rider_safety/views/rider_safety_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../routes/app_routes.dart';  

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.HELMET_SECURITY,
      page: () => const HelmetSecurityView(),
      binding: HelmetSecurityBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.RIDER_SAFETY,
      page: () => const RiderSafetyView(),
      binding: RiderSafetyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
