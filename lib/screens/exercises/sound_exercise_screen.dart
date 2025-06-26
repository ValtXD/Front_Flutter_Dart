import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/services/auth_state_service.dart';

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

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _initExercise();
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
      // Opcional: Redirecionar para a tela de login/welcome
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
      return;
    }

    setState(() {
      _isLoading = true;
      _evaluationResult = null; // Limpa o resultado da avaliação anterior
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final words = await apiService.getSoundsWords(
        [], // Preferências (pode ser vazio por enquanto, ou usar as do questionário)
        widget.selectedSounds, // Sons selecionados na tela anterior
      );

      if (mounted) {
        if (words != null && words.isNotEmpty) {
          // Seleciona uma palavra aleatória entre as retornadas
          final randomWord = words[0]; // Por simplicidade, pegando a primeira. Idealmente, randomizar.
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
      if (await _audioRecorder.hasPermission()) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/audio_record.m4a';
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordedFilePath = filePath;
            _evaluationResult = null; // Limpa o resultado anterior ao iniciar nova gravação
          });
        }
      }
    } catch (e) {
      print('Erro ao iniciar gravação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao iniciar gravação.')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
      }
      if (path != null) {
        _evaluatePronunciation(path);
      }
    } catch (e) {
      print('Erro ao parar gravação: $e');
      if (mounted) {
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

        // Registrar a tentativa no backend
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercício de Sons'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading && _currentWord == null)
                const CircularProgressIndicator()
              else if (_currentWord != null)
                Column(
                  children: [
                    const Text(
                      'Pronuncie a palavra:',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentWord!,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    if (_currentSound != null)
                      Text(
                        'Focando no som: "${_currentSound!.toUpperCase()}"',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                  ],
                )
              else
                const Text(
                  'Carregando palavra...',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 40),
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.shade700 : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    size: 80,
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
              const SizedBox(height: 30),
              if (_isLoading && _evaluationResult == null)
                const CircularProgressIndicator()
              else if (_evaluationResult != null)
                Column(
                  children: [
                    if (_evaluationResult!['error'] != null)
                      Text(
                        'Erro: ${_evaluationResult!['error']}',
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                        textAlign: TextAlign.center,
                      )
                    else if (_evaluationResult!['correto'] == true)
                      const Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 60),
                          SizedBox(height: 10),
                          Text(
                            'Parabéns! Pronúncia correta!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else if (_evaluationResult!['correto'] == false)
                        const Column(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'Quase lá! Tente novamente.',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              textAlign: TextAlign.center,
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
                      child: const Text(
                        'Próxima Palavra',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}