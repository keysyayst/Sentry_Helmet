import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../controllers/ble_connect_controller.dart';

// ============================================
// BLE CONNECT PAGE - UI untuk koneksi BLE
// ============================================
//
// Fitur:
// - Button Scan Device
// - List device yang ditemukan
// - Connect/Disconnect button
// - Send test messages (PING, STATUS, etc)
// - Log data yang diterima
// ============================================

class BleConnectPage extends GetView<BleConnectController> {
  const BleConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Connection'), elevation: 0),
      body: Column(
        children: [
          // ============================================
          // STATUS CARD
          // ============================================
          Obx(() {
            return Card(
              margin: const EdgeInsets.all(16),
              color: controller.isConnected.value
                  ? Colors.green[100]
                  : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${controller.getStatus()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      return Text(
                        'Last Message: ${controller.lastReceivedMessage.value.isEmpty ? 'None' : controller.lastReceivedMessage.value}',
                        style: const TextStyle(fontSize: 14),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),

          // ============================================
          // BUTTON SECTION
          // ============================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Scan Button
                Expanded(
                  child: Obx(() {
                    return ElevatedButton.icon(
                      onPressed: controller.isScanning.value
                          ? null
                          : controller.startScan,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                    );
                  }),
                ),
                const SizedBox(width: 8),

                // Connect/Disconnect Button
                Expanded(
                  child: Obx(() {
                    if (!controller.isConnected.value) {
                      return ElevatedButton.icon(
                        onPressed: controller.foundDevices.isEmpty
                            ? null
                            : () => controller.connect(
                                controller.foundDevices.first,
                              ),
                        icon: const Icon(Icons.bluetooth),
                        label: const Text('Connect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: controller.disconnect,
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============================================
          // DEVICE LIST
          // ============================================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Found Devices:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          Obx(() {
            if (controller.foundDevices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No devices found. Tap Scan to search.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Expanded(
              child: ListView.builder(
                itemCount: controller.foundDevices.length,
                itemBuilder: (context, index) {
                  final fbp.BluetoothDevice device =
                      controller.foundDevices[index];
                  return ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(device.platformName),
                    trailing: Obx(() {
                      if (controller.isConnected.value &&
                          controller.connectedDevice.value == device) {
                        return const Chip(
                          label: Text('Connected'),
                          backgroundColor: Colors.green,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    onTap: () => controller.connect(device),
                  );
                },
              ),
            );
          }),

          const SizedBox(height: 8),

          // ============================================
          // TEST COMMANDS
          // ============================================
          Obx(() {
            if (!controller.isConnected.value) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.sendMessage('PING'),
                      icon: const Icon(Icons.send),
                      label: const Text('PING'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.sendMessage('STATUS'),
                      icon: const Icon(Icons.info),
                      label: const Text('STATUS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ============================================
          // LOG SECTION
          // ============================================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Received Data:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          Obx(() {
            return Expanded(
              child: ListView.builder(
                itemCount: controller.receivedData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        controller.receivedData[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
