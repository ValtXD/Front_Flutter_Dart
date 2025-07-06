// lib/screens/main_menu/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';

// Imports para as telas que o menu principal acessa
import 'package:funfono1/screens/exercises/exercises_menu_screen.dart';
import 'package:funfono1/screens/main_menu/progress_screen.dart';
import 'package:funfono1/screens/main_menu/schedule_screen.dart';
import 'package:funfono1/screens/main_menu/assistant_bot_screen.dart';
import 'package:funfono1/screens/main_menu/pronunciation_tips_screen.dart';
import 'package:funfono1/screens/mini_games/mini_games_selection_screen.dart';

// NOVO: Imports para as novas telas do Drawer
import 'package:funfono1/screens/main_menu/about_screen.dart'; // Import para a tela "Sobre"
import 'package:funfono1/screens/main_menu/contact_support_screen.dart'; // Import para a tela "Contato / Suporte"
import 'package:funfono1/screens/main_menu/settings_screen.dart'; // Import para a tela "Configurações"

//NOVO
import 'package:funfono1/screens/main_menu/daily_words_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Widget> _menuScreens = {
    'Exercícios': const ExercisesMenuScreen(),
    'Progresso': const ProgressScreen(),
    'Cronograma': const ScheduleScreen(),
    'Dicas': PronunciationTipsScreen(),
    'Mini Games': const MiniGamesSelectionScreen(),
    'Assistente Bot': const AssistantBotScreen(),
    'Palavras Diárias': const DailyWordsScreen(),
  };
  List<String> _filteredMenuTitles = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _filteredMenuTitles = _menuScreens.keys.toList();
    _searchController.addListener(_filterMenuTitles);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMenuTitles);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStateService().getLoggedInUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _filterMenuTitles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMenuTitles = _menuScreens.keys.toList();
      } else {
        _filteredMenuTitles = _menuScreens.keys.where((title) {
          return title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Widget _buildMenuItemButton(BuildContext context, String title, IconData icon, Widget screen) {
    if (!_filteredMenuTitles.contains(title)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('FunFono'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,

        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentUser?.fullName ?? 'Usuário',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? 'email@exemplo.com',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Menu Principal'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())); // NOVO: Navega para a tela Sobre
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone), // NOVO: Ícone para Contato/Suporte
              title: const Text('Contato / Suporte'), // NOVO: Título
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactSupportScreen())); // NOVO: Navega para a tela Contato/Suporte
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); // NOVO: Navega para a tela Configurações
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                await AuthStateService().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
            ),
          ],
        ),
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

            // Barra de Pesquisa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // As Rows de botões existentes, agora usando _buildMenuItemButton
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuItemButton(context, 'Exercícios', Icons.assignment, const ExercisesMenuScreen()),
                _buildMenuItemButton(context, 'Progresso', Icons.trending_up, const ProgressScreen()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuItemButton(context, 'Cronograma', Icons.calendar_today, const ScheduleScreen()),
                _buildMenuItemButton(context, 'Dicas', Icons.lightbulb_outline, PronunciationTipsScreen()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuItemButton(context, 'Mini Games', Icons.gamepad_outlined, const MiniGamesSelectionScreen()),
                _buildMenuItemButton(context, 'Palavras Diárias', Icons.message, const DailyWordsScreen()),
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