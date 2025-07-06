// lib/screens/main_menu/settings_subscreens/delete_account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _confirmAndDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão de Conta'),
          content: const Text(
              'Esta ação é irreversível e excluirá todos os seus dados. Deseja continuar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      print('DEBUG DELETE: Confirmação recebida. Iniciando exclusão...');
      await _deleteAccount();
    } else {
      print('DEBUG DELETE: Exclusão cancelada pelo usuário.');
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excluindo conta...')),
    );

    final loggedInUser = await AuthStateService().getLoggedInUser();
    if (loggedInUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Nenhum usuário logado para excluir.')),
        );
        setState(() {
          _isDeleting = false;
        });
        print('DEBUG DELETE: Erro - Nenhum usuário logado. Exclusão abortada.');
        return;
      }
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    print('DEBUG DELETE: Chamando API para excluir conta do userId: ${loggedInUser!.id}');
    final bool success = await apiService.deleteUserAccount(loggedInUser.id);

    if (mounted) {
      setState(() {
        _isDeleting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sua conta foi excluída com sucesso.')),
        );
        print('DEBUG DELETE: Conta excluída com sucesso na API. Tentando deslogar e navegar...');
        // Deslogar o usuário e navegar para a tela de boas-vindas/login
        await AuthStateService().logout();
        print('DEBUG DELETE: Usuário deslogado. Navegando para /welcome...');

        // Verifica se o widget ainda está no "árvore" antes de navegar
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
          print('DEBUG DELETE: Chamada de navegação para /welcome concluída.');
        } else {
          print('DEBUG DELETE: Widget não está montado. Navegação não pode ser feita.');
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao excluir conta. Tente novamente.')),
        );
        print('DEBUG DELETE: Falha ao excluir conta na API.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG DELETE: DeleteAccountScreen build chamado.'); // Para ver se está sendo reconstruída
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluir Conta'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Atenção!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ao excluir sua conta, todos os seus dados, incluindo histórico de exercícios, lembretes e questionários, serão permanentemente removidos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              _isDeleting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _confirmAndDeleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Excluir Minha Conta', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}