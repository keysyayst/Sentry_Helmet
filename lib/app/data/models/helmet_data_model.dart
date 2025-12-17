import 'sensor_data_model.dart';

class HelmetDataModel {
  final String id;
  final bool isLocked;
  final bool isActive;
  final bool isConnected;
  final DateTime timestamp;
  final SensorDataModel? sensorData;
  final String deviceId;
  final String deviceName;

  HelmetDataModel({
    required this.id,
    required this.isLocked,
    required this.isActive,
    required this.isConnected,
    required this.timestamp,
    this.sensorData,
    required this.deviceId,
    required this.deviceName,
  });

  // From JSON
  factory HelmetDataModel.fromJson(Map<String, dynamic> json) {
    return HelmetDataModel(
      id: json['id'] ?? '',
      isLocked: json['isLocked'] ?? false,
      isActive: json['isActive'] ?? false,
      isConnected: json['isConnected'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      sensorData: json['sensorData'] != null
          ? SensorDataModel.fromJson(json['sensorData'])
          : null,
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isLocked': isLocked,
      'isActive': isActive,
      'isConnected': isConnected,
      'timestamp': timestamp.toIso8601String(),
      'sensorData': sensorData?.toJson(),
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  // CopyWith
  HelmetDataModel copyWith({
    String? id,
    bool? isLocked,
    bool? isActive,
    bool? isConnected,
    DateTime? timestamp,
    SensorDataModel? sensorData,
    String? deviceId,
    String? deviceName,
  }) {
    return HelmetDataModel(
      id: id ?? this.id,
      isLocked: isLocked ?? this.isLocked,
      isActive: isActive ?? this.isActive,
      isConnected: isConnected ?? this.isConnected,
      timestamp: timestamp ?? this.timestamp,
      sensorData: sensorData ?? this.sensorData,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  // Empty constructor
  static HelmetDataModel empty() {
    return HelmetDataModel(
      id: '',
      isLocked: false,
      isActive: false,
      isConnected: false,
      timestamp: DateTime.now(),
      deviceId: '',
      deviceName: '',
    );
  }

  @override
  String toString() {
    return 'HelmetDataModel(id: $id, isLocked: $isLocked, isActive: $isActive, isConnected: $isConnected)';
  }
}
