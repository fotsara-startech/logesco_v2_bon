import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// Paiement pour un service additionnel (dépannage, formation,
/// installation réseau, etc.), toujours rattaché à un client existant.
@JsonSerializable()
class Payment {
  final String id;
  final String clientId;
  final String description;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.clientId,
    required this.description,
    required this.amount,
    this.currency = 'XAF',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  Payment copyWith({
    String? id,
    String? clientId,
    String? description,
    double? amount,
    String? currency,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, clientId: $clientId, description: $description, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
