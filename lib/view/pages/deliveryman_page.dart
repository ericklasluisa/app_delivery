import 'package:app_delivery/controller/auth_controller.dart';
import 'package:flutter/material.dart';

class DeliverymanPage extends StatelessWidget {
  const DeliverymanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Repartidor'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authController.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delivery_dining,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido, Repartidor!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestiona tus entregas desde aquí',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment),
              label: const Text('Pedidos Pendientes'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                // Navegación a la lista de pedidos pendientes
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.checklist),
              label: const Text('Entregas Completadas'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                // Navegación al historial de entregas
              },
            ),
          ],
        ),
      ),
    );
  }
}
