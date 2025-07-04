// lib/screens/main_menu/settings_subscreens/language_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/providers/language_provider.dart'; // Import do provedor

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assiste ao LanguageProvider para reconstruir quando o locale muda
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Idioma'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          RadioListTile<Locale>(
            title: const Text('Português (Brasil)'),
            value: const Locale('pt', 'BR'),
            groupValue: languageProvider.locale, // Usa o locale do provedor
            onChanged: (Locale? value) {
              if (value != null) {
                languageProvider.setLocale(value); // Chama o método do provedor para mudar o locale
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Idioma alterado para Português (Brasil).')),
                );
              }
            },
          ),
          RadioListTile<Locale>(
            title: const Text('English (US)'),
            value: const Locale('en', 'US'),
            groupValue: languageProvider.locale, // Usa o locale do provedor
            onChanged: (Locale? value) {
              if (value != null) {
                languageProvider.setLocale(value); // Chama o método do provedor para mudar o locale
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language changed to English (US).')),
                );
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Atenção: A mudança de idioma afeta a exibição de datas, números e textos padrões do Flutter. '
                  'Para traduzir todos os textos do aplicativo, é necessário implementar a internacionalização completa (arquivos .arb).',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}