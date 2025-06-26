import 'package:flutter/material.dart';
import 'package:funfono1/screens/exercises/exercises_menu_screen.dart'; // Próxima tela

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Olá, Andrew!', // TODO: Substituir por nome do usuário logado
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Ícone do Prontuário - MVP: apenas um placeholder
            GestureDetector(
              onTap: () {
                // TODO: Implementar navegação para a tela de Prontuário
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prontuário (MVP: Em breve!)')),
                );
              },
              child: Column(
                children: [
                  Icon(Icons.folder_shared, size: 80, color: Colors.blue),
                  SizedBox(height: 8),
                  Text('Prontuário', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExercisesMenuScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Ir para Exercícios',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}