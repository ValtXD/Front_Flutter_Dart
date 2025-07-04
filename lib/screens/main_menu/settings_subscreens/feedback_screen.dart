// lib/screens/main_menu/settings_subscreens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // NOVO: Import do Provider para usar ApiService
import 'package:funfono1/api/api_service.dart'; // NOVO: Import do ApiService
// Removido import de url_launcher, pois não será mais usado diretamente

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  double _rating = 3.0; // Avaliação inicial de 3 estrelas
  bool _isSending = false; // Estado para controlar o envio

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_isSending) return; // Evita múltiplos cliques

    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty && _rating == 0.0) { // Garante que algo seja enviado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite seu feedback ou avalie o aplicativo.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando feedback...')),
    );

    final apiService = Provider.of<ApiService>(context, listen: false);
    final bool success = await apiService.sendFeedback(feedbackText, _rating.round());

    setState(() {
      _isSending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado! Seu feedback foi enviado com sucesso.')),
      );
      _feedbackController.clear();
      setState(() {
        _rating = 3.0; // Resetar avaliação
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao enviar feedback. Tente novamente mais tarde.')),
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
              divisions: 4,
              label: _rating.round().toString(),
              onChanged: _isSending ? null : (double value) { // Desabilita slider durante envio
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
              enabled: !_isSending, // Desabilita campo durante envio
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
                onPressed: _isSending ? null : _submitFeedback, // Desabilita botão durante envio
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white) // Mostra progresso
                    : const Text('Enviar Feedback', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}