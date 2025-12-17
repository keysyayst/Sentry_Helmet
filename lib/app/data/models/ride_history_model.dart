import 'sensor_data_model.dart';

class RideHistoryModel {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final LocationData startLocation;
  final LocationData? endLocation;
  final double? distance;
  final Duration? duration;
  final List<LocationData> route;
  final double? avgSpeed;
  final double? maxSpeed;
  final bool hadIncident;
  final List<String>? incidentIds;

  RideHistoryModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.endLocation,
    this.distance,
    this.duration,
    this.route = const [],
    this.avgSpeed,
    this.maxSpeed,
    this.hadIncident = false,
    this.incidentIds,
  });

  // From JSON
  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryModel(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      startLocation: LocationData.fromJson(json['startLocation']),
      endLocation: json['endLocation'] != null
          ? LocationData.fromJson(json['endLocation'])
          : null,
      distance: json['distance']?.toDouble(),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      route: json['route'] != null
          ? (json['route'] as List)
                .map((e) => LocationData.fromJson(e))
                .toList()
          : [],
      avgSpeed: json['avgSpeed']?.toDouble(),
      maxSpeed: json['maxSpeed']?.toDouble(),
      hadIncident: json['hadIncident'] ?? false,
      incidentIds: json['incidentIds'] != null
          ? List<String>.from(json['incidentIds'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation?.toJson(),
      'distance': distance,
      'duration': duration?.inSeconds,
      'route': route.map((e) => e.toJson()).toList(),
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'hadIncident': hadIncident,
      'incidentIds': incidentIds,
    };
  }

  // Is ride active
  bool get isActive {
    return endTime == null;
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return '-';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Get formatted distance
  String get formattedDistance {
    if (distance == null) return '-';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)} m';
    }
    return '${distance!.toStringAsFixed(2)} km';
  }

  // Copy with method
  RideHistoryModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    LocationData? startLocation,
    LocationData? endLocation,
    double? distance,
    Duration? duration,
    List<LocationData>? route,
    double? avgSpeed,
    double? maxSpeed,
    bool? hadIncident,
    List<String>? incidentIds,
  }) {
    return RideHistoryModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      hadIncident: hadIncident ?? this.hadIncident,
      incidentIds: incidentIds ?? this.incidentIds,
    );
  }

  @override
  String toString() {
    return 'RideHistoryModel(id: $id, start: $startTime, active: $isActive)';
  }
}
