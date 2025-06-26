// lib/services/auth_state_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:funfono1/models/user.dart';
import 'dart:convert'; // Para jsonEncode/decode

class AuthStateService {
  static const String _userKey = 'loggedInUser';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}