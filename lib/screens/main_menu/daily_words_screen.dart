// lib/screens/main_menu/daily_words_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';
import 'package:funfono1/models/questionnaire.dart'; // Importa DailyWordAttempt de questionnaire.dart
import 'package:fl_chart/fl_chart.dart';

// Import para a tela de prática da palavra diária
import 'package:funfono1/screens/main_menu/daily_word_practice_screen.dart';
import 'package:funfono1/models/daily_word_attempt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyWordsScreen extends StatefulWidget {
  const DailyWordsScreen({super.key});

  @override
  State<DailyWordsScreen> createState() => _DailyWordsScreenState();
}

class _DailyWordsScreenState extends State<DailyWordsScreen> {
  User? _currentUser;
  List<String> _dailyWords = [];
  bool _isLoadingWords = true;
  bool _isLoadingHistory = true;

  List<DailyWordAttempt> _wordHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndWords();
  }

  Future<void> _loadCurrentUserAndWords() async {
    final user = await AuthStateService().getLoggedInUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não logado. Faça login novamente.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    _currentUser = user;
    await _loadDailyWords();
    await _loadWordHistory();
  }

  Future<void> _loadDailyWords() async {
    setState(() {
      _isLoadingWords = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    if (_currentUser == null) {
      _isLoadingWords = false;
      return;
    }

    // Lógica para verificar a data (00:00h) e resetar as palavras diárias
    // Armazenar a última data de geração em SharedPreferences
    final prefs = await SharedPreferences.getInstance(); // Precisará do SharedPreferences aqui também
    final String? lastGenDateStr = prefs.getString('lastDailyWordsGenerationDate');
    DateTime? lastGenDate;
    if (lastGenDateStr != null) {
      lastGenDate = DateTime.tryParse(lastGenDateStr);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Meia-noite de hoje

    bool shouldGenerateNewWords = false;
    if (_dailyWords.isEmpty) { // Se não tem palavras carregadas
      shouldGenerateNewWords = true;
    } else if (lastGenDate != null && lastGenDate.isBefore(today)) { // Se a última geração foi antes de hoje
      shouldGenerateNewWords = true;
    }

    if (shouldGenerateNewWords) {
      final generatedWords = await apiService.generateDailyWords(_currentUser!.id);
      if (mounted) {
        setState(() {
          _dailyWords = generatedWords ?? [];
          if (_dailyWords.isNotEmpty) {
            prefs.setString('lastDailyWordsGenerationDate', now.toIso8601String());
          }
        });
      }
    }

    setState(() {
      _isLoadingWords = false;
    });
  }

  Future<void> _loadWordHistory() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoadingHistory = true;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final history = await apiService.getDailyWordHistory(_currentUser!.id);
      if (mounted) {
        setState(() {
          _wordHistory = history ?? [];
        });
      }
    } catch (e) {
      print('Erro ao carregar histórico de palavras diárias: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar histórico de palavras diárias.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palavras Diárias'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingWords || _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pratique palavras diariamente de acordo com seu questionário:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _dailyWords.isEmpty
                ? const Center(
              child: Text(
                  'Não há palavras diárias para hoje. Tente novamente mais tarde ou verifique seu questionário.'),
            )
                : Column(
              children: _dailyWords.map((word) {
                final bool isPracticed = _wordHistory.any((attempt) =>
                attempt.word == word &&
                    attempt.createdAt?.day == DateTime.now().day &&
                    attempt.createdAt?.month == DateTime.now().month &&
                    attempt.createdAt?.year == DateTime.now().year);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: isPracticed ? null : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyWordPracticeScreen(
                            word: word,
                            userId: _currentUser!.id,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _loadDailyWords();
                        await _loadWordHistory();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPracticed ? Colors.grey : Colors.blue.shade100,
                      foregroundColor: isPracticed ? Colors.white : Colors.blue,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          word,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (isPracticed) const SizedBox(width: 10),
                        if (isPracticed) Icon(Icons.check_circle, color: Colors.green[800]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            const Text(
              'Histórico de Palavras Diárias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            SizedBox(
              height: 180,
              child: _buildDailyWordsChart(),
            ),
            const SizedBox(height: 20),

            _wordHistory.isEmpty
                ? const Center(child: Text('Nenhum histórico de palavras diárias ainda.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wordHistory.length,
              itemBuilder: (context, index) {
                final item = _wordHistory[index];
                final bool isCorrect = item.isCorrect;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  child: ListTile(
                    leading: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    title: Text('Palavra: ${item.word}'),
                    subtitle: Text(
                        'Status: ${isCorrect ? "Correta" : "Incorreta"} '
                            '(${item.createdAt?.toLocal().toString().split(' ')[0]})'),
                    trailing: isCorrect
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text('Detalhes de "${item.word}"'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Transcrição: ${item.userTranscription}'),
                                  Text('Dica da IA: ${item.tip}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
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

  Widget _buildDailyWordsChart() {
    if (_wordHistory.isEmpty) {
      return const Center(child: Text('Sem dados para o gráfico.'));
    }

    final int correctCount = _wordHistory.where((a) => a.isCorrect).length;
    final int incorrectCount = _wordHistory.where((a) => !a.isCorrect).length;
    final int totalCount = correctCount + incorrectCount;

    if (totalCount == 0) {
      return const Center(child: Text('Sem dados válidos para o gráfico.'));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            // Lógica para interação com o gráfico se necessário
          });
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: correctCount.toDouble(),
            title: '${(correctCount / totalCount * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: correctCount > 0 ? Text('$correctCount') : null,
            badgePositionPercentageOffset: 1.4,
          ),
          PieChartSectionData(
            color: Colors.red,
            value: incorrectCount.toDouble(),
            title: '${(incorrectCount / totalCount * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: incorrectCount > 0 ? Text('$incorrectCount') : null,
            badgePositionPercentageOffset: 1.4,
          ),
        ],
      ),
    );
  }
}