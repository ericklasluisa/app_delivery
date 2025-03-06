import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;


class AccessToken {
  Future<String> getAccessToken() async {
    final String jsonString =
        await rootBundle.loadString('assets/credentials.json');

    final serviceAccountJson = jsonDecode(jsonString);

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();

    return credentials.accessToken.data;
  }
}

class Constants {
  static const String BASE_URL =
      'https://fcm.googleapis.com/v1/projects/app-banco-flutter/messages:send';
}

class EnviarNotificacionService {
  Future<bool> pushNotifications({
    required String title,
    required String body,
    required String token,
  }) async {
    Map<String, dynamic> payload = {
      "message": {
        "token": token,
        "notification": {
          "title": title,
          "body": body,
        },
      },
    };
    String dataNotifications = jsonEncode(payload);

    final String keyServer = await AccessToken().getAccessToken();

    var response = await http.post(
      Uri.parse(Constants.BASE_URL),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $keyServer',
      },
      body: dataNotifications,
    );
    debugPrint(response.body.toString());
    if (response.statusCode != 200) {
      return false;
    }
    return true;
  }
}
