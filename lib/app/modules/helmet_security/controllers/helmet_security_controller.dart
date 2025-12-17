import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../../../services/bluetooth_service.dart';  // HelmetBluetoothService
import '../../../core/utils/helpers.dart';
import '../../../data/models/helmet_data_model.dart';

class HelmetSecurityController extends GetxController {
  final BluetoothService _bluetoothService = Get.find();  // ← GANTI

  // Observables
  final RxList<BluetoothDevice> availableDevices = <BluetoothDevice>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool isHelmetLocked = false.obs;
  final RxBool isAlarmActive = false.obs;
  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  final RxString lockStatus = 'Tidak Diketahui'.obs;
  final RxInt failedAttempts = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    ever(_bluetoothService.devices, (List<BluetoothDevice> devices) {
      availableDevices.value = devices;
    });

    ever(_bluetoothService.isScanning, (bool scanning) {
      isScanning.value = scanning;
    });

    ever(_bluetoothService.isConnected, (bool connected) {
      isConnected.value = connected;
      if (connected) {
        connectedDevice.value = _bluetoothService.connectedDevice.value;
        _getHelmetStatus();
      } else {
        connectedDevice.value = null;
        lockStatus.value = 'Terputus';
      }
    });

    isConnected.value = _bluetoothService.isConnected.value;
    connectedDevice.value = _bluetoothService.connectedDevice.value;
    availableDevices.value = _bluetoothService.devices;
  }

  Future<void> startScan() async {
    await _bluetoothService.startScan();
  }

  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    bool success = await _bluetoothService.connectToDevice(device);
    if (success) {
      await _getHelmetStatus();
    }
  }

  Future<void> disconnect() async {
    bool confirm = await Helpers.showConfirmDialog(
      title: 'Putuskan Koneksi',
      message: 'Apakah Anda yakin ingin memutuskan koneksi dari helm?',
      confirmText: 'Ya, Putuskan',
      cancelText: 'Batal',
    );

    if (confirm) {
      await _bluetoothService.disconnect();
      Helpers.showInfo('Koneksi terputus');
    }
  }

  Future<void> _getHelmetStatus() async {
    await _bluetoothService.getStatus();
  }

  Future<void> lockHelmet() async {
    if (!isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    isLoading.value = true;

    bool success = await _bluetoothService.lockHelmet();
    if (success) {
      isHelmetLocked.value = true;
      lockStatus.value = 'Terkunci';
      Helpers.showSuccess('Helm berhasil dikunci');
    } else {
      Helpers.showError('Gagal mengunci helm');
    }

    isLoading.value = false;
  }

  Future<void> unlockHelmet() async {
    if (!isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    bool confirm = await Helpers.showConfirmDialog(
      title: 'Buka Kunci Helm',
      message: 'Apakah Anda yakin ingin membuka kunci helm?',
      confirmText: 'Ya, Buka',
      cancelText: 'Batal',
    );

    if (!confirm) return;

    isLoading.value = true;

    bool success = await _bluetoothService.unlockHelmet();
    if (success) {
      isHelmetLocked.value = false;
      lockStatus.value = 'Terbuka';
      Helpers.showSuccess('Helm berhasil dibuka');
    } else {
      Helpers.showError('Gagal membuka kunci helm');
    }

    isLoading.value = false;
  }

  Future<void> activateAlarm() async {
    if (!isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    bool success = await _bluetoothService.activateAlarm();
    if (success) {
      isAlarmActive.value = true;
      Helpers.showSuccess('Alarm diaktifkan');
    } else {
      Helpers.showError('Gagal mengaktifkan alarm');
    }
  }

  Future<void> deactivateAlarm() async {
    if (!isConnected.value) {
      Helpers.showError('Helm tidak terhubung');
      return;
    }

    bool success = await _bluetoothService.deactivateAlarm();
    if (success) {
      isAlarmActive.value = false;
      Helpers.showSuccess('Alarm dinonaktifkan');
    } else {
      Helpers.showError('Gagal menonaktifkan alarm');
    }
  }

  Future<void> emergencyUnlock() async {
    bool confirm = await Helpers.showConfirmDialog(
      title: 'Buka Kunci Darurat',
      message: 'Fitur ini akan membuka kunci helm secara paksa. Gunakan hanya dalam keadaan darurat!',
      confirmText: 'Ya, Buka Paksa',
      cancelText: 'Batal',
    );

    if (confirm) {
      await unlockHelmet();
      failedAttempts.value = 0;
    }
  }

  Future<void> simulateRFIDScan() async {
    Helpers.showInfo('Mendekatkan kartu RFID...');
    await Future.delayed(const Duration(seconds: 1));
    
    bool success = DateTime.now().second % 2 == 0;
    
    if (success) {
      await unlockHelmet();
    } else {
      failedAttempts.value++;
      Helpers.showError('Kartu RFID tidak dikenali');
      
      if (failedAttempts.value >= 3) {
        await activateAlarm();
        Helpers.showWarning('Terlalu banyak percobaan gagal! Alarm diaktifkan');
      }
    }
  }

  @override
  void onClose() {
    stopScan();
    super.onClose();
  }
}
