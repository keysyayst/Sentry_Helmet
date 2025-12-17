import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/services/bluetooth_service.dart';
import 'app/services/location_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // Uncomment when firebase is configured
  // await Firebase.initializeApp();

  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  print('Starting services initialization...');

  try {
    // Initialize services with shorter timeout and parallel execution
    print('Initializing all services...');

    await Future.wait([
      // BluetoothService
      Get.putAsync(() => BluetoothService().init())
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('⚠️ BluetoothService timeout, continuing...');
              return BluetoothService();
            },
          )
          .catchError((e) {
            print('⚠️ BluetoothService error: $e');
            return BluetoothService();
          }),

      // LocationService
      Get.putAsync(() => LocationService().init())
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('⚠️ LocationService timeout, continuing...');
              return LocationService();
            },
          )
          .catchError((e) {
            print('⚠️ LocationService error: $e');
            return LocationService();
          }),

      // NotificationService
      Get.putAsync(() => NotificationService().init())
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('⚠️ NotificationService timeout, continuing...');
              return NotificationService();
            },
          )
          .catchError((e) {
            print('⚠️ NotificationService error: $e');
            return NotificationService();
          }),

      // BleService
      Get.putAsync(() => BleService().init())
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('⚠️ BleService timeout, continuing...');
              return BleService();
            },
          )
          .catchError((e) {
            print('⚠️ BleService error: $e');
            return BleService();
          }),
    ], eagerError: false); // Continue even if some fail

    print('✅ Services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    // Continue anyway
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sentry Helmet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
    );
  }
}
