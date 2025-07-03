// lib/screens/mini_games/quick_word_game_play_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/models/game_result.dart';
import 'package:audioplayers/audioplayers.dart';

class QuickWordGamePlayScreen extends StatefulWidget {
  final String userId;
  const QuickWordGamePlayScreen({super.key, required this.userId});

  @override
  State<QuickWordGamePlayScreen> createState() => _QuickWordGamePlayScreenState();
}

class _QuickWordGamePlayScreenState extends State<QuickWordGamePlayScreen> {
  // Game state
  int _score = 0;
  int _wordsCompleted = 0;
  static const int _maxWordsToPronounce = 10;
  bool _isGameOver = false;
  String? _currentWord;
  String _gameMessage = 'Prepare-se para decolar!';
  final List<String> _correctWords = [];
  final List<String> _incorrectWords = [];

  // Game phases
  bool _isPronunciationPhase = false;
  int _lastPronunciationScoreGate = 0;

  // Rocket character
  double _rocketY = 0.0;

  // Lasers
  bool _isShooting = false;
  final List<Map<String, double>> _lasers = [];
  Timer? _laserShootTimer;

  // Meteors
  final List<Map<String, dynamic>> _meteors = [];
  static const double _meteorSpeed = 0.015;
  Timer? _meteorTimer;

  // Game loop timer
  Timer? _gameLoopTimer;

  // Pronunciation system
  bool _isRecording = false;
  late AudioRecorder _audioRecorder;
  String? _recordedFilePath;

  // Visual effects
  bool _showExplosion = false;
  Timer? _explosionTimer;
  bool _showSuccess = false;
  Timer? _successTimer;

  // Audio Players
  late AudioPlayer _backgroundMusicPlayer;
  late AudioPlayer _sfxPlayer;
  late AudioCache _audioCache; // AudioCache ainda útil para precarregar, mesmo que não toque tudo

  @override
  void initState() {
    super.initState();
    print('DEBUG: initState chamado.');
    _audioRecorder = AudioRecorder();
    _initializeAudioPlayers();
    _requestPermissionsAndStartGame();
  }

  void _initializeAudioPlayers() {
    _backgroundMusicPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _audioCache = AudioCache(prefix: 'assets/audio/');

    _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    _backgroundMusicPlayer.setVolume(0.5);
    _sfxPlayer.setVolume(0.8);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    _audioCache.loadAll([
      'background_music.mp3', // Música de fundo
      'laser_shoot.mp3', // Apenas para pre-carga, não será tocado
      'explosion.mp3',   // Apenas para pre-carga, não será tocado
      'meteor_hit.mp3',  // Apenas para pre-carga, não será tocado
    ]).then((_) {
      print('DEBUG: Sons pré-carregados com sucesso!');
    }).catchError((e) {
      print('ERRO: Falha ao pré-carregar sons: $e');
    });
  }

