// lib/screens/main_menu/settings_subscreens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVO: Import para enviar e-mail

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  double _rating = 3.0; // Avaliação inicial de 3 estrelas

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // NOVO: Função para enviar o feedback por e-mail
  Future<void> _sendFeedbackEmail() async {
    final feedbackText = _feedbackController.text;
    final String subject = 'Feedback FunFono - Avaliação de ${_rating.round()} estrelas';
    final String body = 'Avaliação: ${_rating.round()} estrelas\n\nFeedback:\n$feedbackText';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'aamon.ling00@gmail.com', // E-MAIL DE SUPORTE PARA FEEDBACK
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obrigado pelo seu feedback! Abrindo aplicativo de e-mail.')),
        );
        _feedbackController.clear();
        setState(() {
          _rating = 3.0; // Resetar avaliação
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo de e-mail. Por favor, tente novamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar feedback: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sua opinião é importante para nós!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Por favor, avalie o aplicativo e deixe suas sugestões para melhorarmos.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Avaliação por estrelas
            const Text(
              'Avalie o FunFono:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 4, // 1, 2, 3, 4, 5 estrelas
              label: _rating.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return Icon(
                  index < _rating.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                );
              }),
            ),
            const SizedBox(height: 20),

            // Campo de texto para feedback
            const Text(
              'Seu feedback (opcional):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escreva seu feedback aqui...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _sendFeedbackEmail, // CHAMA A NOVA FUNÇÃO DE ENVIAR E-MAIL
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enviar Feedback', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}