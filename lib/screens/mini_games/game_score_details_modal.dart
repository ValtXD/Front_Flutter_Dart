// lib/screens/mini_games/game_score_details_modal.dart

import 'package:flutter/material.dart';
import 'package:funfono1/models/game_result.dart'; // Import para GameResult

class GameScoreDetailsModal extends StatelessWidget {
  final GameResult gameResult;

  const GameScoreDetailsModal({super.key, required this.gameResult});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Acertos e Erros', // Título do modal
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              // Palavras Acertadas
              Text(
                'Acertos (${gameResult.correctWords.length}):',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 5),
              if (gameResult.correctWords.isEmpty)
                const Text('Nenhuma palavra acertada.', style: TextStyle(fontStyle: FontStyle.italic))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: gameResult.correctWords.map((word) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text('✅ ${word}', style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              // Palavras Erradas
              Text(
                'Erros (${gameResult.incorrectWords.length}):',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 5),
              if (gameResult.incorrectWords.isEmpty)
                const Text('Nenhuma palavra errada.', style: TextStyle(fontStyle: FontStyle.italic))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: gameResult.incorrectWords.map((word) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text('❌ ${word}', style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}