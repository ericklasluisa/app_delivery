import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapService {
  // Convertir la ubicación a LatLng para flutter_map
  static LatLng locationToLatLng(double latitude, double longitude) {
    return LatLng(latitude, longitude);
  }

  // Obtener mapa con marcador
  static FlutterMap getMapWithMarker({
    required LatLng position,
    required String markerTitle,
    required Color markerColor,
    double zoom = 15.0,
    List<Polyline>? polylines,
    MapController? mapController,
  }) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: position,
        initialZoom: zoom,
      ),
      children: [
        // Capa de azulejos (tiles) de OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app_delivery',
          // Atribución requerida por OSM
          additionalOptions: const {
            'attribution': '© OpenStreetMap contributors',
          },
        ),
        // Capa de marcadores
        MarkerLayer(
          markers: [
            Marker(
              point: position,
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Text(
                    markerTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Capa de polilíneas (rutas)
        if (polylines != null) PolylineLayer(polylines: polylines),
      ],
    );
  }

  // Función para obtener la ubicación actual
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están desactivados';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Los permisos de ubicación fueron denegados';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están permanentemente denegados';
    }

    return await Geolocator.getCurrentPosition();
  }
}
