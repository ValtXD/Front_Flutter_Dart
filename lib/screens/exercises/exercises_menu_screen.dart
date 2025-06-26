import 'package:flutter/material.dart';
import 'package:funfono1/screens/exercises/speech_exercise_screen.dart'; // Tela de Exercício de Fala
import 'package:funfono1/screens/exercises/sounds_exercise_selection_screen.dart'; // Tela de Seleção de Sons

class ExercisesMenuScreen extends StatelessWidget {
  const ExercisesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercícios'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildExerciseOption(
              context,
              'Exercícios de Fala',
              Icons.record_voice_over,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpeechExerciseScreen()),
                );
              },
            ),
            const SizedBox(height: 30),
            _buildExerciseOption(
              context,
              'Exercícios de Sons',
              Icons.volume_up,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SoundsExerciseSelectionScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseOption(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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