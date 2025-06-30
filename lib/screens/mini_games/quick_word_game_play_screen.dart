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

class QuickWordGamePlayScreen extends StatefulWidget {
  final String userId;
  const QuickWordGamePlayScreen({super.key, required this.userId});

  @override
  State<QuickWordGamePlayScreen> createState() => _QuickWordGamePlayScreenState();
}

class _QuickWordGamePlayScreenState extends State<QuickWordGamePlayScreen> {
  // Game state
  int _score = 0;
  int _wordsCompleted = 0; // Quantidade de palavras pronunciadas (sucesso ou falha)
  static const int _maxWordsToPronounce = 10; // 1000 pontos / 100 pontos por palavra = 10 palavras
  bool _isGameOver = false;
  String? _currentWord;
  String _gameMessage = 'Prepare-se para decolar!';
  final List<String> _correctWords = [];
  final List<String> _incorrectWords = [];

  // Game phases
  bool _isPronunciationPhase = false; // Indica se o jogo está na fase de pronúncia
  int _lastPronunciationScoreGate = 0; // Controla qual gate de 100 pontos foi alcançado

  // Rocket character
  double _rocketY = 0.0; // Y será o centro vertical da tela (0.0 é o centro)

  // Lasers
  bool _isShooting = false;
  final List<Map<String, double>> _lasers = [];
  Timer? _laserShootTimer; // Timer para disparo automático de laser

  // Meteors
  final List<Map<String, dynamic>> _meteors = [];
  static const double _meteorSpeed = 0.015; // Velocidade dos meteoros
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

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _requestPermissionsAndStartGame();
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();
    _explosionTimer?.cancel();
    _successTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndStartGame() async {
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
    setState(() {
      _score = 0;
      _wordsCompleted = 0;
      _isGameOver = false;
      _isPronunciationPhase = false;
      _lastPronunciationScoreGate = 0;
      _gameMessage = 'Desvie dos meteoros e atire!';
      _rocketY = 0.0; // Posição Y centralizada
      _meteors.clear();
      _lasers.clear();
      _correctWords.clear();
      _incorrectWords.clear();
      _showExplosion = false;
      _showSuccess = false;
    });

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
      // Laser movement - Iterar em reverso para remoção segura
      for (int i = _lasers.length - 1; i >= 0; i--) {
        _lasers[i]['x'] = _lasers[i]['x']! + 0.05;
        if (_lasers[i]['x']! > 1.5) {
          _lasers.removeAt(i);
        }
      }

      // Meteor movement and collision - Iterar em reverso para remoção segura
      for (int i = _meteors.length - 1; i >= 0; i--) {
        final meteor = _meteors[i];
        meteor['x'] = meteor['x'] - meteor['speed'];

        // Rocket-meteor collision
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
          _explodeRocket('Foguete atingido! Fim de jogo.');
          return;
        }

        // Laser-meteor collision - Iterar em reverso para remoção segura de lasers
        for (int j = _lasers.length - 1; j >= 0; j--) {
          final laser = _lasers[j];
          final laserX = laser['x'];
          final laserY = laser['y'];

          if (laserX! > meteorXLeft &&
              laserX < meteorXRight &&
              laserY! > meteorYTop &&
              laserY < meteorYBottom) {
            _meteors.removeAt(i); // Remove o meteoro
            _lasers.removeAt(j); // Remove o laser
            _score += 10; // Ganha 10 pontos por meteoro destruído
            _showSuccessEffect();
            break; // Sai do loop de lasers para este meteoro, pois ele foi destruído
          }
        }

        if (meteor['x'] < -1.5) {
          _meteors.removeAt(i);
        }
      }

      // Verifica gate de pontuação para pronúncia
      if (!_isPronunciationPhase && _score >= (_lastPronunciationScoreGate + 100) && _score < 1000) {
        _lastPronunciationScoreGate = (_score ~/ 100) * 100;
        _enterPronunciationPhase();
      }

