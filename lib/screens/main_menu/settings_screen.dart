// lib/screens/main_menu/settings_screen.dart

import 'package:flutter/material.dart';

// NOVO: Imports para as sub-telas de configuração
import 'package:funfono1/screens/main_menu/settings_subscreens/language_settings_screen.dart';
import 'package:funfono1/screens/main_menu/settings_subscreens/theme_settings_screen.dart';
import 'package:funfono1/screens/main_menu/settings_subscreens/quick_help_screen.dart';
import 'package:funfono1/screens/main_menu/settings_subscreens/social_media_links_screen.dart';
import 'package:funfono1/screens/main_menu/settings_subscreens/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Item de Configuração: Idioma
          /*
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: const Text('Selecione o idioma do aplicativo'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
              );
            },
          ),
          const Divider(),
*/
          // Item de Configuração: Tema
          /*
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            subtitle: const Text('Ajuste para modo claro ou escuro'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()),
              );
            },
          ),
          const Divider(),
*/
          // Item de Configuração: Ajuda Rápida
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda Rápida'),
            subtitle: const Text('Mini tutorial do app'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuickHelpScreen()),
              );
            },
          ),
          const Divider(),

          // Item de Configuração: Redes Sociais
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Redes Sociais'),
            subtitle: const Text('Links para Instagram, WhatsApp, etc.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SocialMediaLinksScreen()),
              );
            },
          ),
          const Divider(),

          // Item de Configuração: Feedback
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Feedback'),
            subtitle: const Text('Envie sua avaliação e sugestões'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}