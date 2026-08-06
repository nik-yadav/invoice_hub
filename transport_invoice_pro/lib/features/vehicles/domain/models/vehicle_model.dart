import 'dart:convert';
import 'package:flutter/material.dart';

enum VehicleStatus {
  available('Available', Colors.green),
  busy('Busy', Colors.orange),
  maintenance('Maintenance', Colors.red);

  final String displayName;
  final Color color;
  const VehicleStatus(this.displayName, this.color);
}

class VehicleModel {
  final String id;
  final String vehicleNumber;
  final String type; // e.g. Open Truck, Container, Trailer
  final double capacity; // in Tons
  final String driverName;
  final String driverPhone;
  final String insuranceNumber;
  final DateTime? fitnessExpiry;
  final VehicleStatus status;

  VehicleModel({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    required this.capacity,
    required this.driverName,
    required this.driverPhone,
    required this.insuranceNumber,
    this.fitnessExpiry,
    this.status = VehicleStatus.available,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'type': type,
      'capacity': capacity,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'insuranceNumber': insuranceNumber,
      'fitnessExpiry': fitnessExpiry?.toIso8601String(),
      'status': status.name,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      type: map['type'] ?? '',
      capacity: (map['capacity'] ?? 0.0).toDouble(),
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      insuranceNumber: map['insuranceNumber'] ?? '',
      fitnessExpiry: map['fitnessExpiry'] != null ? DateTime.tryParse(map['fitnessExpiry']) : null,
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VehicleStatus.available,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory VehicleModel.fromJson(String source) => VehicleModel.fromMap(json.decode(source));

  VehicleModel copyWith({
    String? id,
    String? vehicleNumber,
    String? type,
    double? capacity,
    String? driverName,
    String? driverPhone,
    String? insuranceNumber,
    DateTime? fitnessExpiry,
    VehicleStatus? status,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      fitnessExpiry: fitnessExpiry ?? this.fitnessExpiry,
      status: status ?? this.status,
    );
  }
}