  @override
  void dispose() {
    print('DEBUG: dispose chamado.');
    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();
    _explosionTimer?.cancel();
    _successTimer?.cancel();
    _audioRecorder.dispose();
    _backgroundMusicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndStartGame() async {
    print('DEBUG: _requestPermissionsAndStartGame chamado.');
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone necessária para jogar!')),
        );
        Navigator.of(context).pop(false);
      }
      return;
    }
    _startGame();
  }

  void _startGame() {
    print('DEBUG: _startGame chamado. Resetando o jogo.');
    setState(() {
      _score = 0;
      _wordsCompleted = 0;
      _isGameOver = false;
      _isPronunciationPhase = false;
      _lastPronunciationScoreGate = 0;
      _gameMessage = 'Desvie dos meteoros e atire!';
      _rocketY = 0.0;
      _meteors.clear();
      _lasers.clear();
      _correctWords.clear();
      _incorrectWords.clear();
      _showExplosion = false;
      _showSuccess = false;
    });

    _backgroundMusicPlayer.play(AssetSource('audio/background_music.mp3'));

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isGameOver && !_isPronunciationPhase) {
        _updateGame();
      } else if (_isGameOver) {
        timer.cancel();
      }
    });

    _meteorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isGameOver && !_isPronunciationPhase) {
        _spawnMeteor();
      } else if (_isGameOver) {
        timer.cancel();
      }
    });

    _startAutoLaserShoot();
  }

  void _startAutoLaserShoot() {
    print('DEBUG: _startAutoLaserShoot chamado.');
    _laserShootTimer?.cancel();
    _laserShootTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!_isGameOver && !_isPronunciationPhase) {
        _shootLaser();
      } else if (_isGameOver) {
        timer.cancel();
      }
    });
  }

  void _updateGame() {
    setState(() {
      for (int i = _lasers.length - 1; i >= 0; i--) {
        _lasers[i]['x'] = _lasers[i]['x']! + 0.05;
        if (_lasers[i]['x']! > 1.5) {
          _lasers.removeAt(i);
        }
      }

      for (int i = _meteors.length - 1; i >= 0; i--) {
        final meteor = _meteors[i];
        meteor['x'] = meteor['x'] - meteor['speed'];

        final rocketXLeft = -0.7;
        final rocketXRight = -0.5;
        final rocketYTop = _rocketY - 0.1;
        final rocketYBottom = _rocketY + 0.1;

        final meteorXLeft = meteor['x'] - meteor['size'] / 2;
        final meteorXRight = meteor['x'] + meteor['size'] / 2;
        final meteorYTop = meteor['y'] - meteor['size'] / 2;
        final meteorYBottom = meteor['y'] + meteor['size'] / 2;

        if (rocketXRight > meteorXLeft &&
            rocketXLeft < meteorXRight &&
            rocketYBottom > meteorYTop &&
            rocketYTop < meteorYBottom) {
          print('DEBUG: Colisão detectada! Chamando _explodeRocket.');
          _explodeRocket('Foguete atingido! Fim de jogo.');
          return;
        }

        for (int j = _lasers.length - 1; j >= 0; j--) {
          final laser = _lasers[j];
          final laserX = laser['x'];
          final laserY = laser['y'];

          if (laserX! > meteorXLeft &&
              laserX < meteorXRight &&
              laserY! > meteorYTop &&
              laserY < meteorYBottom) {
            print('DEBUG: Laser atingiu meteoro. Pontos: +10.');
            // _sfxPlayer.play(AssetSource('audio/meteor_hit.mp3')); // REMOVIDO: Som de meteoro atingido
            _meteors.removeAt(i);
            _lasers.removeAt(j);
            _score += 10;
            _showSuccessEffect();
            break;
          }
        }

        if (meteor['x'] < -1.5) {
          _meteors.removeAt(i);
        }
      }

      if (!_isPronunciationPhase && _score >= (_lastPronunciationScoreGate + 100) && _score < 1000) {
        print('DEBUG: Gate de pontuação atingido ($_score). Chamando _enterPronunciationPhase.');
        _lastPronunciationScoreGate = (_score ~/ 100) * 100;
        _enterPronunciationPhase();
      }

      if (_score >= 1000 && !_isPronunciationPhase && !_isGameOver) {
        print('DEBUG: Pontuação máxima atingida ($_score). Chamando _gameOver (Vitória).');
        _gameOver('Parabéns! Você alcançou a pontuação máxima!', win: true);
      }
    });
  }

  void _spawnMeteor() {
    final random = Random();
    _meteors.add({
      'x': 1.5,
      'y': -0.7 + random.nextDouble() * 1.4,
      'size': 0.1 + random.nextDouble() * 0.1,
      'speed': _meteorSpeed * (0.8 + random.nextDouble() * 0.4)
    });
  }

  void _shootLaser() {
    if (_isGameOver || _isShooting || _isPronunciationPhase) return;
    print('DEBUG: _shootLaser chamado.');
    // _sfxPlayer.play(AssetSource('audio/laser_shoot.mp3')); // REMOVIDO: Som de laser
    setState(() {
      _lasers.add({
        'x': -0.5,
        'y': _rocketY,
      });
      _isShooting = true;
      Timer(const Duration(milliseconds: 300), () {
        _isShooting = false;
      });
    });
  }

  void _explodeRocket(String message) {
    if (_isGameOver) return;
    print('DEBUG: _explodeRocket chamado com mensagem: $message');
    // _sfxPlayer.play(AssetSource('audio/explosion.mp3')); // REMOVIDO: Som de explosão
    _backgroundMusicPlayer.stop();
    setState(() {
      _showExplosion = true;
      //_isGameOver = true;
      _gameMessage = message;
    });
    _explosionTimer = Timer(const Duration(seconds: 2), () {
      // O timer é apenas para o efeito visual, o game over já foi acionado
    });
    _gameOver(message);
  }

  void _showSuccessEffect() {
    setState(() {
      _showSuccess = true;
    });
    _successTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _showSuccess = false;
      });
    });
  }

  Future<void> _enterPronunciationPhase() async {
    print('DEBUG: _enterPronunciationPhase chamado. Pausando jogo.');
    _backgroundMusicPlayer.pause();
    setState(() {
      _isPronunciationPhase = true;
      _gameMessage = 'PRONUNCIE A PALAVRA PARA GANHAR COMBUSTÍVEL!';
    });

    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();

    final apiService = Provider.of<ApiService>(context, listen: false);
    print('DEBUG: Gerando nova palavra para pronúncia...');
    final word = await apiService.generateQuickWord();
    if (word != null && word.isNotEmpty) {
      setState(() {
        _currentWord = word.toUpperCase();
      });
      print('DEBUG: Palavra gerada: $_currentWord. Iniciando gravação.');
      await _startPronunciationRecording();
    } else {
      print('DEBUG: Falha ao gerar palavra. Chamando _explodeRocket.');
      _explodeRocket('Não foi possível gerar uma nova palavra para pronúncia. Fim de jogo.');
    }
  }

  Future<void> _startPronunciationRecording() async {
    print('DEBUG: _startPronunciationRecording chamado.');
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone não concedida para gravar.')),
        );
      }
      _explodeRocket('Permissão de microfone negada. Jogo encerrado.');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    _recordedFilePath = '${directory.path}/game_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      setState(() { _isRecording = true; });
      print('DEBUG: Gravação iniciada. Caminho: $_recordedFilePath');
    } catch (e) {
      print('DEBUG: Erro ao iniciar gravação: $e. Chamando _explodeRocket.');
      _explodeRocket('Erro na gravação. Jogo encerrado.');
    }
  }

  Future<void> _evaluatePronunciationAndContinue() async {
    print('DEBUG: _evaluatePronunciationAndContinue chamado.');
    if (!_isRecording) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum áudio gravado. Fale a palavra primeiro.')),
        );
      }
      return;
    }

    if (_recordedFilePath == null || _currentWord == null) {
      print('DEBUG: Caminho do áudio ou palavra nulos. Chamando _explodeRocket.');
      _explodeRocket('Erro: Nenhuma palavra ou áudio para avaliar.');
      return;
    }

    // Parar gravação antes de enviar para avaliação
    if (await _audioRecorder.isRecording()) {
      try {
        final path = await _audioRecorder.stop();
        _recordedFilePath = path;
        setState(() { _isRecording = false; });
        print('DEBUG: Gravação parada. Caminho final: $_recordedFilePath');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao parar gravação. Tente novamente.')),
          );
        }
        print('DEBUG: Erro ao parar gravação: $e. Chamando _explodeRocket.');
        _explodeRocket('Erro na gravação. Jogo encerrado.');
        return;
      }
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    String? base64Audio;
    try {
      final audioFile = File(_recordedFilePath!);
      if (await audioFile.exists()) {
        final bytes = await audioFile.readAsBytes();
        base64Audio = base64Encode(bytes);
        print('DEBUG: Áudio lido e codificado em Base64 (${base64Audio.length} bytes).');
      }
    } catch (e) {
      print('DEBUG: Erro ao processar áudio para avaliação: $e. Chamando _explodeRocket.');
      _explodeRocket('Erro ao processar áudio para avaliação.');
      return;
    }

    if (base64Audio == null || base64Audio.isEmpty) {
      print('DEBUG: Áudio Base64 nulo ou vazio. Chamando _explodeRocket.');
      _explodeRocket('Nenhum áudio válido para enviar para avaliação.');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliando pronúncia...')),
      );
    }
    print('DEBUG: Enviando áudio para evaluateQuickWordPronunciation.');
    final evaluationResult = await apiService.evaluateQuickWordPronunciation(
      widget.userId,
      _currentWord!,
      _currentWord![0], // Assumindo que o som a ser avaliado é a primeira letra da palavra
      base64Audio,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (evaluationResult != null) {
      final bool correct = evaluationResult['correto'] ?? false;
      final String feedback = evaluationResult['mensagem'] ?? 'Sem feedback.';
      print(
          'DEBUG: Resultado da avaliação: Correto=$correct, Feedback="$feedback"');

      if (correct) {
        _correctWords.add(_currentWord!);
        _wordsCompleted++;
        print('DEBUG: Pronúncia correta. Retornando ao jogo normal.');

        setState(() {
          _isPronunciationPhase = false;
          _gameMessage = 'Pronúncia correta! Continue jogando...';
        });

        await Future.delayed(const Duration(seconds: 1));

        if (!_isGameOver) {
          _startGameLoopIfNecessary(); // volta ao jogo
        }
      } else {
        _incorrectWords.add(_currentWord!);
        print('DEBUG: Pronúncia incorreta. Salvando progresso parcial...');

        final apiService = Provider.of<ApiService>(context, listen: false);
        final gameResult = GameResult(
          userId: widget.userId,
          score: _score,
          correctWords: _correctWords,
          incorrectWords: _incorrectWords,
        );
        await apiService.saveQuickWordGameResult(gameResult);
        print('✅ Progresso salvo antes de _explodeRocket.');

        _explodeRocket('Pronúncia INCORRETA! ${feedback} Fim de jogo.');
      }
    } else {
      print('DEBUG: Resultado da avaliação nulo. Salvando progresso parcial.');

      final apiService = Provider.of<ApiService>(context, listen: false);
      final gameResult = GameResult(
        userId: widget.userId,
        score: _score,
        correctWords: _correctWords,
        incorrectWords: _incorrectWords,
      );
      await apiService.saveQuickWordGameResult(gameResult);
      print('✅ Progresso salvo antes de _explodeRocket (erro nulo).');

      _explodeRocket('Erro ao avaliar a pronúncia. Fim de jogo.');
    }
  }

  void _startGameLoopIfNecessary() {
    print('DEBUG: _startGameLoopIfNecessary chamado.');
    if (!_isGameOver) {
      _backgroundMusicPlayer.resume();
      _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_isGameOver && !_isPronunciationPhase) {
          _updateGame();
        } else if (_isGameOver) {
          timer.cancel();
        }
      });
      _meteorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!_isGameOver && !_isPronunciationPhase) {
          _spawnMeteor();
        } else if (_isGameOver) {
          timer.cancel();
        }
      });
      _startAutoLaserShoot();
    }
  }

  Future<void> _gameOver(String finalMessage, {bool win = false}) async {
    if (_isGameOver) return;
    print('DEBUG: _gameOver chamado! Mensagem final: "$finalMessage"');
    _isGameOver = true;
    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();
    await _audioRecorder.stop();
    _backgroundMusicPlayer.stop();
    setState(() {
      _gameMessage = finalMessage;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final gameResult = GameResult(
      userId: widget.userId,
      score: _score,
      correctWords: _correctWords,
      incorrectWords: _incorrectWords,
    );
    print('DEBUG: Tentando salvar resultado do Quick Word Game. Score: $_score');
    await apiService.saveQuickWordGameResult(gameResult);
    print('DEBUG: apiService.saveQuickWordGameResult chamada concluída.');


  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final random = Random();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foguete da Pronúncia'),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (!_isGameOver && !_isPronunciationPhase) {
            setState(() {
              _rocketY += details.primaryDelta! / (screenHeight * 0.3);
              _rocketY = _rocketY.clamp(-1.0, 1.0);
            });
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.deepPurple[900]!,
                  ],
                ),
              ),
            ),

            for (int i = 0; i < 100; i++)
              Positioned(
                left: random.nextDouble() * screenWidth,
                top: random.nextDouble() * screenHeight,
                child: Container(
                  width: random.nextDouble() * 3,
                  height: random.nextDouble() * 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(random.nextDouble()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              left: screenWidth * 0.2,
              top: screenHeight * 0.5 + (_rocketY * screenHeight * 0.3) - 50,
              child: _showExplosion
                  ? Image.asset('assets/explosion.png', width: 100, height: 100)
                  : Image.asset('assets/rocket.png', width: 60, height: 100),
            ),

            for (final laser in _lasers)
              Positioned(
                left: screenWidth * 0.2 + 60 + (laser['x']! * screenWidth * 0.3),
                top: screenHeight * 0.5 + (laser['y']! * screenHeight * 0.3) - 2,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.yellow, Colors.red],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            for (final meteor in _meteors)
              Positioned(
                left: screenWidth * 0.5 + (meteor['x'] * screenWidth * 0.5) - (meteor['size'] * 60),
                top: screenHeight * 0.5 + (meteor['y'] * screenHeight * 0.3) - (meteor['size'] * 60),
                child: Transform.rotate(
                  angle: meteor['x'] * 2,
                  child: Image.asset('assets/meteor.png',
                      width: meteor['size'] * 120,
                      height: meteor['size'] * 120),
                ),
              ),

            if (_showSuccess)
              Center(
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: Colors.green.withOpacity(0.3),
                ),
              ),

            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Pontos: $_score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Palavras Pronunciadas: $_wordsCompleted/$_maxWordsToPronounce',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _gameMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  if (_currentWord != null && _isPronunciationPhase)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _currentWord!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isPronunciationPhase && !_isGameOver)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _evaluatePronunciationAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Enviar Pronúncia', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isRecording ? 'Gravando...' : 'Pressione "Enviar Pronúncia" após falar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isGameOver)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _gameMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Pontuação final: $_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          _startGame();
                        },
                        child: const Text(
                          'Jogar Novamente',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text(
                          'Voltar para o Início',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}