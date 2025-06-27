// lib/services/auth_state_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:funfono1/models/user.dart';
import 'dart:convert';

class AuthStateService {
  static const String _userKey = 'loggedInUser';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
    print('AuthStateService: Usuário salvo: ${user.fullName}'); // Log de depuração
  }

  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final user = User.fromJson(json.decode(userJson));
      print('AuthStateService: Usuário recuperado: ${user.fullName}'); // Log de depuração
      return user;
    }
    print('AuthStateService: Nenhum usuário logado encontrado.'); // Log de depuração
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    print('AuthStateService: Usuário deslogado.'); // Log de depuração
  }
}