// lib/screens/main_menu/settings_subscreens/theme_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/providers/theme_provider.dart'; // Import do provedor

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assiste ao ThemeProvider para reconstruir quando o tema muda
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Tema'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Tema do Sistema'),
            subtitle: const Text('Usa o tema claro ou escuro do seu dispositivo'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode, // Usa o tema do provedor
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value); // Chama o método do provedor para mudar o tema
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema "Sistema" selecionado.')),
                );
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Tema Claro'),
            subtitle: const Text('Define o aplicativo para usar o tema claro'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode, // Usa o tema do provedor
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value); // Chama o método do provedor para mudar o tema
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema "Claro" selecionado.')),
                );
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Tema Escuro'),
            subtitle: const Text('Define o aplicativo para usar o tema escuro'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode, // Usa o tema do provedor
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value); // Chama o método do provedor para mudar o tema
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema "Escuro" selecionado.')),
                );
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Atenção: A mudança de tema será aplicada em todo o aplicativo e será salva para a próxima vez que você abrir o app.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}