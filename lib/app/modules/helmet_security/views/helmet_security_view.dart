import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/helmet_security_controller.dart';
import '../../../core/theme/app_colors.dart';

class HelmetSecurityView extends GetView<HelmetSecurityController> {
  const HelmetSecurityView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan Helm'),
        actions: [
          Obx(() => controller.isConnected.value
              ? IconButton(
                  icon: const Icon(Icons.bluetooth_connected),
                  onPressed: controller.disconnect,
                )
              : IconButton(
                  icon: const Icon(Icons.bluetooth_disabled),
                  onPressed: () {},
                )),
        ],
      ),
      body: Obx(() {
        if (!controller.isConnected.value) {
          return _buildConnectionView();
        }
        return _buildSecurityControlView();
      }),
    );
  }

  // Connection View
  Widget _buildConnectionView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.primary.withOpacity(0.1),
          child: Column(
            children: [
              const Icon(
                Icons.bluetooth_searching,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hubungkan ke Helm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih perangkat helm Anda untuk melanjutkan',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        // Scan Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isScanning.value
                ? null
                : controller.startScan,
            icon: controller.isScanning.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(
              controller.isScanning.value ? 'Memindai...' : 'Pindai Perangkat',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )),
        ),
        
        // Devices List
        Expanded(
          child: Obx(() {
            if (controller.isScanning.value && controller.availableDevices.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mencari perangkat...'),
                  ],
                ),
              );
            }
            
            if (controller.availableDevices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada perangkat ditemukan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan Bluetooth aktif dan helm Anda menyala',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.availableDevices.length,
              itemBuilder: (context, index) {
                final device = controller.availableDevices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.sports_motorsports,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    title: Text(
                      device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => controller.connectToDevice(device),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // Security Control View
  Widget _buildSecurityControlView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connected Device Info
          _buildConnectedDeviceCard(),
          const SizedBox(height: 16),
          
          // Lock Status Card
          _buildLockStatusCard(),
          const SizedBox(height: 16),
          
          // Lock Controls
          Text(
            'Kontrol Kunci',
            style: Get.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.lockHelmet,
                  icon: const Icon(Icons.lock),
                  label: const Text('Kunci'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.unlockHelmet,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Buka'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Alarm Control
          Text(
            'Alarm Keamanan',
            style: Get.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          _buildAlarmCard(),
          const SizedBox(height: 24),
          
          // Additional Features
          Text(
            'Fitur Tambahan',
            style: Get.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          _buildFeatureButton(
            title: 'Scan RFID',
            subtitle: 'Buka kunci menggunakan kartu RFID',
            icon: Icons.credit_card,
            onTap: controller.simulateRFIDScan,
          ),
          const SizedBox(height: 12),
          
          _buildFeatureButton(
            title: 'Buka Kunci Darurat',
            subtitle: 'Buka kunci secara paksa (keadaan darurat)',
            icon: Icons.emergency,
            color: AppColors.warning,
            onTap: controller.emergencyUnlock,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Obx(() => Card(
      color: AppColors.success.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(
          Icons.bluetooth_connected,
          color: AppColors.success,
          size: 32,
        ),
        title: const Text(
          'Terhubung ke',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          controller.connectedDevice.value?.platformName ?? 'Unknown Device',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: TextButton(
          onPressed: controller.disconnect,
          child: const Text('Putuskan'),
        ),
      ),
    ));
  }

  Widget _buildLockStatusCard() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              controller.isHelmetLocked.value ? Icons.lock : Icons.lock_open,
              size: 80,
              color: controller.isHelmetLocked.value
                  ? AppColors.locked
                  : AppColors.unlocked,
            ),
            const SizedBox(height: 16),
            Text(
              controller.lockStatus.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.isHelmetLocked.value
                  ? 'Helm dalam keadaan aman'
                  : 'Helm dapat digunakan',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildAlarmCard() {
    return Obx(() => Card(
      color: controller.isAlarmActive.value
          ? AppColors.warning.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: Icon(
          controller.isAlarmActive.value
              ? Icons.notifications_active
              : Icons.notifications_off,
          size: 32,
          color: controller.isAlarmActive.value
              ? AppColors.warning
              : AppColors.textSecondary,
        ),
        title: Text(
          controller.isAlarmActive.value ? 'Alarm Aktif' : 'Alarm Nonaktif',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          controller.isAlarmActive.value
              ? 'Alarm akan berbunyi jika ada percobaan pembobolan'
              : 'Alarm tidak aktif',
        ),
        trailing: Switch(
          value: controller.isAlarmActive.value,
          onChanged: (value) => controller.toggleAlarm(),
          activeColor: AppColors.warning,
        ),
      ),
    ));
  }

  Widget _buildFeatureButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
