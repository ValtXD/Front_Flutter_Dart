// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/screens/auth/registration_screen.dart';
import 'package:funfono1/screens/main_menu/menu_screen.dart';
import 'package:funfono1/screens/main_menu/questionnaire_screen.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart'; // Importe o modelo User para a simulação

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController(); // Alterado para fullName
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose(); // Dispose do novo controller
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final apiService = Provider.of<ApiService>(context, listen: false);

      // Chamada real à API com nome de usuário e senha
      final user = await apiService.loginUser(_fullNameController.text, _passwordController.text);

      if (user != null) {
        await AuthStateService().saveUser(user);

        // Verificar se o questionário já foi preenchido para este usuário
        final hasQuestionnaire = await apiService.checkUserQuestionnaireStatus(user.id);

        if (mounted) {
          if (hasQuestionnaire) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login realizado com sucesso!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login realizado. Por favor, preencha o questionário.')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
            );
          }
        }
      } else {
        // Exibir mensagem de erro se a autenticação falhar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciais inválidas. Verifique seu nome de usuário e senha.')),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock, size: 100, color: Colors.blue), // Ícone para login
                const SizedBox(height: 30),
                const Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController, // Alterado para _fullNameController
                  decoration: const InputDecoration(
                    labelText: 'Nome de Usuário', // Alterado o label
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person), // Ícone de pessoa
                  ),
                  keyboardType: TextInputType.text, // Tipo de teclado para texto
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome de usuário'; // Validação
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  child: const Text(
                    'Não tem uma conta? Cadastre-se aqui',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}