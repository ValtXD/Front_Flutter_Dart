// lib/screens/mini_games/quick_word_game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/models/game_result.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';
import 'package:funfono1/screens/mini_games/quick_word_game_play_screen.dart'; // NOVO IMPORT para a tela de jogo
import 'package:funfono1/screens/mini_games/game_score_details_modal.dart'; // NOVO IMPORT para o modal de detalhes

class QuickWordGameScreen extends StatefulWidget {
  const QuickWordGameScreen({super.key});

  @override
  State<QuickWordGameScreen> createState() => _QuickWordGameScreenState();
}

class _QuickWordGameScreenState extends State<QuickWordGameScreen> {
  User? _currentUser;
  bool _isLoading = true;
  List<GameResult> _gameHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndGameHistory();
  }

  Future<void> _loadCurrentUserAndGameHistory() async {
    _currentUser = await AuthStateService().getLoggedInUser();
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não logado. Faça login novamente.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
    await _fetchGameHistory();
  }

  Future<void> _fetchGameHistory() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _gameHistory = await Provider.of<ApiService>(context, listen: false)
          .getQuickWordGameHistory(_currentUser!.id);
      // Ordenar por data de criação, do mais recente para o mais antigo
      _gameHistory.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    } catch (e) {
      print('Erro ao carregar histórico do jogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar histórico do jogo.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGameResult(int resultId) async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este resultado do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && _currentUser != null) {
      setState(() {
        _isLoading = true;
      });
      final success = await Provider.of<ApiService>(context, listen: false)
          .deleteQuickWordGameResult(_currentUser!.id, resultId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resultado excluído com sucesso!')),
          );
          await _fetchGameHistory(); // Recarrega o histórico após exclusão
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao excluir resultado.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showScoreDetailsModal(GameResult result) {
    final hasWords = result.correctWords.isNotEmpty || result.incorrectWords.isNotEmpty;

    if (!hasWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este jogo não possui detalhes de palavras')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => GameScoreDetailsModal(gameResult: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Palavra Rápida')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Palavra Rápida')),
        body: const Center(
          child: Text('Por favor, faça login para jogar.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foguete da Pronúncia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão Start
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Navega para a tela do jogo e espera o resultado
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuickWordGamePlayScreen(
                        userId: _currentUser!.id,
                      ),
                    ),
                  );
                  // Se o resultado for 'true' (vindo do botão "Voltar para o Início"), recarrega o histórico
                  if (result == true) {
                    await _fetchGameHistory(); // Use await para garantir que o histórico seja carregado antes de setState
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Cor verde para Start
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(40),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Descrição do Jogo
            const Text(
              'Descrição:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Neste mini-game, você terá que pronunciar a palavra que aparece na tela ao completar os 100 pontos, desviar e atirar nos obstáculos. Acerte para pontuar! Tente acertar o máximo de palavras para conseguir prosseguir nessa aventura espacial.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Histórico de Pontuações
            const Text(
              'Histórico:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (_gameHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Nenhum resultado de jogo ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gameHistory.length,
                itemBuilder: (context, index) {
                  final result = _gameHistory[index];
                  final hasWords = result.correctWords.isNotEmpty || result.incorrectWords.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        'Pontuação: ${result.score}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Data: ${result.createdAt?.day}/${result.createdAt?.month}/${result.createdAt?.year}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasWords) // Mostra ícone de info apenas se tiver palavras
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.blue),
                              onPressed: () => _showScoreDetailsModal(result),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteGameResult(result.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }
}