// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  // Locale padrão: Português do Brasil
  Locale _locale = const Locale('pt', 'BR');
  static const String _languageCodeKey = 'appLanguageCode';
  static const String _countryCodeKey = 'appCountryCode';

  LanguageProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey) ?? 'pt';
    final countryCode = prefs.getString(_countryCodeKey) ?? 'BR';
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return; // Evita atualizações desnecessárias
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, newLocale.languageCode);
    await prefs.setString(_countryCodeKey, newLocale.countryCode ?? ''); // countryCode pode ser nulo
    notifyListeners(); // Notifica os widgets que estão "ouvindo"
  }
}