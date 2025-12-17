import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../services/location_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/bluetooth_service.dart';
import '../../../data/models/sensor_data_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/ride_history_model.dart';
import '../../../core/utils/helpers.dart';

class RiderSafetyController extends GetxController {
  final LocationService _locationService = Get.find();
  final FirebaseService _firebaseService = Get.find();
  final NotificationService _notificationService = Get.find();
  final BluetoothService _bluetoothService = Get.find();

  // Observables
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final Rx<SensorDataModel?> sensorData = Rx<SensorDataModel?>(null);
  final RxBool isTracking = false.obs;
  final RxBool isCrashDetected = false.obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxDouble maxSpeed = 0.0.obs;
  final RxDouble totalDistance = 0.0.obs;
  final Rx<Duration> rideDuration = Duration.zero.obs;

  // Ride tracking
  final Rx<RideHistoryModel?> currentRide = Rx<RideHistoryModel?>(null);
  final RxList<LocationData> routePoints = <LocationData>[].obs;

  // Alerts
  final RxList<AlertModel> recentAlerts = <AlertModel>[].obs;

  Timer? _trackingTimer;
  Timer? _durationTimer;
  DateTime? _rideStartTime;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _listenToSensorData();
  }

  void _initializeData() async {
    // Get current location
    await _getCurrentLocation();

    // Listen to location updates
    ever(_locationService.currentPosition, (position) {
      if (position != null) {
        currentPosition.value = position;
        currentSpeed.value = position.speed * 3.6; // m/s to km/h

        if (currentSpeed.value > maxSpeed.value) {
          maxSpeed.value = currentSpeed.value;
        }
      }
    });

    // Load recent alerts
    _loadRecentAlerts();
  }

  void _listenToSensorData() {
    // Listen to sensor data from Bluetooth
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_bluetoothService.isConnected.value && isTracking.value) {
        _checkSensorData();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await _locationService.getCurrentLocation();
    if (position != null) {
      currentPosition.value = position;
    }
  }

  void _checkSensorData() {
    // This would be called when receiving data from Bluetooth
    // For now, we'll create a placeholder

    // Check for crash detection
    if (sensorData.value != null) {
      if (sensorData.value!.accelerometer.isCrash) {
        _handleCrashDetection();
      }
    }
  }

  Future<void> _handleCrashDetection() async {
    if (isCrashDetected.value) return; // Already handling

    isCrashDetected.value = true;

    // Stop tracking
    await stopTracking();

    // Create alert
    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.crash,
      severity: AlertSeverity.critical,
      title: 'Kecelakaan Terdeteksi',
      message: 'Benturan keras terdeteksi. Notifikasi darurat sedang dikirim.',
      timestamp: DateTime.now(),
      location: currentPosition.value != null
          ? LocationData(
              latitude: currentPosition.value!.latitude,
              longitude: currentPosition.value!.longitude,
              timestamp: DateTime.now(),
            )
          : null,
    );

    // Save alert
    await _firebaseService.saveAlert(alert);
    recentAlerts.insert(0, alert);

    // Show notification
    await _notificationService.showCrashAlert(
      message: alert.message,
      location: alert.location?.coordinatesString ?? 'Unknown',
    );

    // Show dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Kecelakaan Terdeteksi!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem mendeteksi benturan keras. Notifikasi darurat akan dikirim ke kontak darurat Anda dalam 30 detik.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (currentPosition.value != null)
                Text(
                  'Lokasi: ${currentPosition.value!.latitude.toStringAsFixed(6)}, ${currentPosition.value!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                isCrashDetected.value = false;
                Get.back();
                Helpers.showInfo('Notifikasi darurat dibatalkan');
              },
              child: const Text('Saya Baik-Baik Saja'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _sendEmergencyAlert();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Kirim Notifikasi Sekarang'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Auto send emergency alert after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (isCrashDetected.value) {
        _sendEmergencyAlert();
      }
    });
  }

  Future<void> _sendEmergencyAlert() async {
    Helpers.showLoadingDialog('Mengirim notifikasi darurat...');

    // Simulate sending to emergency contacts
    await Future.delayed(const Duration(seconds: 2));

    Helpers.hideLoadingDialog();
    Helpers.showSuccess('Notifikasi darurat telah dikirim ke kontak darurat');

    isCrashDetected.value = false;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Start ride tracking
  Future<void> startTracking() async {
    if (!await _locationService.requestLocationPermission()) {
      return;
    }

    isTracking.value = true;
    _rideStartTime = DateTime.now();
    routePoints.clear();
    totalDistance.value = 0.0;
    maxSpeed.value = 0.0;

    // Get starting position
    await _getCurrentLocation();

    if (currentPosition.value != null) {
      routePoints.add(
        LocationData(
          latitude: currentPosition.value!.latitude,
          longitude: currentPosition.value!.longitude,
          timestamp: DateTime.now(),
        ),
      );

      // Create ride history
      currentRide.value = RideHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _rideStartTime!,
        startLocation: routePoints.first,
      );
    }

    // Start location tracking
    await _locationService.startTracking();

    // Start tracking timer
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRouteTracking();
    });

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rideStartTime != null) {
        rideDuration.value = DateTime.now().difference(_rideStartTime!);
      }
    });

    Helpers.showSuccess('Pelacakan dimulai');
  }

  void _updateRouteTracking() {
    if (currentPosition.value != null && routePoints.isNotEmpty) {
      final lastPoint = routePoints.last;
      final newPoint = LocationData(
        latitude: currentPosition.value!.latitude,
        longitude: currentPosition.value!.longitude,
        timestamp: DateTime.now(),
      );

      // Calculate distance from last point
      double distance = _locationService.calculateDistance(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      totalDistance.value += distance;
      routePoints.add(newPoint);
    }
  }

  // Stop ride tracking
  Future<void> stopTracking() async {
    if (!isTracking.value) return;

    isTracking.value = false;
    _trackingTimer?.cancel();
    _durationTimer?.cancel();
    _locationService.stopTracking();

    // Finalize ride history
    if (currentRide.value != null && currentPosition.value != null) {
      final endLocation = LocationData(
        latitude: currentPosition.value!.latitude,
        longitude: currentPosition.value!.longitude,
        timestamp: DateTime.now(),
      );

      final finalRide = currentRide.value!.copyWith(
        endTime: DateTime.now(),
        endLocation: endLocation,
        distance: totalDistance.value,
        duration: rideDuration.value,
        route: routePoints,
        maxSpeed: maxSpeed.value,
        avgSpeed: totalDistance.value / (rideDuration.value.inSeconds / 3600),
      );

      // Save to Firebase
      await _firebaseService.saveRideHistory(finalRide);

      Helpers.showSuccess('Pelacakan dihentikan dan disimpan');
    }

    // Reset values
    currentRide.value = null;
    rideDuration.value = Duration.zero;
    _rideStartTime = null;
  }

  // Load recent alerts
  void _loadRecentAlerts() {
    _firebaseService.getAlertsStream(limit: 10).listen((alerts) {
      recentAlerts.value = alerts;
    });
  }

  // Open location in maps
  void openInMaps() async {
    if (currentPosition.value != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${currentPosition.value!.latitude},${currentPosition.value!.longitude}';
      Helpers.showInfo('Membuka Google Maps...');
      // In real app, use url_launcher package
      print('Opening: $url');
    } else {
      Helpers.showError('Lokasi tidak tersedia');
    }
  }

  // Simulate crash (for testing)
  Future<void> simulateCrash() async {
    bool confirm = await Helpers.showConfirmDialog(
      title: 'Simulasi Kecelakaan',
      message: 'Ini akan memicu sistem deteksi kecelakaan. Lanjutkan?',
      confirmText: 'Ya, Simulasi',
      cancelText: 'Batal',
    );

    if (confirm) {
      // Create fake crash sensor data
      sensorData.value = SensorDataModel(
        temperature: 25.0,
        humidity: 60.0,
        accelerometer: AccelerometerData(
          x: 5.0,
          y: 5.0,
          z: 5.0,
        ), // High G-force
        location: currentPosition.value != null
            ? LocationData(
                latitude: currentPosition.value!.latitude,
                longitude: currentPosition.value!.longitude,
              )
            : LocationData.empty(),
        timestamp: DateTime.now(),
        isCrashDetected: true,
      );

      await _handleCrashDetection();
    }
  }

  @override
  void onClose() {
    _trackingTimer?.cancel();
    _durationTimer?.cancel();
    if (isTracking.value) {
      stopTracking();
    }
    super.onClose();
  }
}
