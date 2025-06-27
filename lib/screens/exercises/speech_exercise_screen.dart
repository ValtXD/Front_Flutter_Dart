// lib/screens/exercises/speech_exercise_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:flutter_tts/flutter_tts.dart'; // <--- TTS

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

  String? _currentUserId;

  // Variáveis para o TTS
  late FlutterTts flutterTts;
  bool _isSpeaking = false; // Estado para controlar se o TTS está falando

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _initExercise();
    _initTts(); // <--- Inicializa o TTS
  }

  // Função para inicializar o TTS
  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("pt-BR"); // Define o idioma para português do Brasil
    flutterTts.setSpeechRate(0.5); // Velocidade da fala (ajuste conforme necessário)
    flutterTts.setVolume(1.0); // Volume (0.0 a 1.0)
    flutterTts.setPitch(1.0); // Tom da voz (0.5 a 2.0)

    // Listeners para o estado do TTS (opcional, mas bom para feedback)
    flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        print("TTS: Começou a falar.");
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        print("TTS: Terminou de falar.");
      });
    });

    flutterTts.setErrorHandler((message) {
      setState(() {
        _isSpeaking = false;
        print("TTS: Erro: $message");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reproduzir áudio: $message')),
      );
    });
  }

  // Função para reproduzir a frase usando TTS
  Future<void> _speakPhrase(String phrase) async {
    if (_isSpeaking) {
      await flutterTts.stop(); // Para a fala atual se estiver falando
    }
    // Verifica se a frase não é nula e não está vazia antes de falar
    if (phrase.isNotEmpty) {
      await flutterTts.speak(phrase);
    }
  }

  Future<void> _initExercise() async {
    await _requestPermissions();
    await _loadCurrentUser();
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
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _evaluationResult = null;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    final phrase = await apiService.generateSpeechPhrases();
    if (phrase != null && phrase.isNotEmpty) {
      _currentPhrase = phrase;
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
        // Interrompe o TTS se ele estiver falando antes de gravar
        if (_isSpeaking) {
          await flutterTts.stop();
        }
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
          if (result != null && result.containsKey('acertou')) {
            await apiService.recordAttempt(
              _currentUserId!,
              _currentPhrase!,
              'frase',
              result['acertou'] as bool,
            );
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
    flutterTts.stop(); // <--- Parar e liberar o TTS ao descartar o widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null && !_isLoading) {
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conteúdo de Pronúncia da Frase
            if (_evaluationResult == null)
              Column(
                children: [
                  const Text(
                    'Fale essa frase:',
                    style: TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentPhrase ?? 'Carregando frase...',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20), // Espaço antes do botão de ouvir

                  // Ícone para ouvir a frase
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _currentPhrase != null && !_isSpeaking
                          ? () => _speakPhrase(_currentPhrase!)
                          : null, // Desabilita se já estiver falando ou frase nula
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up, // Altera ícone se falando
                        color: _isSpeaking ? Colors.green : Colors.blue,
                      ),
                      label: Text(_isSpeaking ? 'Falando...' : 'Ouvir Frase', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
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
                ],
              ),
            // Conteúdo de Avaliação da Frase
            if (_evaluationResult != null)
              Column(
                children: [
                  (_evaluationResult!['acertou'] ?? false)
                      ? Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 60),
                      const SizedBox(height: 10),
                      const Text('Muito bem!',
                          style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  )
                      : Column(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 60),
                      const SizedBox(height: 10),
                      const Text('Incorreto.',
                          style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_evaluationResult!['avaliacao'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Avaliação: ${_evaluationResult!['avaliacao']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadNewPhrase,
                    child: Text(
                      ((_evaluationResult!['acertou'] ?? false)) ? 'Continuar' : 'Tentar outra frase',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}