import 'package:app_delivery/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Guardar datos de usuario
  Future<void> saveUserData(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  // Obtener datos de un usuario
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Actualizar el rol de un usuario
  Future<void> updateUserRole(String userId, String newRole) async {
    await _usersCollection.doc(userId).update({'role': newRole});
  }
}
