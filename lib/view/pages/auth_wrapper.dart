import 'package:app_delivery/controller/auth_controller.dart';
import 'package:app_delivery/controller/firestore_controller.dart';
import 'package:app_delivery/model/user_model.dart';
import 'package:app_delivery/view/pages/client_page.dart';
import 'package:app_delivery/view/pages/deliveryman_page.dart';
import 'package:app_delivery/view/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  final AuthController _authController = AuthController();
  final FirestoreController _firestoreController = FirestoreController();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authController.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: _firestoreController.getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Determinar la página según el rol del usuario
              if (userSnapshot.hasData) {
                final userRole = userSnapshot.data!.role;

                if (userRole == 'client') {
                  return const ClientPage();
                } else if (userRole == 'deliveryman') {
                  return const DeliverymanPage();
                }
              }

              // Si no hay datos o hay un error, volver al login
              return const LoginPage();
            },
          );
        }

        // Usuario no autenticado
        return const LoginPage();
      },
    );
  }
}
