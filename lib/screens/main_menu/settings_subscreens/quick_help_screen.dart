// lib/screens/main_menu/settings_subscreens/quick_help_screen.dart
import 'package:flutter/material.dart';

class QuickHelpScreen extends StatelessWidget {
  const QuickHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda Rápida / Tutorial'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Mini tutorial ou FAQs serão adicionados aqui.'),
      ),
    );
  }
}