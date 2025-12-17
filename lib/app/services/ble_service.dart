import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:get/get.dart';

// ============================================
// BLE SERVICE - Mengelola komunikasi dengan ESP32
// ============================================
//
// Peran:
// - Scan BLE devices
// - Connect/Disconnect ke ESP32
// - Read/Write data
// - Subscribe ke notify
//
// UUID Custom (HARUS SAMA dengan ESP32):
// - Service UUID  : 12345678-1234-5678-1234-56789abcdef0
// - RX UUID       : 12345678-1234-5678-1234-56789abcdef1 (Write)
// - TX UUID       : 12345678-1234-5678-1234-56789abcdef2 (Notify)
// ============================================

class BleService extends GetxService {
  // ============================================
  // STATE & OBSERVABLE
  // ============================================
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxList<fbp.BluetoothDevice> foundDevices = <fbp.BluetoothDevice>[].obs;
  final Rx<fbp.BluetoothDevice?> connectedDevice = Rx<fbp.BluetoothDevice?>(
    null,
  );
  final RxList<String> receivedData = <String>[].obs;
  final RxString lastReceivedMessage = ''.obs;

  // ============================================
  // UUID CHARACTERISTIC (CUSTOM)
  // ============================================
  static const String SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0";
  static const String CHARACTERISTIC_RX =
      "12345678-1234-5678-1234-56789abcdef1"; // Write
  static const String CHARACTERISTIC_TX =
      "12345678-1234-5678-1234-56789abcdef2"; // Notify

  // Device name yang dicari
  static const String TARGET_DEVICE_NAME = "HELM-VICTOR";

  // ============================================
  // PRIVATE VARIABLE
  // ============================================
  fbp.BluetoothCharacteristic? _rxCharacteristic;
  fbp.BluetoothCharacteristic? _txCharacteristic;

  Future<BleService> init() async {
    print('[BleService] Initializing...');

    try {
      // Check Bluetooth support (non-blocking)
      final isSupported = await fbp.FlutterBluePlus.isSupported.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          print('[BleService] Bluetooth support check timeout');
          return false;
        },
      );

      if (!isSupported) {
        print('[BleService] Bluetooth not supported on this device');
        return this;
      }

      // Listen ke adapter state (non-blocking)
      fbp.FlutterBluePlus.adapterState.listen((state) {
        print('[BleService] Bluetooth adapter state: $state');
      });

