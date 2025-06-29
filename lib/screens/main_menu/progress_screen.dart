// lib/screens/main_menu/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/models/attempt_history.dart'; // NOVO IMPORT
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';
import 'package:fl_chart/fl_chart.dart'; // Adicione ao pubspec.yaml

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  User? _currentUser;
  bool _isLoading = true;
  List<AttemptHistory> _fullHistory = [];
  List<AttemptHistory> _filteredHistory = [];
  bool _showSpeechExercises = false; // true para Fala, false para Sons

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndHistory();
  }

  Future<void> _loadCurrentUserAndHistory() async {
    _currentUser = await AuthStateService().getLoggedInUser();
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não logado. Por favor, faça login novamente.')),
        );
        // Considere navegar para a tela de login se o usuário não estiver logado
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser != null) {
        _fullHistory = await Provider.of<ApiService>(context, listen: false).getAttemptHistory(_currentUser!.id);
        _filterHistory(); // Filtra o histórico após carregar
      }
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar histórico. Tente novamente.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterHistory() {
    setState(() {
      _filteredHistory = _fullHistory.where((attempt) {
        return _showSpeechExercises
            ? attempt.type == 'frase'
            : attempt.type == 'som';
      }).toList();
    });
  }

  Future<void> _deleteAttempt(int id, String type) async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta tentativa do histórico?'),
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
          .deleteAttempt(_currentUser!.id, id, type);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tentativa excluída com sucesso!')),
          );
          await _fetchHistory(); // Recarrega o histórico após exclusão
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao excluir tentativa.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAttemptDetailsModal(AttemptHistory attempt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Tentativa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Palavra/Frase Original: ${attempt.original}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Transcrição: ${attempt.transcribed ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Dica da IA: ${attempt.feedback ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _fullHistory.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progresso')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progresso')),
        body: const Center(
          child: Text('Por favor, faça login para ver seu progresso.'),
        ),
      );
    }

    final int correctCount = _filteredHistory.where((a) => a.correct).length;
    final int incorrectCount = _filteredHistory.where((a) => !a.correct).length;
    final int totalAttempts = _filteredHistory.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Exercícios de Sons',
                  style: TextStyle(
                    fontWeight: _showSpeechExercises ? FontWeight.normal : FontWeight.bold,
                    color: _showSpeechExercises ? Colors.grey : Colors.blue,
                  ),
                ),
                Switch(
                  value: _showSpeechExercises,
                  onChanged: (bool value) {
                    setState(() {
                      _showSpeechExercises = value;
                      _filterHistory(); // Re-filtra o histórico
                    });
                  },
                ),
                Text(
                  'Exercícios de Fala',
                  style: TextStyle(
                    fontWeight: _showSpeechExercises ? FontWeight.bold : FontWeight.normal,
                    color: _showSpeechExercises ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Gráfico de Progresso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: totalAttempts > 0
                  ? PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: correctCount.toDouble(),
                      title: '${(correctCount / totalAttempts * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: incorrectCount.toDouble(),
                      title: '${(incorrectCount / totalAttempts * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              )
                  : const Center(child: Text('Nenhum dado para o gráfico ainda.')),
            ),
            const SizedBox(height: 30),
            const Text(
              'Histórico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            if (_filteredHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Nenhuma tentativa registrada para este tipo de exercício.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredHistory.length,
                itemBuilder: (context, index) {
                  final attempt = _filteredHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      tileColor: attempt.correct ? Colors.green.shade50 : Colors.red.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        attempt.correct ? Icons.check_circle : Icons.cancel,
                        color: attempt.correct ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      title: Text(
                        attempt.correct ? 'Correto: ${attempt.original}' : 'Incorreto: ${attempt.original}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: attempt.correct ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      subtitle: Text(
                        'Em ${attempt.createdAt.day}/${attempt.createdAt.month}/${attempt.createdAt.year} ${attempt.createdAt.hour}:${attempt.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!attempt.correct) // Apenas mostra o botão de detalhes para incorretas
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.blue),
                              onPressed: () => _showAttemptDetailsModal(attempt),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteAttempt(attempt.id, attempt.type),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}