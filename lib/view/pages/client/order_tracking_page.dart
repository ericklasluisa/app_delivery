import 'dart:async';
import 'package:app_delivery/controller/database_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/model/location_model.dart';
import 'package:app_delivery/service/map_service.dart'; // Importar nuevo servicio
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Importar flutter_map
import 'package:latlong2/latlong.dart'; // Importar latlong2
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingPage extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingPage({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final DatabaseController _databaseController = DatabaseController();
  final MapController _mapController =
      MapController(); // Controlador de flutter_map

  bool _isLoading = true;
  bool _hasLocation = false;
  LocationModel? _lastLocation;

  // Posiciones para el mapa
  LatLng _deliveryPosition = LatLng(0, 0);
  LatLng _destinationPosition = LatLng(0, 0); // Posición estimada del destino

  // Colores para los marcadores
  final Color _deliveryColor = Colors.blue;
  final Color _destinationColor = Colors.red;

  // Lista de puntos para la ruta
  List<LatLng> _routePoints = [];

  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _setupLocationListener();

    // Definir una ubicación inicial aproximada basada en la dirección
    // En una implementación real, usarías geocodificación para convertir direcciones en coordenadas
    _destinationPosition = LatLng(0.0, 0.0);
  }

  void _setupLocationListener() {
    // Escuchar actualizaciones de ubicación del repartidor
    _locationSubscription = _databaseController
        .getLocationUpdatesStream(widget.order.id)
        .listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Convertir a Map<String, dynamic>
        final Map<String, dynamic> locationData = {};
        data.forEach((key, value) {
          locationData[key.toString()] = value;
        });

        final location = LocationModel.fromMap(locationData);

        setState(() {
          _lastLocation = location;
          _isLoading = false;
          _hasLocation = true;
          _deliveryPosition = LatLng(location.latitude, location.longitude);

          // Actualizar la ruta
          _updateRoute();
        });

        // Actualizar la posición del mapa
        _mapController.move(_deliveryPosition, 15);
      } else {
        setState(() {
          _isLoading = false;
          _hasLocation = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error en stream de ubicación: $e');
      setState(() {
        _isLoading = false;
        _hasLocation = false;
      });
    });
  }

  void _updateRoute() {
    if (_lastLocation == null) return;

    // Añadir el punto actual a la ruta
    _routePoints.add(_deliveryPosition);

    // Si hay más de un punto, podemos mostrar una línea
    if (_routePoints.length > 1) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _openMapApp() async {
    if (_lastLocation == null) return;

    // Crear URL para abrir la aplicación de mapas predeterminada
    final url =
        'https://www.openstreetmap.org/?mlat=${_lastLocation!.latitude}&mlon=${_lastLocation!.longitude}#map=15/${_lastLocation!.latitude}/${_lastLocation!.longitude}';

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el mapa')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Mapa con dos marcadores y una ruta
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _hasLocation ? _deliveryPosition : LatLng(0, 0),
              initialZoom: 15,
            ),
            children: [
              // Capa de azulejos de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_delivery',
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
              ),

              // Capa de polilíneas (ruta)
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Capa de marcadores
              MarkerLayer(
                markers: [
                  if (_hasLocation)
                    // Marcador del repartidor
                    Marker(
                      point: _deliveryPosition,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _deliveryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const Text(
                            'Repartidor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Marcador del destino
                  Marker(
                    point: _destinationPosition,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _destinationColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const Text(
                          'Destino',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Panel de estado
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pedido #${widget.order.id.substring(0, 6)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('Dirección: ${widget.order.address}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _hasLocation ? Icons.location_on : Icons.location_off,
                        color: _hasLocation ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasLocation
                            ? 'Repartidor en camino'
                            : 'Esperando la ubicación del repartidor',
                        style: TextStyle(
                          color: _hasLocation ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_lastLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Última actualización: ${DateTime.now().difference(_lastLocation!.timestamp).inMinutes} min atrás'),
                  ],
                ],
              ),
            ),
          ),

          // Indicador de carga
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMapApp,
        icon: const Icon(Icons.directions),
        label: const Text('Ver en App de Mapas'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
