import 'sensor_data_model.dart';

enum AlertType {
  crash,
  theft,
  temperatureHigh,
  temperatureLow,
  humidityHigh,
  humidityLow,
  batteryLow,
  connection,
  other,
}

enum AlertSeverity {
  critical,
  high,
  medium,
  low,
  info,
}

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final LocationData? location;
  final bool isRead;
  final bool isResolved;
  final Map<String, dynamic>? metadata;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.location,
    this.isRead = false,
    this.isResolved = false,
    this.metadata,
  });

  // From JSON
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.toString() == 'AlertType.${json['type']}',
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${json['severity']}',
        orElse: () => AlertSeverity.info,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
      isRead: json['isRead'] ?? false,
      isResolved: json['isResolved'] ?? false,
      metadata: json['metadata'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'isRead': isRead,
      'isResolved': isResolved,
      'metadata': metadata,
    };
  }

  // CopyWith
  AlertModel copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    LocationData? location,
    bool? isRead,
    bool? isResolved,
    Map<String, dynamic>? metadata,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get icon based on type
  String get icon {
    switch (type) {
      case AlertType.crash:
        return '🚨';
      case AlertType.theft:
        return '🔒';
      case AlertType.temperatureHigh:
      case AlertType.temperatureLow:
        return '🌡️';
      case AlertType.humidityHigh:
      case AlertType.humidityLow:
        return '💧';
      case AlertType.batteryLow:
        return '🔋';
      case AlertType.connection:
        return '📡';
      default:
        return 'ℹ️';
    }
  }

  // Get color based on severity
  String get colorHex {
    switch (severity) {
      case AlertSeverity.critical:
        return '#D32F2F';
      case AlertSeverity.high:
        return '#F44336';
      case AlertSeverity.medium:
        return '#FF9800';
      case AlertSeverity.low:
        return '#FFC107';
      case AlertSeverity.info:
        return '#2196F3';
    }
  }

  @override
  String toString() {
    return 'AlertModel(type: $type, severity: $severity, title: $title)';
  }
}
