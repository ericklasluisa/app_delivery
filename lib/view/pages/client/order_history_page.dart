import 'package:app_delivery/controller/order_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/view/pages/client/order_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderController _orderController = OrderController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _selectedStatus = 'all';

  Stream<QuerySnapshot> _getOrdersStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }

    if (_selectedStatus == 'all') {
      return _orderController.getClientOrdersStream(_currentUser!.uid);
    } else {
      return _orderController.getClientOrdersByStatusStream(
          _currentUser!.uid, _selectedStatus);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Desconocido';
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
        title: const Text('Mis Pedidos'),
        backgroundColor: Colors.deepPurple,
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
                  _filterChip('Pendientes', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('Asignados', 'assigned'),
                  const SizedBox(width: 8),
                  _filterChip('En camino', 'in_progress'),
                  const SizedBox(width: 8),
                  _filterChip('Entregados', 'delivered'),
                  const SizedBox(width: 8),
                  _filterChip('Cancelados', 'canceled'),
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
                    child: Text('No hay pedidos para mostrar'),
                  );
                }

                // Ordenar manualmente si usas la opción 3
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
                          child: Text(
                            order.status.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                                  OrderDetailPage(order: order),
                            ),
                          );
                        },
                        trailing: order.status == 'pending'
                            ? IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () async {
                                  _showCancelConfirmationDialog(order.id);
                                },
                              )
                            : null,
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

  Future<void> _showCancelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Pedido'),
          content:
              const Text('¿Estás seguro de que deseas cancelar este pedido?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _orderController.cancelOrder(orderId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pedido cancelado con éxito'),
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
                }
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }
}
