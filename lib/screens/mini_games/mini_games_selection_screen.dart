// lib/screens/mini_games/mini_games_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:funfono1/screens/mini_games/quick_word_game_screen.dart'; // NOVO IMPORT

class MiniGamesSelectionScreen extends StatelessWidget {
  const MiniGamesSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGameOption(
              context,
              'Foguete da Pronúncia',
              Icons.rocket, // Ícone de relógio para palavra rápida
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuickWordGameScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildGameOption(
              context,
              'EM BREVE',
              Icons.hourglass_empty,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Este jogo estará disponível em breve!')),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildGameOption(
              context,
              'EM BREVE',
              Icons.hourglass_empty,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Este jogo estará disponível em breve!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOption(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return Card(
      margin: EdgeInsets.zero, // Remove margem padrão do Card
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 60, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}