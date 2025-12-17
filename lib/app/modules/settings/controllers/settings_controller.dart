import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/firebase_service.dart';
import '../../../data/models/emergency_contact_model.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage();
  final BluetoothService _bluetoothService = Get.find();
  final FirebaseService _firebaseService = Get.find();

  // Observables
  final RxString userName = ''.obs;
  final RxString userPhone = ''.obs;
  final RxBool autoLock = true.obs;
  final RxBool notificationEnabled = true.obs;
  final RxBool darkMode = false.obs;
  final RxList<EmergencyContactModel> emergencyContacts = <EmergencyContactModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  // Load settings from storage
  void _loadSettings() {
    userName.value = _storage.read(AppConstants.keyUserName) ?? '';
    userPhone.value = _storage.read(AppConstants.keyUserPhone) ?? '';
    autoLock.value = _storage.read(AppConstants.keyAutoLock) ?? true;
    notificationEnabled.value = _storage.read(AppConstants.keyNotificationEnabled) ?? true;
    
    // Load emergency contacts
    final contactsJson = _storage.read(AppConstants.keyEmergencyContacts);
    if (contactsJson != null && contactsJson is List) {
      emergencyContacts.value = contactsJson
          .map((json) => EmergencyContactModel.fromJson(json))
          .toList();
    }
  }

  // Save user name
  Future<void> saveUserName(String name) async {
    userName.value = name;
    await _storage.write(AppConstants.keyUserName, name);
    Helpers.showSuccess('Nama berhasil disimpan');
  }

  // Save user phone
  Future<void> saveUserPhone(String phone) async {
    if (!Helpers.isValidPhoneNumber(phone)) {
      Helpers.showError('Nomor telepon tidak valid');
      return;
    }
    
    userPhone.value = phone;
    await _storage.write(AppConstants.keyUserPhone, phone);
    Helpers.showSuccess('Nomor telepon berhasil disimpan');
  }

  // Toggle auto lock
  Future<void> toggleAutoLock(bool value) async {
    autoLock.value = value;
    await _storage.write(AppConstants.keyAutoLock, value);
  }

  // Toggle notification
  Future<void> toggleNotification(bool value) async {
    notificationEnabled.value = value;
    await _storage.write(AppConstants.keyNotificationEnabled, value);
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    darkMode.value = value;
    // Implement theme switching
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  // Add emergency contact
  Future<void> addEmergencyContact(EmergencyContactModel contact) async {
    if (!contact.isValidPhoneNumber) {
      Helpers.showError('Nomor telepon tidak valid');
      return;
    }

    emergencyContacts.add(contact);
    await _saveEmergencyContacts();
    Helpers.showSuccess('Kontak darurat ditambahkan');
  }

  // Edit emergency contact
  Future<void> editEmergencyContact(int index, EmergencyContactModel contact) async {
    if (index < 0 || index >= emergencyContacts.length) return;
    
    if (!contact.isValidPhoneNumber) {
      Helpers.showError('Nomor telepon tidak valid');
      return;
    }

    emergencyContacts[index] = contact;
    await _saveEmergencyContacts();
    Helpers.showSuccess('Kontak darurat diperbarui');
  }

  // Remove emergency contact
  Future<void> removeEmergencyContact(int index) async {
    bool confirm = await Helpers.showConfirmDialog(
      title: 'Hapus Kontak',
      message: 'Apakah Anda yakin ingin menghapus kontak ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );

    if (confirm) {
      emergencyContacts.removeAt(index);
      await _saveEmergencyContacts();
      Helpers.showSuccess('Kontak darurat dihapus');
    }
  }

  // Save emergency contacts to storage
  Future<void> _saveEmergencyContacts() async {
    final contactsJson = emergencyContacts.map((c) => c.toJson()).toList();
    await _storage.write(AppConstants.keyEmergencyContacts, contactsJson);
  }

  // Show add contact dialog
  void showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Tambah Kontak Darurat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Hubungan',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  relationController.text.isEmpty) {
                Helpers.showError('Semua field harus diisi');
                return;
              }

              final contact = EmergencyContactModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                phoneNumber: phoneController.text,
                relation: relationController.text,
              );

              addEmergencyContact(contact);
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Show edit user profile dialog
  void showEditProfileDialog() {
    final nameController = TextEditingController(text: userName.value);
    final phoneController = TextEditingController(text: userPhone.value);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              saveUserName(nameController.text);
              saveUserPhone(phoneController.text);
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    bool confirm = await Helpers.showConfirmDialog(
      title: 'Hapus Semua Data',
      message: 'Apakah Anda yakin ingin menghapus semua data aplikasi? Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );

    if (confirm) {
      await _storage.erase();
      _loadSettings();
      Helpers.showSuccess('Semua data telah dihapus');
    }
  }

  // Disconnect and clear
  Future<void> disconnectDevice() async {
    if (_bluetoothService.isConnected.value) {
      await _bluetoothService.disconnect();
    }
  }

  // About app
  void showAboutApp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SENTRY HELMET',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Sistem Keamanan Helm dan Keselamatan Pengendara Berbasis IoT dengan GPS Tracking, Smart Lock, dan Rider Safety Monitoring.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Dibuat oleh:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Keysya Yesanti Safa\'at (202310370311363)'),
            Text('Irfan Deny (202310370311377)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
