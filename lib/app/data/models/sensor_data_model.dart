class SensorDataModel {
  final double temperature;
  final double humidity;
  final AccelerometerData accelerometer;
  final LocationData location;
  final DateTime timestamp;
  final bool isCrashDetected;
  final String rfidStatus;

  SensorDataModel({
    required this.temperature,
    required this.humidity,
    required this.accelerometer,
    required this.location,
    required this.timestamp,
    this.isCrashDetected = false,
    this.rfidStatus = 'IDLE',
  });

  // From JSON
  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      accelerometer: AccelerometerData.fromJson(json['accelerometer'] ?? {}),
      location: LocationData.fromJson(json['location'] ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isCrashDetected: json['isCrashDetected'] ?? false,
      rfidStatus: json['rfidStatus'] ?? 'IDLE',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'accelerometer': accelerometer.toJson(),
      'location': location.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'isCrashDetected': isCrashDetected,
      'rfidStatus': rfidStatus,
    };
  }

  // Parse dari String ESP32
  // Format: "TEMP:25.5,HUM:60.2,ACC_X:0.1,ACC_Y:0.2,ACC_Z:9.8,LAT:-7.9666,LON:112.6326,RFID:ACTIVE"
  factory SensorDataModel.fromESP32String(String data) {
    try {
      final Map<String, double> values = {};
      String rfidStatus = 'IDLE';

      final parts = data.split(',');
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();

          if (key == 'RFID') {
            rfidStatus = value;
          } else {
            values[key] = double.tryParse(value) ?? 0.0;
          }
        }
      }

      return SensorDataModel(
        temperature: values['TEMP'] ?? 0.0,
        humidity: values['HUM'] ?? 0.0,
        accelerometer: AccelerometerData(
          x: values['ACC_X'] ?? 0.0,
          y: values['ACC_Y'] ?? 0.0,
          z: values['ACC_Z'] ?? 0.0,
        ),
        location: LocationData(
          latitude: values['LAT'] ?? 0.0,
          longitude: values['LON'] ?? 0.0,
        ),
        timestamp: DateTime.now(),
        rfidStatus: rfidStatus,
      );
    } catch (e) {
      return SensorDataModel.empty();
    }
  }

  // Empty constructor
  static SensorDataModel empty() {
    return SensorDataModel(
      temperature: 0.0,
      humidity: 0.0,
      accelerometer: AccelerometerData.empty(),
      location: LocationData.empty(),
      timestamp: DateTime.now(),
    );
  }

  // Check if temperature is normal
  bool get isTemperatureNormal {
    return temperature >= 0.0 && temperature <= 45.0;
  }

  // Check if humidity is normal
  bool get isHumidityNormal {
    return humidity >= 20.0 && humidity <= 90.0;
  }

  // Get temperature status
  String get temperatureStatus {
    if (temperature < 0.0) return 'Terlalu Dingin';
    if (temperature > 45.0) return 'Terlalu Panas';
    return 'Normal';
  }

  // Get humidity status
  String get humidityStatus {
    if (humidity < 20.0) return 'Terlalu Kering';
    if (humidity > 90.0) return 'Terlalu Lembab';
    return 'Normal';
  }

  @override
  String toString() {
    return 'SensorDataModel(temp: $temperature°C, hum: $humidity%, crash: $isCrashDetected)';
  }
}

// Accelerometer Data
class AccelerometerData {
  final double x;
  final double y;
  final double z;

  AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
  });

  factory AccelerometerData.fromJson(Map<String, dynamic> json) {
    return AccelerometerData(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }

  // Calculate magnitude (G-force)
  double get magnitude {
    return (x * x + y * y + z * z).abs();
  }

  // Check if crash detected (threshold: 3.0 G)
  bool get isCrash {
    return magnitude > 3.0;
  }

  static AccelerometerData empty() {
    return AccelerometerData(x: 0.0, y: 0.0, z: 0.0);
  }

  @override
  String toString() {
    return 'AccelerometerData(x: $x, y: $y, z: $z, magnitude: ${magnitude.toStringAsFixed(2)})';
  }
}

// Location Data
class LocationData {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Check if location is valid
  bool get isValid {
    return latitude != 0.0 && longitude != 0.0;
  }

  // Get Google Maps URL
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // Get coordinates as string
  String get coordinatesString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  static LocationData empty() {
    return LocationData(latitude: 0.0, longitude: 0.0);
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lon: $longitude)';
  }
}
