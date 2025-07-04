// lib/screens/main_menu/settings_subscreens/feedback_screen.dart
import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulário simples para o usuário avaliar será adicionado aqui.'),
      ),
    );
  }
}