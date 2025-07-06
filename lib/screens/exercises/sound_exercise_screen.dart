// lib/screens/exercises/sound_exercise_screen.dart

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

class SoundExerciseScreen extends StatefulWidget {
  final List<String> selectedSounds;
  final String? selectedCategory;
  const SoundExerciseScreen({
    super.key,
    required this.selectedSounds,
    this.selectedCategory,
  });
  @override
  State<SoundExerciseScreen> createState() => _SoundExerciseScreenState();
}

class _SoundExerciseScreenState extends State<SoundExerciseScreen> {
  late AudioRecorder _audioRecorder;
  String? _currentWord;
  String? _currentSound;
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

  Future<void> _speakWord(String word) async {
    if (_isSpeaking) {
      await flutterTts.stop();
    }
    if (word.isNotEmpty) {
      await flutterTts.speak(word);
    }
  }

  Future<void> _initExercise() async {
    await _requestPermissions();
    await _loadCurrentUser();
    await _loadNewWord();
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

  Future<void> _loadNewWord() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado. Redirecionando...')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _evaluationResult = null;
      _currentWord = null;
      _currentSound = null;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final words = await apiService.getSoundsWords(
        [],
        widget.selectedSounds,
      );
      if (mounted) {
        if (words != null && words.isNotEmpty) {
          final randomWord = words[0];
          setState(() {
            _currentWord = randomWord['palavra'];
            _currentSound = randomWord['som'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _currentWord = 'Nenhuma palavra encontrada.';
            _currentSound = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma palavra encontrada para os sons selecionados.')),
          );
        }
      }
    } catch (e) {
      print('Erro ao carregar nova palavra: $e');
      if (mounted) {
        setState(() {
          _currentWord = 'Erro ao carregar palavra.';
          _currentSound = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar palavras. Verifique sua conexão.')),
        );
      }
    }
  }

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

  Future<void> _stopRecordingAndEvaluate() async {
    if (await _audioRecorder.isRecording()) {
      final path = await _audioRecorder.stop();
      _recordedFilePath = path;
    }
    if (mounted) setState(() { _isRecording = false; });
    if (mounted) setState(() { _isLoading = true; });

    if (_currentUserId != null && _currentWord != null && _currentSound != null) {
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

      final result = await apiService.evaluatePronunciation(
        _currentUserId!,
        _currentWord!,
        _currentSound!,
        base64Audio ?? '',
      );
      if (mounted) setState(() {
        _evaluationResult = result;
        _isLoading = false;
      });
      // REMOVIDA: A chamada a apiService.recordAttempt() é redundante aqui
      // pois evaluatePronunciation já persiste os dados detalhados.
      /*
      if (result != null && result.containsKey('correto')) {
        await apiService.recordAttempt(
          _currentUserId!,
          _currentWord!,
          _currentSound!,
          result['correto'] as bool,
        );
        if (mounted) {
          // apiService.getAttemptHistory(_currentUserId!); // Removida a chamada desnecessária, histórico é obtido na ProgressScreen
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
        appBar: AppBar(title: const Text('Exercício de Sons')),
        body: const Center(
          child: Text('Usuário não logado. Por favor, faça login novamente.', textAlign: TextAlign.center,),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercício de Sons'),
      ),
      body: _isLoading && _evaluationResult == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_evaluationResult != null) ...[
              (_evaluationResult!['error'] != null)
                  ? Text(
                'Erro: ${_evaluationResult!['error']}',
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              )
                  : (_evaluationResult!['correto'] ?? false)
                  ? Column( // Bloco para Correto
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  Text( // Exibe a mensagem de parabéns do Gemini
                    _evaluationResult!['mensagem'] ?? 'Parabéns!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  : Column( // Bloco para Incorreto
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 60),
                  const SizedBox(height: 10),
                  const Text( // Apenas "Incorreto."
                    'Incorreto.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Mostra a transcrição abaixo do "Incorreto."
                  if (_evaluationResult!['transcricao_assemblyai'] != null && _evaluationResult!['transcricao_assemblyai'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Transcrição: "${_evaluationResult!['transcricao_assemblyai']}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ),
                  // Mostra a dica abaixo da transcrição (se houver)
                  if (_evaluationResult!['mensagem'] != null && _evaluationResult!['mensagem'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        _evaluationResult!['mensagem']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadNewWord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  ((_evaluationResult!['correto'] ?? false)) ? 'Próxima Palavra' : 'Tentar outra palavra',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ] else if (_currentWord != null)
              Column(
                children: [
                  const Text(
                    'Pronuncie a palavra:',
                    style: TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentWord!,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentSound != null)
                    Text(
                      'Focando no som: "${_currentSound!.toUpperCase()}"',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _currentWord != null && !_isSpeaking
                          ? () => _speakWord(_currentWord!)
                          : null,
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up,
                        color: _isSpeaking ? Colors.green : Colors.blue,
                      ),
                      label: Text(_isSpeaking ? 'Falando...' : 'Ouvir Palavra', style: TextStyle(fontSize: 18)),
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
                        ? 'Gravando... Pronuncie a palavra!'
                        : 'Pressione e segure para gravar',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              )
            else
              const Text(
                'Nenhuma palavra para praticar. Selecione um som.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}