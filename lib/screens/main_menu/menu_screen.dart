// lib/screens/main_menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:funfono1/screens/exercises/exercises_menu_screen.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';
import 'package:funfono1/screens/main_menu/progress_screen.dart'; // NOVO IMPORT

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

                // Botão Progresso (ATUALIZADO PARA NAVEGAR PARA ProgressScreen)
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
          ],
        ),
      ),
    );
  }
}