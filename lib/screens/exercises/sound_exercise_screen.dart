// lib/screens/exercises/sound_exercise_screen.dart

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

  // Função para reproduzir a palavra usando TTS
  Future<void> _speakWord(String word) async {
    if (_isSpeaking) {
      await flutterTts.stop(); // Para a fala atual se estiver falando
    }
    // Verifica se a palavra não é nula e não está vazia antes de falar
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

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.isGranted) {
        // Interrompe o TTS se ele estiver falando antes de gravar
        if (_isSpeaking) {
          await flutterTts.stop();
        }
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/audio_record.m4a';
        await _audioRecorder.start(const RecordConfig(), path: filePath);
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

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
          _isLoading = true;
        });
      }
      if (path != null) {
        _evaluatePronunciation(path);
      }
    } catch (e) {
      print('Erro ao parar gravação: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao parar gravação.')),
        );
      }
    }
  }

  Future<void> _evaluatePronunciation(String filePath) async {
    if (_currentWord == null || _currentSound == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Dados incompletos para avaliação.')),
      );
      setState(() { _isLoading = false; });
      return;
    }

    final audioFile = File(filePath);
    final bytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final result = await apiService.evaluatePronunciation(
        _currentUserId!,
        _currentWord!,
        _currentSound!,
        base64Audio,
      );
      if (mounted) {
        setState(() {
          _evaluationResult = result;
          _isLoading = false;
        });
        if (result != null && result.containsKey('correto')) {
          await apiService.recordAttempt(
            _currentUserId!,
            _currentWord!,
            _currentSound!,
            result['correto'] as bool,
          );
        }
      }
    } catch (e) {
      print('Erro ao avaliar pronúncia: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _evaluationResult = {'error': 'Falha na avaliação. Tente novamente.'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao avaliar pronúncia. Verifique sua conexão.')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercício de Sons'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_evaluationResult != null) ...[
              // Se houver um resultado de avaliação
              (_evaluationResult!['error'] != null)
                  ? Text(
                'Erro: ${_evaluationResult!['error']}',
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              )
                  : (_evaluationResult!['correto'] ?? false)
                  ? Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    'Parabéns! Pronúncia correta!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  : Column(
                // Se incorreto
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    'Incorreto.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (_evaluationResult!['dica'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Avaliação: ${_evaluationResult!['dica']}',
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
                  const SizedBox(height: 20), // Espaço antes do botão de ouvir

                  // Ícone para ouvir a palavra
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _currentWord != null && !_isSpeaking
                          ? () => _speakWord(_currentWord!)
                          : null, // Desabilita se já estiver falando ou palavra nula
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up, // Altera ícone se falando
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
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
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
                    _isRecording ? 'Gravando...' : 'Pressione e segure para gravar',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isRecording ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ],
              )
            else
              const Text( // Caso _currentWord seja null e não esteja carregando
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