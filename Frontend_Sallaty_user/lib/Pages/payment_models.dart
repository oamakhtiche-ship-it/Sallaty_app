import 'dart:math';
import 'package:flutter/foundation.dart';

// ─── PaymentMethod enum (mirrors backend enum exactly) ────────────
enum PaymentMethod { CARD, CASH }

// ─── PaymentStatus enum ────────────────────────────────────────────
enum PaymentStatus { SUCCESS, FAILED, PENDING }

// ─── PaymentRequestDto ─────────────────────────────────────────────
// Mirrors com.Sallaty.Sallaty.Dto.PaymentRequest
class PaymentRequestDto {
  final int ordreId;
  final PaymentMethod method;

  // Card-only fields (null when method == CASH)
  final String? cardNumber;
  final String? expiryDate;
  final String? cvv;
  final String? cardholderName;
  final bool saveCard;

  const PaymentRequestDto({
    required this.ordreId,
    required this.method,
    this.cardNumber,
    this.expiryDate,
    this.cvv,
    this.cardholderName,
    this.saveCard = false,
  });

  Map<String, dynamic> toJson() => {
        'ordreId': ordreId,
        'method': method.name,          // sends "CARD" or "CASH"
        if (cardNumber != null) 'cardNumber': cardNumber,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (cvv != null) 'cvv': cvv,
        if (cardholderName != null) 'cardholderName': cardholderName,
        'saveCard': saveCard,
      };
}

// ─── PaymentDto ────────────────────────────────────────────────────
// Mirrors com.Sallaty.Sallaty.Dto.PaymentDTO
class PaymentDto {
  final int id;
  final int ordreId;
  final int userId;
  final double amount;              // total charged to buyer
  final double transportCost;      // 450 DA fixed
  final double platformCommission; // totalPrice × 10 %
  final PaymentMethod method;
  final PaymentStatus status;
  final String createdAt;

  const PaymentDto({
    required this.id,
    required this.ordreId,
    required this.userId,
    required this.amount,
    required this.transportCost,
    required this.platformCommission,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    // Helper: parse BigDecimal (might arrive as int, double, or string)
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PaymentDto(
      id: json['id'] as int? ?? 0,
      ordreId: json['ordreId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      amount: _toDouble(json['amount']),
      transportCost: _toDouble(json['transportCost']),
      platformCommission: _toDouble(json['platformCommission']),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == (json['method'] as String? ?? 'CARD'),
        orElse: () => PaymentMethod.CARD,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'SUCCESS'),
        orElse: () => PaymentStatus.SUCCESS,
      ),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  /// subTotal = amount - transportCost - platformCommission
  double get subTotal => amount - transportCost - platformCommission;
}

// ─── PaymentResult (success/failure wrapper) ──────────────────────
class PaymentResult {
  final bool isSuccess;
  final PaymentDto? data;
  final String? errorMessage;

  const PaymentResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory PaymentResult.success(PaymentDto data) =>
      PaymentResult._(isSuccess: true, data: data);

  factory PaymentResult.failure(String message) =>
      PaymentResult._(isSuccess: false, errorMessage: message);
}