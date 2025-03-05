import 'package:app_delivery/controller/order_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/view/pages/deliveryman/order_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDeliveriesPage extends StatefulWidget {
  const MyDeliveriesPage({super.key});

  @override
  State<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<MyDeliveriesPage> {
  final OrderController _orderController = OrderController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _selectedStatus = 'all';
  bool _isUpdating = false;

  Stream<QuerySnapshot> _getOrdersStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }

    if (_selectedStatus == 'all') {
      return _orderController.getDeliverymanOrdersStream(_currentUser!.uid);
    } else {
      return _orderController.getDeliverymanOrdersByStatusStream(
          _currentUser!.uid, _selectedStatus);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    String newStatus;

    if (currentStatus == 'assigned') {
      newStatus = 'in_progress';
    } else if (currentStatus == 'in_progress') {
      newStatus = 'delivered';
    } else {
      return; // No se puede cambiar más allá de 'delivered'
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _orderController.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'delivered'
                ? 'Pedido marcado como entregado'
                : 'Pedido marcado como en camino'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(
        child: Text('No hay usuario autenticado'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entregas'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Asignados', 'assigned'),
                  const SizedBox(width: 8),
                  _filterChip('En camino', 'in_progress'),
                  const SizedBox(width: 8),
                  _filterChip('Entregados', 'delivered'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay entregas para mostrar'),
                  );
                }

                // Ordenar manualmente los documentos por fecha (más recientes primero)
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['createdAt'] as Timestamp).toDate();
                  final bTime = (bData['createdAt'] as Timestamp).toDate();
                  return bTime.compareTo(aTime); // Orden descendente
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final orderData = doc.data() as Map<String, dynamic>;
                    final order = OrderModel.fromMap(orderData, doc.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status),
                          child: Icon(
                            order.status == 'delivered'
                                ? Icons.check
                                : Icons.delivery_dining,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Pedido #${order.id.substring(0, 6)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dirección: ${order.address}'),
                            Text(
                                'Total: \$${order.totalPrice.toStringAsFixed(2)}'),
                            Text(
                              'Estado: ${_getStatusText(order.status)}',
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailDeliveryPage(order: order),
                            ),
                          );
                        },
                        trailing: order.status != 'delivered'
                            ? ElevatedButton(
                                onPressed: _isUpdating
                                    ? null
                                    : () => _updateOrderStatus(
                                        order.id, order.status),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _getStatusColor(order.status),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(order.status == 'assigned'
                                        ? 'Iniciar'
                                        : 'Entregar'),
                              )
                            : const Icon(Icons.check_circle,
                                color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepPurple.withOpacity(0.3),
      checkmarkColor: Colors.deepPurple,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }
}
