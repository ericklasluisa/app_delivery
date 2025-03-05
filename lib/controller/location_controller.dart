import 'dart:async';
import 'package:app_delivery/controller/database_controller.dart';
import 'package:app_delivery/model/location_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationController {
  final DatabaseController _databaseController = DatabaseController();
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  // Verificar permisos de ubicación - Método mejorado
  Future<bool> checkLocationPermission() async {
    // Primero verificamos si la localización está habilitada
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // En lugar de pedir permiso, mostrar diálogo para abrir configuración
      debugPrint('Los servicios de ubicación están deshabilitados.');
      return false;
    }

    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Los permisos de ubicación fueron denegados.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Los permisos de ubicación están denegados permanentemente.');
      // Deberíamos mostrar un diálogo informando al usuario que debe
      // habilitar los permisos desde la configuración
      return false;
    }

    // En Android 10+ necesitamos verificar el permiso de ubicación en segundo plano
    if (permission == LocationPermission.whileInUse) {
      try {
        // Para Android 10+ verificar si es necesario permiso en segundo plano
        await Permission.locationAlways.request();
      } catch (e) {
        // Algunos dispositivos pueden no soportar esta API
        debugPrint(
            'Error al solicitar permiso de ubicación en segundo plano: $e');
      }
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Iniciar seguimiento de ubicación para un pedido específico
  Future<bool> startTracking(String orderId) async {
    // Verificar permisos primero
    if (!await checkLocationPermission()) {
      return false;
    }

    // Detener cualquier seguimiento activo
    await stopTracking();

    _isTracking = true;

    // Iniciar el seguimiento con alta precisión
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualiza cada 10 metros
      ),
    ).listen((Position position) async {
      if (!_isTracking) return;

      final locationData = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
        timestamp: DateTime.now(),
      );

      // Actualizar la ubicación en la base de datos en tiempo real
      try {
        await _databaseController.updateDeliverymanLocation(
            orderId, locationData);
      } catch (e) {
        debugPrint('Error al actualizar ubicación: $e');
      }
    });

    return true;
  }

  // Detener el seguimiento de ubicación
  Future<void> stopTracking() async {
    _isTracking = false;
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
  }

  // Método mejorado de obtener ubicación actual
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Verificar permisos primero
      if (!await checkLocationPermission()) {
        return null;
      }

      // Intentar obtener la posición con timeouts adecuados
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw TimeoutException('No se pudo obtener la ubicación a tiempo'),
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error al obtener ubicación actual: $e');
      return null;
    }
  }

  // Verificar si el seguimiento está activo
  bool get isTracking => _isTracking;
}
