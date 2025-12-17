import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../../services/ble_service.dart';

// ============================================
// BLE CONNECT CONTROLLER
// ============================================
//
// Mengelola logic untuk BLE Connect Page
// - Trigger scan/connect
// - Forward data dari BLE Service ke UI
// - Send test messages
// ============================================

class BleConnectController extends GetxController {
  late BleService _bleService;

  // Observables (dari BLE Service)
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxList<fbp.BluetoothDevice> foundDevices = <fbp.BluetoothDevice>[].obs;
  final Rx<fbp.BluetoothDevice?> connectedDevice = Rx<fbp.BluetoothDevice?>(
    null,
  );
  final RxList<String> receivedData = <String>[].obs;
  final RxString lastReceivedMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('[BleConnectController] Initializing...');

    // Get BLE Service
    _bleService = Get.find<BleService>();

    // Bind observables dari BLE Service ke Controller
    ever(_bleService.isScanning, (value) {
      isScanning.value = value;
    });

    ever(_bleService.isConnected, (value) {
      isConnected.value = value;
    });

    ever(_bleService.foundDevices, (value) {
      foundDevices.value = value;
    });

    ever(_bleService.connectedDevice, (value) {
      connectedDevice.value = value;
    });

    ever(_bleService.receivedData, (value) {
      receivedData.value = value;
    });

    ever(_bleService.lastReceivedMessage, (value) {
      lastReceivedMessage.value = value;
    });

    print('[BleConnectController] Initialized');
  }

  // ============================================
  // START SCAN
  // ============================================
  Future<void> startScan() async {
    print('[BleConnectController] Starting scan...');
    await _bleService.startScan();
  }

  // ============================================
  // STOP SCAN
  // ============================================
  Future<void> stopScan() async {
    print('[BleConnectController] Stopping scan...');
    await _bleService.stopScan();
  }

  // ============================================
  // CONNECT TO DEVICE
  // ============================================
  Future<void> connect(fbp.BluetoothDevice device) async {
    print('[BleConnectController] Connecting to ${device.platformName}...');
    bool success = await _bleService.connectToDevice(device);

    if (success) {
      Get.snackbar(
        'Success',
        'Connected to ${device.platformName}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to connect',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================
  // DISCONNECT
  // ============================================
  Future<void> disconnect() async {
    print('[BleConnectController] Disconnecting...');
    await _bleService.disconnect();
    Get.snackbar('Info', 'Disconnected', snackPosition: SnackPosition.BOTTOM);
  }

  // ============================================
  // SEND MESSAGE
  // ============================================
  Future<void> sendMessage(String message) async {
    print('[BleConnectController] Sending: $message');
    bool success = await _bleService.sendData(message);

    if (!success) {
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================
  // GET STATUS
  // ============================================
  String getStatus() {
    return _bleService.getStatus();
  }

  @override
  void onClose() {
    print('[BleConnectController] Closing...');
    super.onClose();
  }
}
