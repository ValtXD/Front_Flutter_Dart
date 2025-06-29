// lib/screens/exercises/speech_exercise_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  late FlutterTts flutterTts;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _initExercise();
    _initTts();
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("pt-BR");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = true;
        print("TTS: Começou a falar.");
      });
    });
    flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        print("TTS: Terminou de falar.");
      });
    });
    flutterTts.setErrorHandler((message) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        print("TTS: Erro: $message");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reproduzir áudio: $message')),
      );
    });
  }

  Future<void> _speakPhrase(String phrase) async {
    if (_isSpeaking) {
      await flutterTts.stop();
    }
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
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
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

  // Inicia a gravação de áudio (SEM STT nativo)
  void _startRecording() async {
    if (_isSpeaking) {
      await flutterTts.stop();
    }
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone não concedida para gravar.')),
      );
      return;
    }

    setState(() {});
    final directory = await getApplicationDocumentsDirectory();
    _recordedFilePath = '${directory.path}/audio_phrase_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: _recordedFilePath!,
    );
    setState(() { _isRecording = true; });
  }

  // Para a gravação de áudio E envia para avaliação
  Future<void> _stopRecordingAndEvaluate() async {
    if (await _audioRecorder.isRecording()) {
      final path = await _audioRecorder.stop();
      _recordedFilePath = path;
    }
    if (mounted) setState(() { _isRecording = false; });

    if (mounted) setState(() { _isLoading = true; });
    if (_currentUserId != null && _currentPhrase != null) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      String? base64Audio;
      try {
        if (_recordedFilePath != null) {
          final audioFile = File(_recordedFilePath!);
          if (await audioFile.exists()) {
            final bytes = await audioFile.readAsBytes();
            base64Audio = base64Encode(bytes);
          } else {
            print('AVISO: Arquivo de áudio gravado não existe em $_recordedFilePath');
          }
        }
      } catch (e) {
        print('ERRO ao ler arquivo de áudio gravado: $e');
        base64Audio = null;
      }

      final result = await apiService.evaluateSpeechPhrase(
        _currentUserId!,
        _currentPhrase!,
        base64Audio ?? '',
      );
      if (mounted) setState(() {
        _evaluationResult = result;
        _isLoading = false;
      });
      // REMOVIDA: A chamada a apiService.recordAttempt() é redundante aqui
      // pois evaluateSpeechPhrase já persiste os dados detalhados.
      /*
      if (result != null && result.containsKey('acertou')) {
        await apiService.recordAttempt(
          _currentUserId!,
          _currentPhrase!,
          'frase',
          result['acertou'] as bool,
        );
        if (mounted) {
          // Provider.of<ApiService>(context, listen: false).getAttemptHistory(_currentUserId!); // Removida a chamada desnecessária
        }
      }
      */
    } else {
      if (mounted) setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: dados insuficientes para avaliação ou gravação falhou.')),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    flutterTts.stop();
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
      body: _isLoading && _evaluationResult == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _currentPhrase != null && !_isSpeaking
                          ? () => _speakPhrase(_currentPhrase!)
                          : null,
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up,
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
                    _isRecording
                        ? 'Gravando...'
                        : 'Toque para Falar',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
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
                      if (_evaluationResult!['transcricao_assemblyai'] != null &&
                          _evaluationResult!['transcricao_assemblyai'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Transcrição: "${_evaluationResult!['transcricao_assemblyai']}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ),
                      if (_evaluationResult!['avaliacao'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${_evaluationResult!['avaliacao']}',
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