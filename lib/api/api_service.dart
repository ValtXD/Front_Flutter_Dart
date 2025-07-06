// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:funfono1/models/user.dart';
import 'package:funfono1/models/questionnaire.dart';
import 'package:funfono1/models/attempt_history.dart'; // NOVO IMPORT
import 'package:funfono1/models/reminder.dart'; // NOVO IMPORT
import 'package:funfono1/models/game_result.dart';
import 'package:funfono1/models/daily_word_attempt.dart';

import '../models/attempt_data.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.9:8080/api'; // Certifique-se de que este IP esteja correto --> Casa
  //static const String _baseUrl = 'http://10.80.248.25:8080/api'; // Teste
  // --- 10.205.6.59 --- Ufam --- ICOMP2-ALUNOS
  // --- Rotas de Autenticação ---

  Future<User?> registerUser(String fullName, String email, String password, String phone, bool isInTherapy) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'isInTherapy': isInTherapy,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey('user')) {
          return User.fromJson(responseBody['user']);
        }
        return null;
      } else {
        print('Erro ao registrar usuário: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao registrar usuário: $e');
      return null;
    }
  }

  Future<User?> loginUser(String fullName, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey('user')) {
          return User.fromJson(responseBody['user']);
        }
        return null;
      } else {
        print('Erro ao fazer login: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao fazer login: $e');
      return null;
    }
  }

  // --- Rotas de Questionário ---

  Future<bool> saveQuestionnaire(Questionnaire questionnaire) async {
    final url = Uri.parse('$_baseUrl/questionnaires/save');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(questionnaire.toJson()),
      );
      if (response.statusCode == 200) {
        print('Questionário salvo com sucesso!');
        return true;
      } else {
        print('Erro ao salvar questionário: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao salvar questionário: $e');
      return false;
    }
  }

  Future<bool> checkUserQuestionnaireStatus(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId/status');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_questionnaire'] ?? false;
      } else {
        print('Erro ao verificar status do questionário: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao verificar status do questionário: $e');
      return false;
    }
  }

  // --- Rotas de Exercícios (Sons e Fala) ---

  Future<List<Map<String, String>>?> getSoundsWords(List<String> preferences, List<String> targets) async {
    final url = Uri.parse('$_baseUrl/exercises/sounds');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'preferences': preferences,
          'targets': targets,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['palavras'] is List) {
          return (data['palavras'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
        return null;
      } else {
        print('Erro ao obter palavras de sons: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao obter palavras de sons: $e');
      return null;
    }
  }

  // MÉTODO evaluatePronunciation ATUALIZADO: agora só recebe Base64
  Future<Map<String, dynamic>?> evaluatePronunciation(String userId, String word, String sound, String userSpeechBase64) async {
    final url = Uri.parse('$_baseUrl/exercises/evaluate');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'palavra': word,
          'som': sound,
          'fala_usuario_audio_base64': userSpeechBase64, // <--- Chave para o áudio Base64
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro ao avaliar pronúncia: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao avaliar pronúncia: $e');
      return null;
    }
  }

  Future<String?> generateSpeechPhrases() async {
    final url = Uri.parse('$_baseUrl/speech/generate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['frase'] as String?;
      } else {
        print('Erro ao gerar frases: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao gerar frases: $e');
      return null;
    }
  }

  // MÉTODO evaluateSpeechPhrase ATUALIZADO: agora só recebe Base64
  Future<Map<String, dynamic>?> evaluateSpeechPhrase(String userId, String phrase, String userSpeechBase64) async {
    final url = Uri.parse('$_baseUrl/speech/evaluate');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'frase': phrase,
          'fala_usuario_audio_base64': userSpeechBase64, // <--- Chave para o áudio Base64
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro ao avaliar frase: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao avaliar frase: $e');
      return null;
    }
  }

  Future<bool> recordAttempt(String userId, String word, String sound, bool correct) async {
    final url = Uri.parse('$_baseUrl/exercises/record_attempt');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'palavra': word,
          'som': sound,
          'correto': correct,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao registrar tentativa: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao registrar tentativa: $e');
      return false;
    }
  }

