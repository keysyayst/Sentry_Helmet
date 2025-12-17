import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentry Helmet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: controller.goToSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Card
              _buildConnectionCard(),
              const SizedBox(height: 16),

              // Helmet Lock Control
              _buildLockCard(),
              const SizedBox(height: 16),

              // Sensor Data Section
              Text(
                'Data Sensor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Temperature & Humidity
              Row(
                children: [
                  Expanded(child: _buildTemperatureCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildHumidityCard()),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text('Menu Utama', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              _buildQuickActionButton(
                title: 'Keamanan Helm',
                subtitle: 'Kontrol kunci & alarm',
                icon: Icons.lock,
                color: AppColors.primary,
                onTap: controller.goToHelmetSecurity,
              ),
              const SizedBox(height: 12),

              _buildQuickActionButton(
                title: 'Keselamatan Pengendara',
                subtitle: 'GPS tracking & deteksi kecelakaan',
                icon: Icons.health_and_safety,
                color: AppColors.success,
                onTap: controller.goToRiderSafety,
              ),
              const SizedBox(height: 12),

              _buildQuickActionButton(
                title: 'BLE Connect',
                subtitle: 'Kontrol ESP32 via Bluetooth',
                icon: Icons.bluetooth,
                color: Colors.blue,
                onTap: () => Get.toNamed(Routes.BLE_CONNECT),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Obx(
      () => Card(
        child: ListTile(
          leading: Icon(
            Icons.bluetooth,
            color: controller.connectionStatus.value == 'Terhubung'
                ? AppColors.success
                : AppColors.error,
            size: 32,
          ),
          title: const Text('Status Koneksi'),
          subtitle: Text(controller.connectionStatus.value),
          trailing: controller.connectionStatus.value == 'Terputus'
              ? ElevatedButton(
                  onPressed: controller.connectToBluetooth,
                  child: const Text('Hubungkan'),
                )
              : const Icon(Icons.check_circle, color: AppColors.success),
        ),
      ),
    );
  }

  Widget _buildLockCard() {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                controller.isHelmetLocked.value ? Icons.lock : Icons.lock_open,
                size: 64,
                color: controller.isHelmetLocked.value
                    ? AppColors.locked
                    : AppColors.unlocked,
              ),
              const SizedBox(height: 12),
              Text(
                controller.isHelmetLocked.value
                    ? 'Helm Terkunci'
                    : 'Helm Terbuka',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.toggleLock,
                      icon: Icon(
                        controller.isHelmetLocked.value
                            ? Icons.lock_open
                            : Icons.lock,
                      ),
                      label: Text(
                        controller.isHelmetLocked.value ? 'Buka' : 'Kunci',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: controller.isHelmetLocked.value
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.toggleAlarm,
                      icon: Icon(
                        controller.isAlarmActive.value
                            ? Icons.notifications_off
                            : Icons.notifications_active,
                      ),
                      label: Text(
                        controller.isAlarmActive.value ? 'Matikan' : 'Alarm',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return Obx(() {
      final temp = controller.temperature.value;
      final isNormal = temp >= 0 && temp <= 45;

      return Card(
        color: isNormal ? null : AppColors.warning.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.thermostat, size: 32, color: AppColors.error),
              const SizedBox(height: 8),
              const Text(
                'Suhu',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${temp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isNormal)
                const Text(
                  'Abnormal',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHumidityCard() {
    return Obx(() {
      final hum = controller.humidity.value;
      final isNormal = hum >= 20 && hum <= 90;

      return Card(
        color: isNormal ? null : AppColors.warning.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.water_drop, size: 32, color: AppColors.info),
              const SizedBox(height: 8),
              const Text(
                'Kelembaban',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${hum.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isNormal)
                const Text(
                  'Abnormal',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
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
                        fontSize: 14,
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
