import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/model/location_model.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseController {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Publicar un nuevo pedido en tiempo real
  Future<void> publishNewOrder(OrderModel order) async {
    await _database.child('orders').child(order.id).set(order.toRTDBMap());
  }

  // Actualizar estado de un pedido en tiempo real
  Future<void> updateOrderStatus(
      String orderId, String status, String? deliverymanId) async {
    final Map<String, dynamic> updates = {
      'status': status,
    };

    if (deliverymanId != null) {
      updates['deliverymanId'] = deliverymanId;
    }

    await _database.child('orders').child(orderId).update(updates);
  }

  // Obtener stream de pedidos pendientes (para repartidores)
  Stream<DatabaseEvent> getPendingOrdersStream() {
    return _database
        .child('orders')
        .orderByChild('status')
        .equalTo('pending')
        .onValue;
  }

  // Obtener pedidos asignados a un repartidor específico
  Stream<DatabaseEvent> getDeliverymanOrdersStream(String deliverymanId) {
    return _database
        .child('orders')
        .orderByChild('deliverymanId')
        .equalTo(deliverymanId)
        .onValue;
  }

  // Eliminar un pedido de la base de datos en tiempo real
  // (cuando se completa o cancela)
  Future<void> removeOrder(String orderId) async {
    await _database.child('orders').child(orderId).remove();
  }

  // Métodos para gestionar ubicaciones en tiempo real

  // Actualizar la ubicación del repartidor
  Future<void> updateDeliverymanLocation(
      String orderId, LocationModel location) async {
    await _database.child('locations').child(orderId).set(location.toMap());
  }

  // Obtener stream de actualizaciones de ubicación para un pedido específico
  Stream<DatabaseEvent> getLocationUpdatesStream(String orderId) {
    return _database.child('locations').child(orderId).onValue;
  }

  // Detener el seguimiento de ubicación (cuando el pedido se entrega o cancela)
  Future<void> removeLocationTracking(String orderId) async {
    await _database.child('locations').child(orderId).remove();
  }
}
