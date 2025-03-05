import 'dart:async';
import 'package:app_delivery/controller/location_controller.dart';
import 'package:app_delivery/model/order_model.dart';
import 'package:app_delivery/model/location_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTrackingPage extends StatefulWidget {
  final OrderModel order;

  const LocationTrackingPage({Key? key, required this.order}) : super(key: key);

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  final LocationController _locationController = LocationController();

  // Inicializar el controlador correctamente
  final MapController _mapController = MapController();

  bool _isTracking = false;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String _statusMessage = "Inicializando...";
  String _errorMessage = "";

  // Usar una ubicación predeterminada diferente de (0,0) que probablemente está en medio del océano
  // Esta es una ubicación en Ecuador (Quito)
  LatLng _position = LatLng(-0.1807, -78.4678);

  // Color para el marcador
  final Color _markerColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndSetupLocation();
  }

  Future<void> _checkPermissionsAndSetupLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Verificando permisos...";
      });

      // Solicitar permisos de ubicación
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
      ].request();

      if (statuses[Permission.location]!.isGranted) {
        setState(() {
          _hasLocationPermission = true;
          _statusMessage = "Obteniendo ubicación...";
        });
        await _getCurrentLocation();
      } else {
        setState(() {
          _hasLocationPermission = false;
          _isLoading = false;
          _statusMessage = "Se requieren permisos de ubicación";
          _errorMessage =
              "Por favor, habilita los permisos de ubicación en la configuración";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error al verificar permisos";
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Obtener la posición actual directamente con Geolocator
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _position = LatLng(position.latitude, position.longitude);
          _isLoading = false;
          _statusMessage = "Listo para compartir ubicación";
        });

        // Mover el mapa a la posición actual después de que el mapa esté listo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Corregido: Verificar si el controlador está creado en lugar de usar .ready
            _mapController.move(_position, 15.0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error al obtener ubicación";
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // Detener seguimiento
      await _locationController.stopTracking();
      setState(() {
        _isTracking = false;
        _statusMessage = "Seguimiento detenido";
      });
    } else {
      // Iniciar seguimiento
      setState(() {
        _isLoading = true;
        _statusMessage = "Iniciando seguimiento...";
      });

      bool success = await _locationController.startTracking(widget.order.id);

      setState(() {
        _isTracking = success;
        _isLoading = false;
        _statusMessage = success
            ? "Compartiendo ubicación en tiempo real"
            : "Error al iniciar seguimiento";
      });
    }
  }

  @override
  void dispose() {
    _locationController.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Entrega'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Botón para recargar la ubicación
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionsAndSetupLocation,
            tooltip: 'Recargar ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa de OpenStreetMap con mejor configuración
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position,
              initialZoom: 15.0,
              backgroundColor: Colors
                  .grey.shade300, // Corregido: usar shade300 en lugar de [300]
              interactionOptions: const InteractionOptions(
                enableScrollWheel: true,
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Capa de azulejos con mejor configuración
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_delivery',
                tileProvider: NetworkTileProvider(),
                maxZoom: 19,
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
                // Añadir mensaje de carga y error
                errorImage: const NetworkImage(
                  'https://cdn.jsdelivr.net/gh/pointhi/leaflet-color-markers/img/marker-icon-red.png',
                ),
                // Eliminado el parámetro no compatible: evictErrorTileOnVersionChange
                retinaMode: true,
              ),
              // Capa de marcadores
              MarkerLayer(
                markers: [
                  Marker(
                    point: _position,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _markerColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const Text(
                          'Tu ubicación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white,
                          ),
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
                    'Pedido #${widget.order.id.substring(0, min(widget.order.id.length, 6))}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dirección: ${widget.order.address}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _hasLocationPermission
                            ? (_isTracking
                                ? Icons.location_on
                                : Icons.location_off)
                            : Icons.location_disabled,
                        color: _hasLocationPermission
                            ? (_isTracking ? Colors.green : Colors.red)
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      // Usar Flexible para evitar desbordamiento
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _hasLocationPermission
                                ? (_isTracking ? Colors.green : Colors.red)
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Mostrar mensaje de error si existe, pero limitado en tamaño
                  if (_errorMessage.isNotEmpty)
                    Flexible(
                      child: Text(
                        "Error: $_errorMessage",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Mostrar coordenadas actuales para depuración
                  if (_hasLocationPermission)
                    Text(
                      "Lat: ${_position.latitude.toStringAsFixed(5)}, Lng: ${_position.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Cargando mapa..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Mensaje cuando no hay permisos
          if (!_hasLocationPermission && !_isLoading)
            Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_disabled,
                          size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        "Se necesitan permisos de ubicación",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Por favor, concede permisos de ubicación para usar esta función",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkPermissionsAndSetupLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Solicitar permisos"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _hasLocationPermission
          ? FloatingActionButton.extended(
              onPressed: _toggleTracking,
              icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
              label: Text(_isTracking ? 'Detener' : 'Iniciar Seguimiento'),
              backgroundColor: _isTracking ? Colors.red : Colors.green,
            )
          : null,
    );
  }
}

// Función auxiliar para obtener el mínimo
int min(int a, int b) {
  return a < b ? a : b;
}
