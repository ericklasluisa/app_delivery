import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String clientId;
  final String? deliverymanId;
  final String address;
  final String description;
  final double totalPrice;
  final String status; // pending, assigned, in_progress, delivered, canceled
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.clientId,
    this.deliverymanId,
    required this.address,
    required this.description,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      clientId: map['clientId'] ?? '',
      deliverymanId: map['deliverymanId'],
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      deliveredAt: map['deliveredAt'] != null
          ? _parseDeliveredAt(map['deliveredAt'])
          : null,
    );
  }

  // Método auxiliar para manejar diferentes tipos de datos para deliveredAt
  static DateTime _parseDeliveredAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      // Intentar parsear como fecha ISO
      try {
        return DateTime.parse(value);
      } catch (_) {
        // Si falla, intentar convertir a int (asumiendo que es una cadena de milisegundos)
        try {
          return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
        } catch (_) {
          // Si todo falla, devolver la fecha actual
          return DateTime.now();
        }
      }
    }
    // Por defecto, devolver la fecha actual
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'deliverymanId': deliverymanId,
      'address': address,
      'description': description,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  // Para Realtime Database (que no soporta Timestamp)
  Map<String, dynamic> toRTDBMap() {
    return {
      'id': id,
      'clientId': clientId,
      'deliverymanId': deliverymanId,
      'address': address,
      'description': description,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
    };
  }

  // Crear una copia del objeto con algunos campos modificados
  OrderModel copyWith({
    String? id,
    String? clientId,
    String? deliverymanId,
    String? address,
    String? description,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      deliverymanId: deliverymanId ?? this.deliverymanId,
      address: address ?? this.address,
      description: description ?? this.description,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
