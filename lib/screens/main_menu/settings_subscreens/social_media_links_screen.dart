// lib/screens/main_menu/settings_subscreens/social_media_links_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir links externos

class SocialMediaLinksScreen extends StatelessWidget {
  const SocialMediaLinksScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url, String appName) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication); // Tenta abrir no app nativo
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link do $appName.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir $appName: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes Sociais'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conecte-se conosco nas redes sociais!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Image.asset('assets/images/instagram_icon.png', height: 30), // Ícone do Instagram
                title: const Text('Instagram'),
                subtitle: const Text('@funfono'),
                onTap: () => _launchUrl(context, 'https://www.instagram.com/funfono?igsh=Z2piYzJkYXIxbGVl', 'Instagram'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Image.asset('assets/images/whatsapp_icon.png', height: 30), // Ícone do WhatsApp
                title: const Text('WhatsApp'),
                subtitle: const Text('Participe do nosso grupo para tirar dúvidas'),
                onTap: () => _launchUrl(context, 'https://chat.whatsapp.com/IJ5Q1ERlAcs3mmqKPXM88E?mode=r_t', 'WhatsApp'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Image.asset('assets/images/facebook_icon.png', height: 30),
                //leading: const Icon(Icons.facebook, color: Colors.blue), // Ícone genérico do Facebook
                title: const Text('Facebook'),
                subtitle: const Text('/FunFonoOficial (em breve!)'),
                onTap: () => _launchUrl(context, 'https://www.facebook.com/FunFonoOficial', 'Facebook'), // Placeholder
              ),
            ),
            // Adicione mais redes sociais aqui, se tiver ícones e links
          ],
        ),
      ),
    );
  }
}