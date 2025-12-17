import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';  // ← Package ini perlu diinstall
import 'dart:math';
import 'constants.dart';  

class Helpers {
  // Format DateTime
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
  
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy').format(dateTime);
  }
  
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} detik lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return formatDate(dateTime);
    }
  }
  
  // Snackbar helpers
  static void showSuccess(String message) {
    Get.snackbar(
      'Berhasil',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
  
  static void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
  
  static void showWarning(String message) {
    Get.snackbar(
      'Peringatan',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
  
  static void showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
  
  // Dialog helpers
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  static void showLoadingDialog([String message = 'Loading...']) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
  
  // Temperature validation
  static bool isTemperatureNormal(double temperature) {
    return temperature >= AppConstants.minTemperature && 
           temperature <= AppConstants.maxTemperature;
  }
  
  static String getTemperatureStatus(double temperature) {
    if (temperature < AppConstants.minTemperature) {
      return 'Terlalu Dingin';
    } else if (temperature > AppConstants.maxTemperature) {
      return 'Terlalu Panas';
    } else {
      return 'Normal';
    }
  }
  
  // Humidity validation
  static bool isHumidityNormal(double humidity) {
    return humidity >= AppConstants.minHumidity && 
           humidity <= AppConstants.maxHumidity;
  }
  
  static String getHumidityStatus(double humidity) {
    if (humidity < AppConstants.minHumidity) {
      return 'Terlalu Kering';
    } else if (humidity > AppConstants.maxHumidity) {
      return 'Terlalu Lembab';
    } else {
      return 'Normal';
    }
  }
  
  // Parse sensor data from ESP32
  static Map<String, dynamic> parseSensorData(String data) {
    try {
      // Expected format: "TEMP:25.5,HUM:60.2,ACC_X:0.1,ACC_Y:0.2,ACC_Z:9.8,LAT:-7.9666,LON:112.6326"
      final Map<String, dynamic> result = {};
      final parts = data.split(',');
      
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0]] = double.tryParse(keyValue[1]) ?? 0.0;
        }
      }
      
      return result;
    } catch (e) {
      return {};
    }
  }
  
  // Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - 
              cos((lat2 - lat1) * p) / 2 + 
              cos(lat1 * p) * 
              cos(lat2 * p) * 
              (1 - cos((lon2 - lon1) * p)) / 2;
    
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
  
  // Phone number validation
  static bool isValidPhoneNumber(String phone) {
    // Indonesian phone number validation
    final regex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    return regex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }
  
  static String formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('0')) {
      return '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      return '+$phone';
    }
    return phone;
  }
  
  // Detect crash from accelerometer data
  static bool isCrashDetected(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    return magnitude > AppConstants.crashThreshold;
  }
}