      // Verifica pontuação máxima
      if (_score >= 1000 && !_isPronunciationPhase && !_isGameOver) {
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
    setState(() {
      _showExplosion = true;
      _isGameOver = true;
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
    setState(() {
      _isPronunciationPhase = true;
      _gameMessage = 'PRONUNCIE A PALAVRA PARA GANHAR COMBUSTÍVEL!';
    });

    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();

    final apiService = Provider.of<ApiService>(context, listen: false);
    final word = await apiService.generateQuickWord();
    if (word != null && word.isNotEmpty) {
      setState(() {
        _currentWord = word.toUpperCase();
      });
      await _startPronunciationRecording();
    } else {
      _explodeRocket('Não foi possível gerar uma nova palavra para pronúncia. Fim de jogo.');
    }
  }

  Future<void> _startPronunciationRecording() async {
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
    } catch (e) {
      _explodeRocket('Erro na gravação. Jogo encerrado.');
    }
  }

  Future<void> _evaluatePronunciationAndContinue() async {
    if (!_isRecording) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum áudio gravado. Fale a palavra primeiro.')),
        );
      }
      return;
    }

    if (_recordedFilePath == null || _currentWord == null) {
      _explodeRocket('Erro: Nenhuma palavra ou áudio para avaliar.');
      return;
    }

    // Parar gravação antes de enviar para avaliação
    if (await _audioRecorder.isRecording()) {
      try {
        final path = await _audioRecorder.stop();
        _recordedFilePath = path;
        setState(() { _isRecording = false; });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao parar gravação. Tente novamente.')),
          );
        }
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
      }
    } catch (e) {
      _explodeRocket('Erro ao processar áudio para avaliação.');
      return;
    }

    if (base64Audio == null || base64Audio.isEmpty) {
      _explodeRocket('Nenhum áudio válido para enviar para avaliação.');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliando pronúncia...')),
      );
    }

    final evaluationResult = await apiService.evaluatePronunciation(
      widget.userId,
      _currentWord!,
      _currentWord![0], // Assumindo que o som a ser avaliado é a primeira letra da palavra
      base64Audio,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Esconder o indicador
    }

    if (evaluationResult != null) {
      final bool correct = evaluationResult['correto'] ?? false;
      final String feedback = evaluationResult['mensagem'] ?? 'Sem feedback.';

      if (correct) {
        _correctWords.add(_currentWord!);
        setState(() {
          _gameMessage = 'Pronúncia CORRETA! Combustível reabastecido!';
          _isPronunciationPhase = false; // Sai da fase de pronúncia
        });
        _wordsCompleted++; // Conta a palavra pronunciada com sucesso
        _startGameLoopIfNecessary(); // Reinicia o loop do jogo e geradores
      } else {
        _incorrectWords.add(_currentWord!);
        _explodeRocket('Pronúncia INCORRETA! ${feedback} Fim de jogo.'); // Game Over por pronúncia errada
      }
    } else {
      _explodeRocket('Erro ao avaliar a pronúncia. Fim de jogo.');
    }
  }

  void _startGameLoopIfNecessary() {
    if (!_isGameOver) {
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
    _isGameOver = true;
    _gameLoopTimer?.cancel();
    _meteorTimer?.cancel();
    _laserShootTimer?.cancel();
    await _audioRecorder.stop();
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
    await apiService.saveQuickWordGameResult(gameResult);
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
      body: GestureDetector( // Reintroduzindo GestureDetector para movimentação
        onVerticalDragUpdate: (details) {
          if (!_isGameOver && !_isPronunciationPhase) {
            setState(() {
              // Ajusta a sensibilidade do movimento, clamp limita o movimento
              _rocketY += details.primaryDelta! / (screenHeight * 0.3);
              _rocketY = _rocketY.clamp(-1.0, 1.0);
            });
          }
        },
        child: Stack(
          children: [
            // Space background
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

            // Stars
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

            // Rocket - Posição X fixa, Y centralizada
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              left: screenWidth * 0.2, // Mantém o foguete à esquerda
              top: screenHeight * 0.5 + (_rocketY * screenHeight * 0.3) - 50, // Centraliza verticalmente o foguete
              child: _showExplosion
                  ? Image.asset('assets/explosion.png', width: 100, height: 100)
                  : Image.asset('assets/rocket.png', width: 60, height: 100),
            ),

            // Lasers
            for (final laser in _lasers)
              Positioned(
                left: screenWidth * 0.2 + 60 + (laser['x']! * screenWidth * 0.3), // Ajusta o disparo do laser para sair da frente do foguete
                top: screenHeight * 0.5 + (laser['y']! * screenHeight * 0.3) - 2, // Ajusta a posição vertical do laser
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

            // Meteors - Posição Y ajustada para serem mais centralizados
            for (final meteor in _meteors)
              Positioned(
                left: screenWidth * 0.5 + (meteor['x'] * screenWidth * 0.5) - (meteor['size'] * 60), // Ajusta X para centralizar o meteoro
                top: screenHeight * 0.5 + (meteor['y'] * screenHeight * 0.3) - (meteor['size'] * 60), // Ajusta Y para centralizar o meteoro
                child: Transform.rotate(
                  angle: meteor['x'] * 2, // Rotation effect
                  child: Image.asset('assets/meteor.png',
                      width: meteor['size'] * 120,
                      height: meteor['size'] * 120),
                ),
              ),

            // Success effect
            if (_showSuccess)
              Center(
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: Colors.green.withOpacity(0.3),
                ),
              ),

            // Game HUD
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
                  if (_currentWord != null && _isPronunciationPhase) // Mostra a palavra apenas na fase de pronúncia
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

            // Botão "Enviar Pronúncia" (somente na fase de pronúncia)
            if (_isPronunciationPhase && !_isGameOver)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 200), // Ajuste a posição conforme necessário
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

            // Game over overlay
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
                          // Reinicia o jogo
                          _startGame();
                        },
                        child: const Text(
                          'Jogar Novamente',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 15), // Espaçamento entre os botões
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, // Outra cor para diferenciar
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Retorna 'true' para a tela anterior (QuickWordGameScreen)
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