import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rider_safety_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class RiderSafetyView extends GetView<RiderSafetyController> {
  const RiderSafetyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keselamatan Pengendara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to ride history
              Get.toNamed('/ride-history');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPS Status Card
            _buildGPSStatusCard(),
            const SizedBox(height: 16),
            
            // Tracking Control
            _buildTrackingCard(),
            const SizedBox(height: 16),
            
            // Current Ride Stats (when tracking)
            Obx(() {
              if (controller.isTracking.value) {
                return Column(
                  children: [
                    _buildRideStatsCard(),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            
            // Safety Features
            Text(
              'Fitur Keselamatan',
              style: Get.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              title: 'Deteksi Kecelakaan',
              subtitle: 'Otomatis mengirim notifikasi saat terjadi benturan',
              icon: Icons.warning_amber,
              color: AppColors.error,
              isActive: true,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              title: 'GPS Tracking Real-time',
              subtitle: 'Pantau lokasi Anda secara langsung',
              icon: Icons.my_location,
              color: AppColors.primary,
              isActive: controller.isTracking.value,
            ),
            const SizedBox(height: 24),
            
            // Recent Alerts
            _buildRecentAlertsSection(),
            const SizedBox(height: 24),
            
            // Emergency Actions
            Text(
              'Aksi Darurat',
              style: Get.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            _buildEmergencyButton(
              title: 'Buka Lokasi di Maps',
              icon: Icons.map,
              color: AppColors.primary,
              onTap: controller.openInMaps,
            ),
            const SizedBox(height: 12),
            
            _buildEmergencyButton(
              title: 'Simulasi Kecelakaan (Testing)',
              icon: Icons.bug_report,
              color: AppColors.warning,
              onTap: controller.simulateCrash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSStatusCard() {
    return Obx(() {
      final hasLocation = controller.currentPosition.value != null;
      
      return Card(
        color: hasLocation
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.gps_fixed : Icons.gps_off,
                size: 32,
                color: hasLocation ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? 'GPS Aktif' : 'GPS Tidak Aktif',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation
                          ? 'Lat: ${controller.currentPosition.value!.latitude.toStringAsFixed(6)}\nLon: ${controller.currentPosition.value!.longitude.toStringAsFixed(6)}'
                          : 'Nyalakan GPS untuk melacak lokasi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTrackingCard() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              controller.isTracking.value
                  ? Icons.directions_bike
                  : Icons.not_started,
              size: 64,
              color: controller.isTracking.value
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              controller.isTracking.value
                  ? 'Pelacakan Aktif'
                  : 'Tidak Melacak',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.isTracking.value
                  ? 'Perjalanan Anda sedang dipantau'
                  : 'Mulai pelacakan untuk keamanan perjalanan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.isTracking.value
                  ? controller.stopTracking
                  : controller.startTracking,
              icon: Icon(
                controller.isTracking.value ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(
                controller.isTracking.value
                    ? 'Hentikan Pelacakan'
                    : 'Mulai Pelacakan',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isTracking.value
                    ? AppColors.error
                    : AppColors.success,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildRideStatsCard() {
    return Obx(() => Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Perjalanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Durasi',
                    value: _formatDuration(controller.rideDuration.value),
                    icon: Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Jarak',
                    value: '${controller.totalDistance.value.toStringAsFixed(2)} km',
                    icon: Icons.route,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Kecepatan',
                    value: '${controller.currentSpeed.value.toStringAsFixed(1)} km/h',
                    icon: Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Max Speed',
                    value: '${controller.maxSpeed.value.toStringAsFixed(1)} km/h',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    return Obx(() {
      if (controller.recentAlerts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peringatan Terbaru',
            style: Get.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...controller.recentAlerts.take(3).map((alert) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Text(
                alert.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                alert.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                Helpers.formatTimeAgo(alert.timestamp),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to alert details
              },
            ),
          )),
        ],
      );
    });
  }

  Widget _buildEmergencyButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
