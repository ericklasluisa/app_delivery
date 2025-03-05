import 'package:app_delivery/controller/order_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/view/pages/deliveryman/order_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controller/database_controller.dart';

class PendingOrdersPage extends StatefulWidget {
  const PendingOrdersPage({super.key});

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  final DatabaseController _databaseController = DatabaseController();
  final OrderController _orderController = OrderController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Pendientes'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pedidos disponibles para entrega',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _databaseController.getPendingOrdersStream(),
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

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text('No hay pedidos pendientes'),
                  );
                }

                // Convertir el objeto dinámico a un Map
                Map<dynamic, dynamic> ordersMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                // Convertir el Map a una lista de OrderModel
                List<OrderModel> orders = [];

                ordersMap.forEach((key, value) {
                  if (value is Map) {
                    Map<String, dynamic> orderMap = {};
                    value.forEach((k, v) {
                      orderMap[k.toString()] = v;
                    });

                    try {
                      OrderModel order =
                          OrderModel.fromMap(orderMap, key.toString());
                      orders.add(order);
                    } catch (e) {
                      print('Error parsing order: $e');
                    }
                  }
                });

                // Ordenar por fecha de creación (más reciente primero)
                orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No hay pedidos pendientes'),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.pending, color: Colors.white),
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
                              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _assignOrder(order.id, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Aceptar'),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailDeliveryPage(order: order),
                            ),
                          );
                        },
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

  Future<void> _assignOrder(String orderId, BuildContext context) async {
    // Capturar el ScaffoldMessengerState al inicio del método
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No hay usuario autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _orderController.assignOrder(orderId, _currentUser!.uid);

      // Usar la referencia guardada en lugar de obtenerla nuevamente
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('¡Pedido aceptado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        // Eliminar la navegación automática que causa el problema
        // Future.delayed(const Duration(milliseconds: 500), () {
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });

        // En su lugar, simplemente actualizar la interfaz para que el pedido desaparezca
        // La UI se actualizará automáticamente cuando la base de datos en tiempo real se actualice
      }
    } catch (e) {
      // Usar la referencia guardada en lugar de obtenerla nuevamente
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
