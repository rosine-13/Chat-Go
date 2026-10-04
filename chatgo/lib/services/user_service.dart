// lib/services/user_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // ============================================================
  // CLÉS DE STOCKAGE
  // ============================================================

  static const String _keyFirstName = 'user_first_name';
  static const String _keyLastName = 'user_last_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserWhatsapp = 'user_whatsapp';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastLogin = 'last_login';
  static const String _keyIsNewUser = 'is_new_user';        // 🔥 NOUVEAU
  static const String _keyIsFirstLogin = 'is_first_login';  // 🔥 NOUVEAU

  // ============================================================
  // SAUVEGARDER L'UTILISATEUR
  // ============================================================

  static Future<void> saveUser({
    required String firstName,
    required String lastName,
    required String email,
    required String whatsapp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserWhatsapp, whatsapp);
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyLastLogin, DateTime.now().toIso8601String());
  }

  // ============================================================
  // METTRE À JOUR SANS TOUCHER À lastLogin
  // ============================================================

  static Future<void> updateUserWithoutLogin({
    required String firstName,
    required String lastName,
    required String email,
    required String whatsapp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserWhatsapp, whatsapp);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // ============================================================
  // 🔥 INDICATEURS POUR LES MESSAGES DE BIENVENUE
  // ============================================================

  static Future<void> setNewUser(bool isNew) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsNewUser, isNew);
  }

  static Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsNewUser) ?? false;
  }

  static Future<void> setFirstLogin(bool isFirst) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstLogin, isFirst);
  }

  static Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLogin) ?? false;
  }

  // ============================================================
  // RÉCUPÉRER LES DONNÉES
  // ============================================================

  static Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFirstName);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString(_keyFirstName) ?? '';
    return firstName;
  }

  static Future<String?> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<String?> getUserWhatsapp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserWhatsapp);
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserWhatsapp);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyLastLogin);
    await prefs.remove(_keyIsNewUser);
    await prefs.remove(_keyIsFirstLogin);
  }
}