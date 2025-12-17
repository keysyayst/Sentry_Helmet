import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/constants.dart';
import '../core/utils/helpers.dart';
import '../data/models/sensor_data_model.dart';

class BluetoothService extends GetxService {
  // Observables
  final Rx<fbp.BluetoothDevice?> connectedDevice = Rx<fbp.BluetoothDevice?>(null);
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxList<fbp.BluetoothDevice> devices = <fbp.BluetoothDevice>[].obs;
  final Rx<fbp.BluetoothAdapterState> adapterState = fbp.BluetoothAdapterState.unknown.obs;
  
  // Characteristics for communication
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  fbp.BluetoothCharacteristic? _notifyCharacteristic;

  Future<BluetoothService> init() async {
    // Check if Bluetooth is supported
    if (await fbp.FlutterBluePlus.isSupported == false) {
      Helpers.showError('Bluetooth tidak didukung pada perangkat ini');
      return this;
    }

    // Listen to adapter state
    fbp.FlutterBluePlus.adapterState.listen((state) {
      adapterState.value = state;
      if (state == fbp.BluetoothAdapterState.off) {
        Helpers.showWarning('Bluetooth tidak aktif. Silakan aktifkan Bluetooth.');
      }
    });

    // Request Bluetooth permissions
    await requestPermissions();

    return this;
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      Helpers.showError('Izin Bluetooth diperlukan untuk menggunakan fitur ini');
      return false;
    }

    return true;
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await fbp.FlutterBluePlus.adapterState.first == fbp.BluetoothAdapterState.on;
  }

  // Turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    try {
      if (GetPlatform.isAndroid) {
        await fbp.FlutterBluePlus.turnOn();
      }
    } catch (e) {
      Helpers.showError('Tidak dapat mengaktifkan Bluetooth: $e');
    }
  }

  // Start scanning for devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      if (!(await isBluetoothEnabled())) {
        Helpers.showWarning('Bluetooth tidak aktif');
        return;
      }

      isScanning.value = true;
      devices.clear();

      // Start scanning
      await fbp.FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          // Filter only SENTRY HELMET devices
          if (result.device.platformName.isNotEmpty &&
              (result.device.platformName.contains('SENTRY') ||
               result.device.platformName.contains('ESP32'))) {
            
            if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
              devices.add(result.device);
            }
          }
        }
      });

      // Auto stop after timeout
      Future.delayed(timeout, () {
        stopScan();
      });

    } catch (e) {
      Helpers.showError('Gagal memindai perangkat: $e');
      isScanning.value = false;
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning.value = false;
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      isConnecting.value = true;

      // Disconnect if already connected to another device
      if (connectedDevice.value != null) {
        await disconnect();
      }

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 30),
        autoConnect: false,
      );

      connectedDevice.value = device;
      isConnected.value = true;

      Helpers.showSuccess('Terhubung ke ${device.platformName}');

      // Discover services and characteristics
      await _discoverServices(device);

      // Listen to connection state
      device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      return true;

    } catch (e) {
      Helpers.showError('Gagal terhubung ke perangkat: $e');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  // Discover services and characteristics
  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    try {
      List<fbp.BluetoothService> services = await device.discoverServices();

      for (fbp.BluetoothService service in services) {
        // Find write characteristic
        for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          
          // Find notify characteristic
          if (characteristic.properties.notify) {
            _notifyCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            
            // Listen to notifications from ESP32
            characteristic.value.listen((value) {
              _handleNotification(value);
            });
          }
        }
      }

    } catch (e) {
      print('Error discovering services: $e');
    }
  }

  // Handle notifications from ESP32
  void _handleNotification(List<int> value) {
    try {
      String data = String.fromCharCodes(value);
      print('Received from ESP32: $data');
      
      // Parse sensor data
      if (data.contains('TEMP:') || data.contains('HUM:')) {
        // Trigger event untuk update sensor data
        if (Get.isRegistered<SensorDataController>()) {
          Get.find<SensorDataController>().updateFromBluetooth(data);
        }
      }
      
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  // Send command to ESP32
  Future<bool> sendCommand(String command) async {
    if (!isConnected.value || _writeCharacteristic == null) {
      Helpers.showError('Tidak terhubung ke helm');
      return false;
    }

    try {
      List<int> bytes = command.codeUnits;
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print('Sent to ESP32: $command');
      return true;
    } catch (e) {
      Helpers.showError('Gagal mengirim perintah: $e');
      return false;
    }
  }

  // Lock helmet
  Future<bool> lockHelmet() async {
    return await sendCommand(AppConstants.cmdLock);
  }

  // Unlock helmet
  Future<bool> unlockHelmet() async {
    return await sendCommand(AppConstants.cmdUnlock);
  }

  // Get status
  Future<bool> getStatus() async {
    return await sendCommand(AppConstants.cmdGetStatus);
  }

  // Get sensor data
  Future<bool> getSensorData() async {
    return await sendCommand(AppConstants.cmdGetSensor);
  }

  // Activate alarm
  Future<bool> activateAlarm() async {
    return await sendCommand(AppConstants.cmdAlarmOn);
  }

  // Deactivate alarm
  Future<bool> deactivateAlarm() async {
    return await sendCommand(AppConstants.cmdAlarmOff);
  }

  // Handle disconnection
  void _handleDisconnection() {
    connectedDevice.value = null;
    isConnected.value = false;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    Helpers.showWarning('Terputus dari helm');
  }

  // Disconnect from device
  Future<void> disconnect() async {
    if (connectedDevice.value != null) {
      try {
        await connectedDevice.value!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
      _handleDisconnection();
    }
  }

  @override
  void onClose() {
    disconnect();
    stopScan();
    super.onClose();
  }
}

// Dummy controller for example (will be created later)
class SensorDataController extends GetxController {
  void updateFromBluetooth(String data) {
    // Will be implemented in controller section
  }
}
