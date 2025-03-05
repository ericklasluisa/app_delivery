import 'package:app_delivery/controller/order_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/view/pages/deliveryman/location_tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailDeliveryPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailDeliveryPage({super.key, required this.order});

  @override
  State<OrderDetailDeliveryPage> createState() =>
      _OrderDetailDeliveryPageState();
}

class _OrderDetailDeliveryPageState extends State<OrderDetailDeliveryPage> {
  final OrderController _orderController = OrderController();
  bool _isUpdating = false;
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
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

  String _getActionButtonText(String status) {
    switch (status) {
      case 'assigned':
        return 'Iniciar Entrega';
      case 'in_progress':
        return 'Marcar como Entregado';
      default:
        return '';
    }
  }

  Future<void> _updateStatus() async {
    String newStatus;

    if (_order.status == 'assigned') {
      newStatus = 'in_progress';
    } else if (_order.status == 'in_progress') {
      newStatus = 'delivered';
    } else {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _orderController.updateOrderStatus(_order.id, newStatus);

      // Actualizar el estado local
      setState(() {
        _order = _order.copyWith(status: newStatus);
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'delivered'
              ? 'Pedido marcado como entregado'
              : 'Pedido marcado como en camino'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método corregido para abrir el mapa
  Future<void> _openMap() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_order.address)}';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${_order.id.substring(0, 6)}'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del pedido
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping,
                            color: _getStatusColor(_order.status), size: 30),
                        const SizedBox(width: 15),
                        Text(
                          'Estado: ${_getStatusText(_order.status)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_order.status),
                          ),
                        ),
                      ],
                    ),
                    if (_order.status != 'delivered' &&
                        _order.status != 'canceled') ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(_order.status == 'assigned'
                                  ? Icons.delivery_dining
                                  : Icons.check_circle),
                          label: Text(_getActionButtonText(_order.status)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStatusColor(_order.status),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isUpdating ? null : _updateStatus,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nuevo botón para compartir ubicación
            if (_order.status == 'assigned' ||
                _order.status == 'in_progress') ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compartir Ubicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Comparte tu ubicación en tiempo real para que el cliente pueda seguir el estado de la entrega.',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on),
                          label: const Text('Compartir Ubicación'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LocationTrackingPage(order: _order),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Información del pedido
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('ID:', _order.id),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Fecha:',
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(_order.createdAt)),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Total:', '\$${_order.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dirección y detalles
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.deepPurple),
                        const SizedBox(width: 10),
                        const Text(
                          'Dirección de Entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: _openMap,
                          tooltip: 'Abrir en mapa',
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      _order.address,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Descripción del pedido
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    Text(
                      _order.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
