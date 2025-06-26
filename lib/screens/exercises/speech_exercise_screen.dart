// lib/screens/exercises/speech_exercise_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart'; // Para obter o userId

class SpeechExerciseScreen extends StatefulWidget {
  const SpeechExerciseScreen({super.key});

  @override
  State<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends State<SpeechExerciseScreen> {
  late AudioRecorder _audioRecorder;
  String? _currentPhrase;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isLoading = false;
  Map<String, dynamic>? _evaluationResult;

  String? _currentUserId; // Para armazenar o ID do usuário logado

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _initExercise();
  }

  Future<void> _initExercise() async {
    await _requestPermissions();
    await _loadCurrentUser(); // Carrega o usuário antes de buscar frases
    await _loadNewPhrase();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStateService().getLoggedInUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.id;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Permissão de microfone concedida');
    } else {
      print('Permissão de microfone negada');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone necessária para o exercício!')),
      );
    }
  }

  Future<void> _loadNewPhrase() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado. Faça login novamente.')),
      );
      if (mounted) Navigator.pop(context); // Volta para a tela anterior
      return;
    }

    setState(() {
      _isLoading = true;
      _evaluationResult = null; // Limpa o resultado anterior
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final phrase = await apiService.generateSpeechPhrases(); // Agora retorna String?

    if (phrase != null && phrase.isNotEmpty) {
      _currentPhrase = phrase; // 'phrase' já é a String. Atribui diretamente.
    } else {
      _currentPhrase = 'Nenhuma frase para praticar.';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _recordedFilePath = '${directory.path}/audio_phrase_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath!,
        );
        setState(() {
          _isRecording = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone necessária para gravar.')),
        );
      }
    } catch (e) {
      print('Erro ao iniciar gravação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar gravação: $e')),
      );
    }
  }

  Future<void> _stopRecordingAndEvaluate() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _isLoading = true;
        });

        if (path != null && _currentUserId != null && _currentPhrase != null) {
          _recordedFilePath = path;
          print('Áudio gravado em: $_recordedFilePath');

          final audioFile = File(_recordedFilePath!);
          final bytes = await audioFile.readAsBytes();
          final base64Audio = base64Encode(bytes);

          final apiService = Provider.of<ApiService>(context, listen: false);
          final result = await apiService.evaluateSpeechPhrase(
            _currentUserId!,
            _currentPhrase!,
            base64Audio,
          );

          setState(() {
            _evaluationResult = result;
            _isLoading = false;
          });

          // Registrar tentativa no backend (usando a rota genérica de record_attempt)
          if (result != null && result.containsKey('acertou')) {
            await apiService.recordAttempt(
              _currentUserId!,
              _currentPhrase!, // 'palavra' recebe a frase original aqui
              'frase', // 'som' indica que é um exercício de frase
              result['acertou'] as bool,
            );
            // Isso fará o gráfico no MenuScreen atualizar
            Provider.of<ApiService>(context, listen: false).getAttemptHistory(_currentUserId!);
          }
        } else {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: dados insuficientes para avaliação ou gravação falhou.')),
          );
        }
      }
    } catch (e) {
      print('Erro ao parar gravação e avaliar frase: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao avaliar frase: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null && !_isLoading) {
      // Se não tem usuário logado e não está mais carregando, exibe uma mensagem
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(
          child: Text('Usuário não logado. Por favor, faça login novamente.', textAlign: TextAlign.center,),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercício de Fala (Modo Livre)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Fale essa frase:',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            Text(
              _currentPhrase ?? 'Carregando frase...',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isRecording ? _stopRecordingAndEvaluate : _startRecording,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                child: Icon(
                  _isRecording ? Icons.mic_off : Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isRecording ? 'Gravando...' : 'Toque para Falar',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            if (_evaluationResult != null) ...[
              _evaluationResult!['acertou'] as bool
                  ? Column(
                children: [
                  const Text('Muito bem!', style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadNewPhrase,
                    child: const Text('Continuar'),
                  ),
                ],
              )
                  : Column(
                children: [
                  const Text('Incorreto.', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_evaluationResult!['avaliacao'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Avaliação: ${_evaluationResult!['avaliacao']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadNewPhrase,
                    child: const Text('Tentar outra frase'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}