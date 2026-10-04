// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔥 Pour l'émulateur ANDROID
  static const String baseUrl = 'http://10.0.2.2:8000';

  // 🔥 Pour le simulateur iOS
  // static const String baseUrl = 'http://127.0.0.1:8000';

  // 🔥 Pour un appareil PHYSIQUE (remplace par ton IP)
  //static const String baseUrl = 'http://192.168.1.77:8000';

  // 🔥 Inscription
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String whatsapp,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'whatsapp': whatsapp,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur : $e');
    }
  }

  // 🔥 Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erreur lors de la connexion');
      }
    } catch (e) {
      throw Exception('Erreur : $e');
    }
  }

  // 🔥 Analyser un message
  static Future<Map<String, dynamic>> analyserMessage(String texte) async {
    final url = Uri.parse('$baseUrl/analyser');

    try {
      final reponse = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'texte': texte}),
          )
          .timeout(const Duration(seconds: 15));

      if (reponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(reponse.bodyBytes),
        );
        final reponseAmicale =
            data['reponse_amicale'] ?? data['intention']?['reponse_amicale'];
        return {
          'intention': data['intention'] ?? {},
          'prestataires': data['prestataires'] ?? [],
          'reponse_amicale': reponseAmicale,
        };
      } else {
        throw Exception("Erreur backend : ${reponse.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur : $e");
    }
  }
}
