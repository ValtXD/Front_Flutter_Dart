// lib/screens/main_menu/settings_subscreens/social_media_links_screen.dart
import 'package:flutter/material.dart';

class SocialMediaLinksScreen extends StatelessWidget {
  const SocialMediaLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes Sociais'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Links para Instagram, WhatsApp, etc. serão adicionados aqui.'),
      ),
    );
  }
}