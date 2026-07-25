import 'package:google_maps_flutter/google_maps_flutter.dart';

enum VehicleStatus { moving, stopped, offline }

extension VehicleStatusX on VehicleStatus {
  String get label {
    switch (this) {
      case VehicleStatus.moving:
        return 'Moving';
      case VehicleStatus.stopped:
        return 'Stopped';
      case VehicleStatus.offline:
        return 'Offline';
    }
  }
}


class VehicleModel {
  final String id;
  final String driverName;
  final LatLng position;
  final double speedKmph;
  final VehicleStatus status;
  final DateTime lastUpdated;

  const VehicleModel({
    required this.id,
    required this.driverName,
    required this.position,
    required this.speedKmph,
    required this.status,
    required this.lastUpdated,
  });

  VehicleModel copyWith({
    LatLng? position,
    double? speedKmph,
    VehicleStatus? status,
    DateTime? lastUpdated,
  }) {
    return VehicleModel(
      id: id,
      driverName: driverName,
      position: position ?? this.position,
      speedKmph: speedKmph ?? this.speedKmph,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