// --- Novos métodos para Histórico ---

  Future<List<AttemptHistory>> getAttemptHistory(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId/history');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['history'] is List) {
          return (data['history'] as List)
              .map((e) => AttemptHistory.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        print('Erro ao obter histórico de tentativas: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao obter histórico de tentativas: $e');
      return [];
    }
  }

  Future<bool> deleteAttempt(String userId, int attemptId, String type) async {
    final url = Uri.parse('$_baseUrl/users/$userId/attempts/$attemptId');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'type': type}), // Envie o tipo da tentativa para o backend
      );
      if (response.statusCode == 200) {
        print('Tentativa $attemptId excluída com sucesso!');
        return true;
      } else {
        print('Erro ao excluir tentativa: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao excluir tentativa: $e');
      return false;
    }
  }

  // --- Rotas de Lembretes (Reminders) ---

  Future<Reminder?> createReminder(Reminder reminder) async {
    final url = Uri.parse('$_baseUrl/reminders');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reminder.toJson()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return Reminder.fromJson(responseBody['reminder'] as Map<String, dynamic>);
      } else {
        print('Erro ao criar lembrete: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao criar lembrete: $e');
      return null;
    }
  }

  Future<List<Reminder>> getReminders(String userId) async {
    final url = Uri.parse('$_baseUrl/reminders/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['reminders'] is List) {
          return (data['reminders'] as List)
              .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        print('Erro ao obter lembretes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao obter lembretes: $e');
      return [];
    }
  }

  Future<bool> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      print('Erro: ID do lembrete é nulo para atualização.');
      return false;
    }
    final url = Uri.parse('$_baseUrl/reminders/${reminder.userId}/${reminder.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reminder.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao atualizar lembrete: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao atualizar lembrete: $e');
      return false;
    }
  }

  Future<bool> deleteReminder(String userId, int reminderId) async {
    final url = Uri.parse('$_baseUrl/reminders/$userId/$reminderId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao excluir lembrete: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao excluir lembrete: $e');
      return false;
    }
  }

  // --- Mini-Game "Palavra Rápida" ---

  Future<String?> generateQuickWord() async {
    // URL CORRIGIDA para /exercises/quick_word_game/generate_word/index.dart (no backend é só /generate_word)
    final url = Uri.parse('$_baseUrl/quick_word_game/generate_word');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['word'] as String?;
      } else {
        print('Erro ao gerar palavra do jogo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao gerar palavra do jogo: $e');
      return null;
    }
  }

  Future<GameResult?> saveQuickWordGameResult(GameResult result) async {
    // URL CORRIGIDA para /exercises/quick_word_game/save_result/index.dart (no backend é só /save_result)
    final url = Uri.parse('$_baseUrl/quick_word_game/save_result');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(result.toJson()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return GameResult.fromJson(responseBody['gameResult'] as Map<String, dynamic>);
      } else {
        print('Erro ao salvar resultado do jogo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao salvar resultado do jogo: $e');
      return null;
    }
  }

  Future<List<GameResult>> getQuickWordGameHistory(String userId) async {
    // URL CORRIGIDA para /exercises/quick_word_game/:userId/index.dart (no backend é só /:userId)
    final url = Uri.parse('$_baseUrl/quick_word_game/user/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['gameResults'] is List) {
          return (data['gameResults'] as List)
              .map((e) => GameResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        print('Erro ao obter histórico do jogo: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao obter histórico do jogo: $e');
      return [];
    }
  }

  Future<bool> deleteQuickWordGameResult(String userId, int resultId) async {
    // URL CORRIGIDA para /exercises/quick_word_game/:userId/:resultId
    final url = Uri.parse('$_baseUrl/quick_word_game/user/$userId/$resultId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao excluir resultado do jogo: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao excluir resultado do jogo: $e');
      return false;
    }
  }

  // NOVO MÉTODO: Avaliação de pronúncia para o mini-game
  Future<Map<String, dynamic>?> evaluateQuickWordPronunciation(
      String userId, String word, String sound, String userSpeechBase64) async {
    // URL DEDICADA PARA O MINI-GAME
    final url = Uri.parse('$_baseUrl/quick_word_game/evaluate_pronunciation');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'palavra': word,
          'som': sound,
          'fala_usuario_audio_base64': userSpeechBase64,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro ao avaliar pronúncia do mini-game: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao avaliar pronúncia do mini-game: $e');
      return null;
    }
  }

  // --- Bot de Assistência ---
  Future<Map<String, dynamic>?> askAssistantBot(String question) async {
    final url = Uri.parse('$_baseUrl/assistant/ask');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Erro ao perguntar ao bot: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao perguntar ao bot: $e');
      return null;
    }
  }

  // --- Rotas de Feedback ---

  Future<bool> sendFeedback(String feedbackText, int rating) async {
    final url = Uri.parse('$_baseUrl/feedback/send_feedback'); // NOVO ENDPOINT
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'feedback_text': feedbackText,
          'rating': rating,
          // 'user_id': userId, // Envie o ID do usuário se necessário
        }),
      );
      if (response.statusCode == 200) {
        print('Feedback enviado para o backend com sucesso!');
        return true;
      } else {
        print('Erro ao enviar feedback para o backend: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      print('Exceção ao enviar feedback para o backend: $e');
      print('Stack Trace Feedback API: $stack');
      return false;
    }
  }

  // NOVO: Método para excluir a conta do usuário
  Future<bool> deleteUserAccount(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId/delete_account');
    try {
      final response = await http.delete(url); // Usando DELETE
      if (response.statusCode == 200) {
        print('Conta do usuário excluída com sucesso!');
        return true;
      } else {
        print('Erro ao excluir conta do usuário: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      print('Exceção ao excluir conta do usuário: $e');
      print('Stack Trace Delete Account: $stack');
      return false;
    }
  }

  // --- Rotas de Palavras Diárias ---
  Future<List<String>?> generateDailyWords(String userId) async {
    // ATENÇÃO: Verifique o caminho da rota no backend!
    final url = Uri.parse('$_baseUrl/daily_words/generate_word');
    print('DEBUG API: Enviando GET para $url');
    try {
      final response = await http.get(url, headers: {'user_id': userId});
      print('DEBUG API: Resposta de $url - Status Code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('DEBUG API: Resposta de $url - Corpo: ${response.body}');
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['words'] is List) {
          return (data['words'] as List).cast<String>();
        }
        return null;
      } else {
        print('ERRO API: Falha ao gerar palavras diárias. Status: ${response.statusCode}. Corpo: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('ERRO API: Exceção ao gerar palavras diárias: $e');
      print('Stack Trace API: $stack');
      return null;
    }
  }

  // NOVO e DEDICADO: Avaliação de pronúncia para Palavras Diárias
  Future<Map<String, dynamic>?> evaluateDailyWordPronunciation(
      String userId, String word, String userSpeechBase64) async {
    // ATENÇÃO: Verifique o caminho da rota no backend!
    final url = Uri.parse('$_baseUrl/daily_words/evaluate_pronunciation');
    print('DEBUG API: Enviando POST para $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'word': word,
          'user_speech_base64': userSpeechBase64,
        }),
      );
      print('DEBUG API: Resposta de $url - Status Code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('DEBUG API: Resposta de $url - Corpo: ${response.body}');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('ERRO API: Falha ao avaliar pronúncia de palavra diária. Status: ${response.statusCode}. Corpo: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('ERRO API: Exceção ao avaliar pronúncia de palavra diária: $e');
      print('Stack Trace API: $stack');
      return null;
    }
  }

  Future<bool> saveDailyWordAttempt({
    required String userId,
    required String word,
    required String userTranscription,
    required bool isCorrect,
    required String tip,
  }) async {
    // ATENÇÃO: Verifique o caminho da rota no backend!
    final url = Uri.parse('$_baseUrl/daily_words/save_attempt');
    print('DEBUG API: Enviando POST para $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'word': word,
          'user_transcription': userTranscription,
          'is_correct': isCorrect,
          'tip': tip,
        }),
      );
      print('DEBUG API: Resposta de $url - Status Code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('DEBUG API: Resposta de $url - Corpo: ${response.body}');
      }
      if (response.statusCode == 200) {
        print('DEBUG API: Tentativa de palavra diária salva com sucesso.');
        return true;
      } else {
        print('ERRO API: Falha ao salvar tentativa de palavra diária. Status: ${response.statusCode}. Corpo: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      print('ERRO API: Exceção ao salvar tentativa de palavra diária: $e');
      print('Stack Trace API: $stack');
      return false;
    }
  }

  Future<List<DailyWordAttempt>?> getDailyWordHistory(String userId) async {
    // ATENÇÃO: Verifique o caminho da rota no backend!
    final url = Uri.parse('$_baseUrl/daily_words/history/$userId');
    print('DEBUG API: Enviando GET para $url');
    try {
      final response = await http.get(url);
      print('DEBUG API: Resposta de $url - Status Code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('DEBUG API: Resposta de $url - Corpo: ${response.body}');
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['history'] is List) {
          return (data['history'] as List)
              .map((e) => DailyWordAttempt.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        print('ERRO API: Corpo da resposta de histórico de palavras diárias inválido ou vazio.');
        return [];
      } else {
        print('ERRO API: Falha ao obter histórico de palavras diárias. Status: ${response.statusCode}. Corpo: ${response.body}');
        return [];
      }
    } catch (e, stack) {
      print('ERRO API: Exceção ao obter histórico de palavras diárias: $e');
      print('Stack Trace API: $stack');
      return [];
    }
  }

}