      print('[BleService] Initialized successfully');
    } catch (e) {
      print('[BleService] Initialization error: $e');
      // Continue anyway, BLE optional
    }

    return this;
  }

  // ============================================
  // SCAN UNTUK MENEMUKAN DEVICE
  // ============================================
  Future<void> startScan() async {
    if (isScanning.value) {
      print('[BleService] Already scanning');
      return;
    }

    try {
      foundDevices.clear();
      isScanning.value = true;
      print('[BleService] Starting scan...');

      // Mulai scan
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen hasil scan
      fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          // Cari device dengan nama TARGET_DEVICE_NAME atau memiliki service UUID
          if (result.device.platformName == TARGET_DEVICE_NAME) {
            if (!foundDevices.contains(result.device)) {
              foundDevices.add(result.device);
              print(
                '[BleService] Found target device: ${result.device.platformName}',
              );
            }
          }
        }
      });

      // Tunggu hingga scan selesai
      await Future.delayed(const Duration(seconds: 11));

      isScanning.value = false;
      print(
        '[BleService] Scan completed. Found ${foundDevices.length} device(s)',
      );
    } catch (e) {
      isScanning.value = false;
      print('[BleService] Scan error: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      isScanning.value = false;
      print('[BleService] Scan stopped');
    } catch (e) {
      print('[BleService] Stop scan error: $e');
    }
  }

  // ============================================
  // CONNECT KE DEVICE
  // ============================================
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      print('[BleService] Connecting to ${device.platformName}...');

      // Connect device
      await device.connect();
      connectedDevice.value = device;
      isConnected.value = true;
      print('[BleService] Connected to ${device.platformName}');

      // Discover services
      await _discoverServices(device);

      return true;
    } catch (e) {
      isConnected.value = false;
      print('[BleService] Connection error: $e');
      return false;
    }
  }

  // ============================================
  // DISCOVER SERVICES & CHARACTERISTICS
  // ============================================
  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    try {
      print('[BleService] Discovering services...');

      List<fbp.BluetoothService> services = await device.discoverServices();

      for (fbp.BluetoothService service in services) {
        print('[BleService] Service found: ${service.uuid}');

        // Cek jika ini adalah service kita
        if (service.uuid.toString() == SERVICE_UUID.toLowerCase()) {
          print('[BleService] ✓ Found target service!');

          // Cari characteristics
          for (fbp.BluetoothCharacteristic char in service.characteristics) {
            print('[BleService] Characteristic: ${char.uuid}');

            // RX Characteristic (Write)
            if (char.uuid.toString() == CHARACTERISTIC_RX.toLowerCase()) {
              _rxCharacteristic = char;
              print('[BleService] ✓ Found RX characteristic (Write)');
            }

            // TX Characteristic (Notify)
            if (char.uuid.toString() == CHARACTERISTIC_TX.toLowerCase()) {
              _txCharacteristic = char;
              print('[BleService] ✓ Found TX characteristic (Notify)');

              // Subscribe ke notify
              await _subscribeToNotify(char);
            }
          }
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        print('[BleService] ⚠️ Warning: Not all characteristics found');
      } else {
        print('[BleService] ✓ All characteristics ready!');
      }
    } catch (e) {
      print('[BleService] Discovery error: $e');
    }
  }

  // ============================================
  // SUBSCRIBE KE TX CHARACTERISTIC (NOTIFY)
  // ============================================
  Future<void> _subscribeToNotify(
    fbp.BluetoothCharacteristic characteristic,
  ) async {
    try {
      print('[BleService] Subscribing to notifications...');

      // Set notify
      await characteristic.setNotifyValue(true);

      // Listen ke value changes
      characteristic.lastValueStream.listen((value) {
        String receivedMessage = String.fromCharCodes(value);
        lastReceivedMessage.value = receivedMessage;
        receivedData.add(receivedMessage);
        print('[BleService] 📨 Received: $receivedMessage');
      });

      print('[BleService] ✓ Subscribed to notifications');
    } catch (e) {
      print('[BleService] Subscribe error: $e');
    }
  }

  // ============================================
  // SEND DATA KE RX CHARACTERISTIC (WRITE)
  // ============================================
  Future<bool> sendData(String message) async {
    if (!isConnected.value || _rxCharacteristic == null) {
      print('[BleService] ✗ Not connected or RX characteristic not found');
      return false;
    }

    try {
      print('[BleService] 📤 Sending: $message');

      // Convert string ke bytes
      List<int> bytes = message.codeUnits;

      // Write ke characteristic
      await _rxCharacteristic!.write(bytes, withoutResponse: false);

      print('[BleService] ✓ Data sent successfully');
      return true;
    } catch (e) {
      print('[BleService] Send error: $e');
      return false;
    }
  }

  // ============================================
  // DISCONNECT DARI DEVICE
  // ============================================
  Future<void> disconnect() async {
    try {
      if (connectedDevice.value != null) {
        await connectedDevice.value!.disconnect();
        connectedDevice.value = null;
        isConnected.value = false;
        _rxCharacteristic = null;
        _txCharacteristic = null;
        print('[BleService] Disconnected');
      }
    } catch (e) {
      print('[BleService] Disconnect error: $e');
    }
  }

  // ============================================
  // HELPER - Get status
  // ============================================
  String getStatus() {
    if (!isConnected.value) {
      if (isScanning.value) {
        return 'Scanning...';
      }
      return 'Disconnected';
    }
    return 'Connected: ${connectedDevice.value?.platformName ?? 'Unknown'}';
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
