// lib/screens/main_menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import necessário para usar Provider
import 'package:funfono1/services/auth_state_service.dart'; // Mantido, assumindo que AuthStateService é seu provedor de usuário
import 'package:funfono1/models/user.dart'; // Mantido para o modelo de usuário

// Imports para as telas que o menu principal acessa
import 'package:funfono1/screens/exercises/exercises_menu_screen.dart';
import 'package:funfono1/screens/main_menu/progress_screen.dart';
import 'package:funfono1/screens/main_menu/schedule_screen.dart';
import 'package:funfono1/screens/main_menu/assistant_bot_screen.dart'; // Import da tela do bot
import 'package:funfono1/screens/main_menu/pronunciation_tips_screen.dart'; // Import da tela de dicas
import 'package:funfono1/screens/mini_games/mini_games_selection_screen.dart'; // NOVO IMPORT para a tela de seleção de mini games

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // Usando AuthStateService para carregar o usuário
    final user = await AuthStateService().getLoggedInUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Menu Principal'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Olá, ${_currentUser?.fullName ?? 'Usuário'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Bem Vindo ao FunFono',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botão Exercícios
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExercisesMenuScreen()),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment, size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text('Exercícios',
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),

                // Botão Progresso
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProgressScreen()),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.trending_up, size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text('Progresso',
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botão Cronograma
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_today, size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text('Cronograma',
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),

                // Botão Dicas
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PronunciationTipsScreen()),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lightbulb_outline, size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text('Dicas',
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // NOVO Botão Mini Games
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MiniGamesSelectionScreen()),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.gamepad_outlined, size: 50, color: Colors.blue), // Ícone de gamepad
                        SizedBox(height: 10),
                        Text('Mini Games',
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // FloatingActionButton para o Assistente Bot no canto inferior direito
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssistantBotScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: Image.asset(
          'assets/images/bot_fono.png',
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}