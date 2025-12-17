import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/helmet_data_model.dart';
import '../../../data/models/sensor_data_model.dart';
import '../../../services/bluetooth_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final BluetoothService _bluetoothService = Get.find();

  // Observables
  final Rx<HelmetDataModel?> helmetData = Rx<HelmetDataModel?>(null);
  final Rx<SensorDataModel?> sensorData = Rx<SensorDataModel?>(null);
  final RxBool isHelmetLocked = false.obs;
  final RxBool isLoading = false.obs;
  final RxDouble temperature = 0.0.obs;
  final RxDouble humidity = 0.0.obs;
  final RxString connectionStatus = 'Terputus'.obs;
  final RxBool isAlarmActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBluetoothPermissions();
    _initializeData();
    _listenToBluetoothConnection();
    _startPeriodicDataFetch();
  }

  Future<void> _checkBluetoothPermissions() async {
    // Delay check sedikit agar UI sudah render
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      bool bluetoothScan = await Permission.bluetoothScan.isGranted;
      bool bluetoothConnect = await Permission.bluetoothConnect.isGranted;
      bool location = await Permission.location.isGranted;

      if (!bluetoothScan || !bluetoothConnect || !location) {
        Get.snackbar(
          'Izin Bluetooth',
          'Beberapa fitur memerlukan izin Bluetooth dan Lokasi',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () {
              Get.back(); // Close snackbar
              _requestPermissions();
            },
            child: const Text(
              'BERIKAN IZIN',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      print('[HomeController] Permission check error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      Get.snackbar(
        'Berhasil',
        'Semua izin telah diberikan',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Refresh bluetooth service
      await _bluetoothService.requestPermissions();
    } else {
      Get.defaultDialog(
        title: 'Izin Ditolak',
        middleText:
            'Aplikasi memerlukan izin Bluetooth dan Lokasi.\n\nBuka Pengaturan untuk memberikan izin.',
        textConfirm: 'Buka Pengaturan',
        textCancel: 'Batal',
        onConfirm: () {
          openAppSettings();
          Get.back();
        },
      );
    }
  }

  void _initializeData() {
    // Listen to connection status
    ever(_bluetoothService.isConnected, (isConnected) {
      connectionStatus.value = isConnected ? 'Terhubung' : 'Terputus';
      if (isConnected) {
        _fetchHelmetStatus();
      }
    });

    // Initial check
    if (_bluetoothService.isConnected.value) {
      connectionStatus.value = 'Terhubung';
      _fetchHelmetStatus();
    }
  }

  void _listenToBluetoothConnection() {
    // Listen to Bluetooth connection changes
    ever(_bluetoothService.isConnected, (isConnected) {
      if (isConnected) {
        Helpers.showSuccess('Terhubung ke helm');
      } else {
        Helpers.showWarning('Terputus dari helm');
      }
    });
  }

  // Start periodic data fetching
  void _startPeriodicDataFetch() {
    // Fetch data every 5 seconds if connected
    ever(_bluetoothService.isConnected, (isConnected) {
      if (isConnected) {
        Future.delayed(const Duration(seconds: 5), () {
          if (_bluetoothService.isConnected.value) {
            _fetchSensorData();
          }
        });
      }
    });
  }

  // Fetch helmet status
  Future<void> _fetchHelmetStatus() async {
    await _bluetoothService.getStatus();
  }

  // Fetch sensor data
  Future<void> _fetchSensorData() async {
    await _bluetoothService.getSensorData();
  }

  // Update sensor data from Bluetooth
  void updateSensorDataFromBluetooth(String data) {
    try {
      SensorDataModel newData = SensorDataModel.fromESP32String(data);
      sensorData.value = newData;
      temperature.value = newData.temperature;
      humidity.value = newData.humidity;

      // Check for crash
      if (newData.accelerometer.isCrash) {
        _handleCrashDetected(newData);
      }

      // Check for abnormal temperature/humidity
      if (!newData.isTemperatureNormal || !newData.isHumidityNormal) {
        _handleAbnormalSensorData(newData);
      }
    } catch (e) {
      print('Error updating sensor data: $e');
    }
  }

  // Handle crash detected
  void _handleCrashDetected(SensorDataModel data) {
    Helpers.showError('KECELAKAAN TERDETEKSI! Mengirim notifikasi darurat...');

    // Create alert
    // Save to Firebase
    // Send emergency notifications
  }

  // Handle abnormal sensor data
  void _handleAbnormalSensorData(SensorDataModel data) {
    if (!data.isTemperatureNormal) {
      Helpers.showWarning('Suhu dalam helm ${data.temperatureStatus}');
    }
    if (!data.isHumidityNormal) {
      Helpers.showWarning('Kelembaban dalam helm ${data.humidityStatus}');
    }
  }

  // Toggle helmet lock
  Future<void> toggleLock() async {
    if (!_bluetoothService.isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    isLoading.value = true;

    bool success;
    if (isHelmetLocked.value) {
      success = await _bluetoothService.unlockHelmet();
    } else {
      success = await _bluetoothService.lockHelmet();
    }

    if (success) {
      isHelmetLocked.value = !isHelmetLocked.value;
      Helpers.showSuccess(
        isHelmetLocked.value ? 'Helm terkunci' : 'Helm terbuka',
      );
    }

    isLoading.value = false;
  }

  // Quick lock
  Future<void> quickLock() async {
    if (!_bluetoothService.isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    if (await _bluetoothService.lockHelmet()) {
      isHelmetLocked.value = true;
      Helpers.showSuccess('Helm terkunci');
    }
  }

  // Quick unlock
  Future<void> quickUnlock() async {
    if (!_bluetoothService.isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    if (await _bluetoothService.unlockHelmet()) {
      isHelmetLocked.value = false;
      Helpers.showSuccess('Helm terbuka');
    }
  }

  // Toggle alarm
  Future<void> toggleAlarm() async {
    if (!_bluetoothService.isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    bool success;
    if (isAlarmActive.value) {
      success = await _bluetoothService.deactivateAlarm();
    } else {
      success = await _bluetoothService.activateAlarm();
    }

    if (success) {
      isAlarmActive.value = !isAlarmActive.value;
      Helpers.showSuccess(
        isAlarmActive.value ? 'Alarm diaktifkan' : 'Alarm dinonaktifkan',
      );
    }
  }

  // Connect to Bluetooth
  Future<void> connectToBluetooth() async {
    Get.toNamed(Routes.HELMET_SECURITY);
  }

  // Navigate to helmet security
  void goToHelmetSecurity() {
    Get.toNamed(Routes.HELMET_SECURITY);
  }

  // Navigate to rider safety
  void goToRiderSafety() {
    Get.toNamed(Routes.RIDER_SAFETY);
  }

  // Navigate to settings
  void goToSettings() {
    Get.toNamed(Routes.SETTINGS);
  }

  // Refresh data
  Future<void> refreshData() async {
    if (_bluetoothService.isConnected.value) {
      await _fetchHelmetStatus();
      await _fetchSensorData();
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
