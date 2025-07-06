// lib/screens/main_menu/daily_word_practice_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/daily_word_attempt.dart';

class DailyWordPracticeScreen extends StatefulWidget {
  final String word; // A palavra a ser praticada
  final String userId; // Recebe o ID do usuário

  const DailyWordPracticeScreen({super.key, required this.word, required this.userId});

  @override
  State<DailyWordPracticeScreen> createState() => _DailyWordPracticeScreenState();
}

class _DailyWordPracticeScreenState extends State<DailyWordPracticeScreen> {
  late AudioRecorder _audioRecorder;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isEvaluating = false;
  String _feedbackMessage = 'Pressione o botão para começar a pronunciar.';
  Color _feedbackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndEvaluate();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone necessária para gravar.')),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    _recordedFilePath = '${directory.path}/daily_word_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: _recordedFilePath!,
      );
      setState(() {
        _isRecording = true;
        _feedbackMessage = 'Gravando... Pronuncie a palavra!';
        _feedbackColor = Colors.black;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar gravação: $e')),
      );
    }
  }

  Future<void> _stopRecordingAndEvaluate() async {
    if (!await _audioRecorder.isRecording()) return;

    setState(() {
      _isRecording = false;
      _isEvaluating = true;
      _feedbackMessage = 'Avaliando pronúncia...';
      _feedbackColor = Colors.grey;
    });

    try {
      final path = await _audioRecorder.stop();
      _recordedFilePath = path;

      if (_recordedFilePath != null && widget.word.isNotEmpty) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final audioFile = File(_recordedFilePath!);
        final bytes = await audioFile.readAsBytes();
        final base64Audio = base64Encode(bytes);

        // Chamar o NOVO endpoint de avaliação de pronúncia para Palavras Diárias
        final evaluationResult = await apiService.evaluateDailyWordPronunciation(
          widget.userId,
          widget.word,
          base64Audio,
        );

        if (evaluationResult != null) {
          final bool correct = evaluationResult['correto'] ?? false;
          final String feedback = evaluationResult['mensagem'] ?? 'Sem feedback.';
          final String transcription = evaluationResult['transcricao_servico_externo'] ?? 'N/A';

          setState(() {
            _feedbackMessage = feedback;
            _feedbackColor = correct ? Colors.green : Colors.red;
          });

          // NOVO: Salvar o resultado no backend para o histórico de palavras diárias
          final bool saveSuccess = await apiService.saveDailyWordAttempt(
            userId: widget.userId,
            word: widget.word,
            userTranscription: transcription,
            isCorrect: correct,
            tip: feedback, // Usando o feedback da IA como dica
          );

          if (mounted) {
            if (saveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Resultado salvo: ${correct ? "Correta" : "Incorreta"}!')),
              );
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Falha ao salvar resultado da prática diária.')),
              );
              Navigator.of(context).pop(false);
            }
          }
        } else {
          setState(() {
            _feedbackMessage = 'Erro ao avaliar pronúncia.';
            _feedbackColor = Colors.red;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao avaliar pronúncia.')),
          );
          Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Erro: $e';
        _feedbackColor = Colors.red;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na avaliação/salvamento: $e')),
      );
      Navigator.of(context).pop(false);
    } finally {
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratique a Pronúncia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pronuncie a palavra:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                widget.word,
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isEvaluating ? null : _toggleRecording,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  child: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: _feedbackColor),
              ),
              const SizedBox(height: 20),
              if (_isEvaluating) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}