import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/services/bluetooth_service.dart';  // HelmetBluetoothService
import 'app/services/firebase_service.dart';
import 'app/services/location_service.dart';
import 'app/services/notification_service.dart';

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
  
  // Initialize services as singletons - FIXED: Gunakan HelmetBluetoothService
  await Get.putAsync(() => BluetoothService().init());
  // await Get.putAsync(() => FirebaseService().init());
  await Get.putAsync(() => LocationService().init());
  await Get.putAsync(() => NotificationService().init());
  
  print('Services initialized successfully');
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
