import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/helpers.dart';
import '../data/models/sensor_data_model.dart';

class LocationService extends GetxService {
  // Observables
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLocationEnabled = false.obs;
  final RxBool isTracking = false.obs;
  final RxDouble currentSpeed = 0.0.obs;

  Future<LocationService> init() async {
    // Check location permission
    await checkLocationPermission();
    
    // Check if location service is enabled
    await checkLocationService();

    return this;
  }

  // Check location permission
  Future<bool> checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      Helpers.showError('Izin lokasi diperlukan. Buka pengaturan untuk mengaktifkan.');
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // Check if location service is enabled
  Future<bool> checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationEnabled.value = serviceEnabled;

    if (!serviceEnabled) {
      Helpers.showWarning('Layanan lokasi tidak aktif');
      return false;
    }

    return true;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      return false;
    }

    bool serviceEnabled = await checkLocationService();
    if (!serviceEnabled) {
      // Try to open location settings
      try {
        await Geolocator.openLocationSettings();
      } catch (e) {
        Helpers.showError('Tidak dapat membuka pengaturan lokasi');
      }
      return false;
    }

    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (!(await requestLocationPermission())) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentPosition.value = position;
      return position;

    } catch (e) {
      Helpers.showError('Gagal mendapatkan lokasi: $e');
      return null;
    }
  }

  // Start location tracking
  Future<void> startTracking() async {
    if (!(await requestLocationPermission())) {
      return;
    }

    isTracking.value = true;

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        currentPosition.value = position;
        currentSpeed.value = position.speed * 3.6; // Convert m/s to km/h
      },
      onError: (error) {
        Helpers.showError('Error tracking lokasi: $error');
        isTracking.value = false;
      },
    );
  }

  // Stop location tracking
  void stopTracking() {
    isTracking.value = false;
  }

  // Calculate distance between two positions
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLon,
      endLat,
      endLon,
    ) / 1000; // Convert to kilometers
  }

  // Get LocationData model from Position
  LocationData getLocationData(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }

  // Get current LocationData
  Future<LocationData?> getCurrentLocationData() async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      return getLocationData(position);
    }
    return null;
  }

  // Check if user is near a location (within radius in meters)
  bool isNearLocation(
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    if (currentPosition.value == null) return false;

    double distance = Geolocator.distanceBetween(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
      targetLat,
      targetLon,
    );

    return distance <= radiusInMeters;
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
