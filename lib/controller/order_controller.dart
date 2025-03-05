import 'package:app_delivery/controller/database_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseController _databaseController = DatabaseController();
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Crear nuevo pedido
  Future<OrderModel?> createOrder({
    required String address,
    required String description,
    required double totalPrice,
  }) async {
    try {
      if (_currentUser == null) {
        throw 'Usuario no autenticado';
      }

      // Crear documento en Firestore
      final docRef = _ordersCollection.doc();

      final newOrder = OrderModel(
        id: docRef.id,
        clientId: _currentUser!.uid,
        address: address,
        description: description,
        totalPrice: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Guardar en Firestore para historial
      await docRef.set(newOrder.toMap());

      // Publicar en Realtime Database para notificaciones
      await _databaseController.publishNewOrder(newOrder);

      return newOrder;
    } catch (e) {
      debugPrint('Error al crear pedido: $e');
      return null;
    }
  }

  // Obtener pedidos del cliente
  Stream<QuerySnapshot> getClientOrdersStream(String clientId) {
    // Versión que requiere menos índices (pero menos eficiente)
    return _ordersCollection.where('clientId', isEqualTo: clientId).snapshots();

    // Versión original que requiere índice compuesto
    // return _ordersCollection
    //    .where('clientId', isEqualTo: clientId)
    //    .orderBy('createdAt', descending: true)
    //    .snapshots();
  }

  // Obtener pedidos del cliente por estado
  Stream<QuerySnapshot> getClientOrdersByStatusStream(
      String clientId, String status) {
    // Versión que requiere menos índices (pero menos eficiente)
    return _ordersCollection
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: status)
        .snapshots();

    // Versión original que requiere índice compuesto
    // return _ordersCollection
    //    .where('clientId', isEqualTo: clientId)
    //    .where('status', isEqualTo: status)
    //    .orderBy('createdAt', descending: true)
    //    .snapshots();
  }

  // Obtener pedidos asignados a un repartidor
  Stream<QuerySnapshot> getDeliverymanOrdersStream(String deliverymanId) {
    // Versión que requiere menos índices
    return _ordersCollection
        .where('deliverymanId', isEqualTo: deliverymanId)
        .snapshots();

    // Versión original que requiere índice compuesto
    // return _ordersCollection
    //     .where('deliverymanId', isEqualTo: deliverymanId)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
  }

  // Obtener pedidos de un repartidor por estado
  Stream<QuerySnapshot> getDeliverymanOrdersByStatusStream(
      String deliverymanId, String status) {
    // Versión que requiere menos índices
    return _ordersCollection
        .where('deliverymanId', isEqualTo: deliverymanId)
        .where('status', isEqualTo: status)
        .snapshots();

    // Versión original que requiere índice compuesto
    // return _ordersCollection
    //     .where('deliverymanId', isEqualTo: deliverymanId)
    //     .where('status', isEqualTo: status)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
  }

  // Asignar pedido a repartidor
  Future<void> assignOrder(String orderId, String deliverymanId) async {
    try {
      // Actualizar en Firestore
      await _ordersCollection.doc(orderId).update({
        'deliverymanId': deliverymanId,
        'status': 'assigned',
      });

      // Actualizar en Realtime Database
      await _databaseController.updateOrderStatus(
          orderId, 'assigned', deliverymanId);
    } catch (e) {
      debugPrint('Error al asignar pedido: $e');
      throw e;
    }
  }

  // Actualizar estado de pedido
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updates = {'status': status};

      // Si se marca como entregado, registrar fecha
      if (status == 'delivered') {
        // Usar un Timestamp en lugar de una cadena
        updates['deliveredAt'] = Timestamp.now().toString();
      }

      // Actualizar en Firestore
      await _ordersCollection.doc(orderId).update(updates);

      // Si está completado o cancelado, eliminar de Realtime (pero mantener en Firestore)
      if (status == 'delivered' || status == 'canceled') {
        try {
          // Detener tracking de ubicación primero
          await _databaseController.removeLocationTracking(orderId);
          // Luego eliminar el pedido de la base en tiempo real
          await _databaseController.removeOrder(orderId);
        } catch (e) {
          debugPrint('Error al limpiar datos en tiempo real: $e');
          // Continuar a pesar del error para no bloquear la actualización de estado
        }
      } else {
        // Actualizar estado en Realtime
        await _databaseController.updateOrderStatus(orderId, status, null);
      }
    } catch (e) {
      debugPrint('Error al actualizar estado del pedido: $e');
      throw e;
    }
  }

  // Cancelar pedido
  Future<void> cancelOrder(String orderId) async {
    try {
      // Un cliente solo puede cancelar sus pedidos pendientes
      if (_currentUser == null) {
        throw 'Usuario no autenticado';
      }

      final doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) {
        throw 'El pedido no existe';
      }

      final orderData = doc.data() as Map<String, dynamic>;
      if (orderData['clientId'] != _currentUser!.uid) {
        throw 'No tienes permisos para cancelar este pedido';
      }

      if (orderData['status'] != 'pending') {
        throw 'Solo se pueden cancelar pedidos pendientes';
      }

      await updateOrderStatus(orderId, 'canceled');
    } catch (e) {
      debugPrint('Error al cancelar pedido: $e');
      throw e;
    }
  }
}
