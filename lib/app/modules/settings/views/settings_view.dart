import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../data/models/emergency_contact_model.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile Section
          _buildSectionHeader('Profil Pengguna'),
          Obx(() => _buildProfileTile()),
          const Divider(),

          // Device Settings
          _buildSectionHeader('Pengaturan Perangkat'),
          Obx(
            () => _buildSwitchTile(
              title: 'Kunci Otomatis',
              subtitle: 'Kunci helm otomatis saat terputus',
              icon: Icons.lock_clock,
              value: controller.autoLock.value,
              onChanged: controller.toggleAutoLock,
            ),
          ),
          Obx(
            () => _buildSwitchTile(
              title: 'Notifikasi',
              subtitle: 'Terima notifikasi keamanan dan peringatan',
              icon: Icons.notifications,
              value: controller.notificationEnabled.value,
              onChanged: controller.toggleNotification,
            ),
          ),
          const Divider(),

          // Emergency Contacts
          _buildSectionHeader('Kontak Darurat'),
          Obx(() {
            if (controller.emergencyContacts.isEmpty) {
              return ListTile(
                leading: const Icon(Icons.contact_emergency),
                title: const Text('Belum ada kontak darurat'),
                subtitle: const Text(
                  'Tambahkan kontak untuk notifikasi darurat',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: controller.showAddContactDialog,
                ),
              );
            }

            return Column(
              children: [
                ...controller.emergencyContacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return _buildEmergencyContactTile(contact, index);
                }),
                ListTile(
                  leading: const Icon(Icons.add, color: AppColors.primary),
                  title: const Text(
                    'Tambah Kontak Darurat',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  onTap: controller.showAddContactDialog,
                ),
              ],
            );
          }),
          const Divider(),

          // Appearance
          _buildSectionHeader('Tampilan'),
          Obx(
            () => _buildSwitchTile(
              title: 'Mode Gelap',
              subtitle: 'Gunakan tema gelap',
              icon: Icons.dark_mode,
              value: controller.darkMode.value,
              onChanged: controller.toggleDarkMode,
            ),
          ),
          const Divider(),

          // About & Help
          _buildSectionHeader('Tentang'),
          _buildListTile(
            title: 'Tentang Aplikasi',
            icon: Icons.info,
            onTap: controller.showAboutApp,
          ),
          _buildListTile(
            title: 'Panduan Penggunaan',
            icon: Icons.help,
            onTap: () {
              // Navigate to help page
            },
          ),
          const Divider(),

          // Danger Zone
          _buildSectionHeader('Zona Bahaya', color: AppColors.error),
          _buildListTile(
            title: 'Putuskan Koneksi Perangkat',
            icon: Icons.bluetooth_disabled,
            titleColor: AppColors.warning,
            onTap: controller.disconnectDevice,
          ),
          _buildListTile(
            title: 'Hapus Semua Data',
            icon: Icons.delete_forever,
            titleColor: AppColors.error,
            onTap: controller.clearAllData,
          ),
          const SizedBox(height: 16),

          // Version
          Center(
            child: Text(
              'Versi ${AppConstants.appVersion}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          controller.userName.value.isNotEmpty
              ? controller.userName.value[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        controller.userName.value.isEmpty
            ? 'Nama Pengguna'
            : controller.userName.value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        controller.userPhone.value.isEmpty
            ? 'Belum diatur'
            : controller.userPhone.value,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: controller.showEditProfileDialog,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildEmergencyContactTile(EmergencyContactModel contact, int index) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.error,
        child: Icon(Icons.emergency, color: Colors.white, size: 20),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${contact.relation} - ${contact.phoneNumber}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: AppColors.error),
        onPressed: () => controller.removeEmergencyContact(index),
      ),
    );
  }
}
