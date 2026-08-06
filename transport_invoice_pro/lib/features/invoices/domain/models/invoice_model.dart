import 'dart:convert';
import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  bank('Bank Transfer'),
  credit('Credit');

  final String displayName;
  const PaymentMethod(this.displayName);
}

enum PaymentStatus {
  paid('Paid', Colors.green),
  pending('Pending', Colors.orange),
  partial('Partial', Colors.blue);

  final String displayName;
  final Color color;
  const PaymentStatus(this.displayName, this.color);
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime tripDate;
  
  // Relations
  final String firmId;
  final String customerId;
  final String vehicleId;
  
  // Routing Details
  final String sourcePin;
  final String sourceCity;
  final String sourceDistrict;
  final String sourceState;
  final String sourceAddress;
  
  final String destinationPin;
  final String destCity;
  final String destDistrict;
  final String destState;
  final String destAddress;
  
  // Cargo Details (Optional)
  final String? materialDescription;
  final double? weight; // Tons
  
  // Financials
  final double transportationCharge;
  
  // Dynamic Custom Fields
  final Map<String, String> customPartiesFields;
  final Map<String, double> customChargesFields;
  
  final double totalAmount;
  
  // Payment
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  
  final String remarks;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.tripDate,
    required this.firmId,
    required this.customerId,
    required this.vehicleId,
    required this.sourcePin,
    required this.sourceCity,
    required this.sourceDistrict,
    required this.sourceState,
    required this.sourceAddress,
    required this.destinationPin,
    required this.destCity,
    required this.destDistrict,
    required this.destState,
    required this.destAddress,
    this.materialDescription,
    this.weight,
    this.transportationCharge = 0.0,
    required this.customPartiesFields,
    required this.customChargesFields,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.remarks = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'tripDate': tripDate.toIso8601String(),
      'firmId': firmId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'sourcePin': sourcePin,
      'sourceCity': sourceCity,
      'sourceDistrict': sourceDistrict,
      'sourceState': sourceState,
      'sourceAddress': sourceAddress,
      'destinationPin': destinationPin,
      'destCity': destCity,
      'destDistrict': destDistrict,
      'destState': destState,
      'destAddress': destAddress,
      'materialDescription': materialDescription,
      'weight': weight,
      'transportationCharge': transportationCharge,
      'customPartiesFields': customPartiesFields,
      'customChargesFields': customChargesFields,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'remarks': remarks,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse double map
    final chargesMap = <String, double>{};
    if (map['customChargesFields'] != null) {
      (map['customChargesFields'] as Map).forEach((k, v) {
        chargesMap[k.toString()] = (v as num).toDouble();
      });
    }

    final partiesMap = <String, String>{};
    if (map['customPartiesFields'] != null) {
      (map['customPartiesFields'] as Map).forEach((k, v) {
        partiesMap[k.toString()] = v.toString();
      });
    }

    return InvoiceModel(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      invoiceDate: DateTime.tryParse(map['invoiceDate'] ?? '') ?? DateTime.now(),
      tripDate: DateTime.tryParse(map['tripDate'] ?? '') ?? DateTime.now(),
      firmId: map['firmId'] ?? '',
      customerId: map['customerId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      sourcePin: map['sourcePin'] ?? '',
      sourceCity: map['sourceCity'] ?? '',
      sourceDistrict: map['sourceDistrict'] ?? '',
      sourceState: map['sourceState'] ?? '',
      sourceAddress: map['sourceAddress'] ?? '',
      destinationPin: map['destinationPin'] ?? '',
      destCity: map['destCity'] ?? '',
      destDistrict: map['destDistrict'] ?? '',
      destState: map['destState'] ?? '',
      destAddress: map['destAddress'] ?? '',
      materialDescription: map['materialDescription'],
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      transportationCharge: (map['transportationCharge'] ?? 0.0).toDouble(),
      customPartiesFields: partiesMap,
      customChargesFields: chargesMap,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      remarks: map['remarks'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceModel.fromJson(String source) => InvoiceModel.fromMap(json.decode(source));

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? tripDate,
    String? firmId,
    String? customerId,
    String? vehicleId,
    String? sourcePin,
    String? sourceCity,
    String? sourceDistrict,
    String? sourceState,
    String? sourceAddress,
    String? destinationPin,
    String? destCity,
    String? destDistrict,
    String? destState,
    String? destAddress,
    String? Bowls,
    String? materialDescription,
    double? weight,
    double? transportationCharge,
    Map<String, String>? customPartiesFields,
    Map<String, double>? customChargesFields,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? remarks,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      tripDate: tripDate ?? this.tripDate,
      firmId: firmId ?? this.firmId,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      sourcePin: sourcePin ?? this.sourcePin,
      sourceCity: sourceCity ?? this.sourceCity,
      sourceDistrict: sourceDistrict ?? this.sourceDistrict,
      sourceState: sourceState ?? this.sourceState,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      destinationPin: destinationPin ?? this.destinationPin,
      destCity: destCity ?? this.destCity,
      destDistrict: destDistrict ?? this.destDistrict,
      destState: destState ?? this.destState,
      destAddress: destAddress ?? this.destAddress,
      materialDescription: materialDescription ?? this.materialDescription,
      weight: weight ?? this.weight,
      transportationCharge: transportationCharge ?? this.transportationCharge,
      customPartiesFields: customPartiesFields ?? this.customPartiesFields,
      customChargesFields: customChargesFields ?? this.customChargesFields,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      remarks: remarks ?? this.remarks,
    );
  }
}
