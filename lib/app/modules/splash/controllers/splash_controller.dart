import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../routes/app_pages.dart';
import '../../../services/bluetooth_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('[SPLASH] onInit called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('[SPLASH] Starting initialization...');

      // Short delay untuk UI render
      await Future.delayed(const Duration(milliseconds: 800));

      // Check dan request permissions
      await _checkPermissions();

      print('[SPLASH] Navigating to HOME');
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      print('[SPLASH] ❌ Error: $e');
      Get.offAllNamed(Routes.HOME);
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Check if permissions already granted
      bool bluetoothScan = await Permission.bluetoothScan.isGranted;
      bool bluetoothConnect = await Permission.bluetoothConnect.isGranted;
      bool location = await Permission.location.isGranted;

      if (bluetoothScan && bluetoothConnect && location) {
        print('[SPLASH] ✅ All permissions already granted');
        return;
      }

      print('[SPLASH] Requesting permissions...');

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('[SPLASH] ⚠️ Some permissions denied');

        // Show dialog after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.defaultDialog(
            title: 'Izin Diperlukan',
            middleText:
                'Aplikasi memerlukan izin Bluetooth dan Lokasi untuk berfungsi dengan baik.\n\nSilakan berikan izin di Pengaturan.',
            textConfirm: 'Buka Pengaturan',
            textCancel: 'Nanti',
            onConfirm: () {
              openAppSettings();
              Get.back();
            },
            onCancel: () => Get.back(),
          );
        });
      } else {
        print('[SPLASH] ✅ All permissions granted');
        // Trigger BluetoothService to update
        try {
          final bluetoothService = Get.find<BluetoothService>();
          await bluetoothService.requestPermissions();
        } catch (e) {
          print('[SPLASH] BluetoothService not found: $e');
        }
      }
    } catch (e) {
      print('[SPLASH] Permission check error: $e');
    }
  }
}
