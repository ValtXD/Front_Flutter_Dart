import 'package:flutter/material.dart';
import 'package:funfono1/screens/exercises/exercises_menu_screen.dart';
import 'package:funfono1/services/auth_state_service.dart'; // Importar AuthStateService
import 'package:funfono1/models/user.dart'; // Importar o modelo User

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? _currentUser; // Variável para armazenar o usuário logado

  @override
  void initState() {
    super.initState();
    print('MenuScreen: initState - Carregando usuário...'); // Log de depuração
    _loadCurrentUser(); // Carregar o usuário ao inicializar a tela
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStateService().getLoggedInUser();
    if (mounted) { // Verifica se o widget ainda está montado antes de chamar setState
      setState(() {
        _currentUser = user;
        print('MenuScreen: Usuário carregado: ${_currentUser?.fullName}'); // Log de depuração
      });
    } else {
      print('MenuScreen: Widget não montado, não é possível chamar setState.'); // Log de depuração
    }
  }

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
            // Exibe "Olá, [Nome do Usuário]!" ou "Olá, Usuário!" se o nome não for encontrado
            Text(
              'Olá, ${_currentUser?.fullName ?? 'Usuário'}!', // <--- Confirmação da mudança aqui
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              child: const Column(
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