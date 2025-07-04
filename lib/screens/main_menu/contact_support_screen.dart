// lib/screens/main_menu/contact_support_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir links externos (e-mail, WhatsApp, Instagram)

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'aamon.ling00@gmail.com', // SEU E-MAIL DE SUPORTE AQUI
      queryParameters: {
        'subject': 'Suporte FunFono - Dúvida/Problema',
        'body': 'Olá equipe FunFono,\n\n',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo de e-mail.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir e-mail: $e')),
      );
    }
  }

  Future<void> _launchWhatsAppGroup(BuildContext context) async {
    const whatsappGroupUrl = 'https://chat.whatsapp.com/IJ5Q1ERlAcs3mmqKPXM88E?mode=r_t';
    final Uri whatsappLaunchUri = Uri.parse(whatsappGroupUrl);
    try {
      if (await canLaunchUrl(whatsappLaunchUri)) {
        await launchUrl(whatsappLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link do grupo do WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
      );
    }
  }

  Future<void> _launchInstagram(BuildContext context) async {
    const instagramUrl = 'https://www.instagram.com/funfono?igsh=Z2piYzJkYXIxbGVl';
    final Uri instagramUri = Uri.parse(instagramUrl);
    try {
      if (await canLaunchUrl(instagramUri)) {
        await launchUrl(instagramUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Instagram.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir Instagram: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contato / Suporte'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como podemos te ajudar?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Enviar um E-mail'),
                subtitle: const Text('aamon.ling00@gmail.com'),
                onTap: () => _launchEmail(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('Participar do Grupo no WhatsApp'),
                subtitle: const Text('Tire suas dúvidas e receba suporte direto.'),
                onTap: () => _launchWhatsAppGroup(context), // Chamada para o grupo do WhatsApp
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Você também pode nos encontrar no Instagram:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _launchInstagram(context),
                  child: Row(
                    children: [
                      // Certifique-se de ter um ícone do Instagram em seus assets (ex: assets/images/instagram_icon.png)
                      Image.asset('assets/images/instagram_icon.png', height: 30),
                      const SizedBox(width: 10),
                      const Text(
                        '@funfono',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Nosso horário de atendimento é de Segunda a Sexta, das 9h às 18h.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}