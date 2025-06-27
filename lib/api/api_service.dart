// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:funfono1/models/user.dart';
import 'package:funfono1/models/questionnaire.dart';

import '../models/attempt_data.dart';

class ApiService {
  // Use o IP do seu computador ou '10.0.2.2' para emulador Android
  // Se estiver testando em um dispositivo físico, use o IP real do seu computador na rede local
  // Ex: 'http://192.168.1.100:8080/api'
  static const String _baseUrl = 'http://192.168.0.8:8080/api'; // Certifique-se de que este IP esteja correto

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

  // MÉTODO LOGIN DE USUÁRIO ATUALIZADO PARA USAR fullName
  Future<User?> loginUser(String fullName, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName, // Enviando fullName em vez de email
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

  // Adaptação para o retorno do seu backend (sounds.txt) que é {"palavras": [{"palavra": "chácara", "som": "ch"}]}
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
          // Mapeia a lista de mapas para o formato esperado List<Map<String, String>>
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
          'fala_usuario': userSpeechBase64,
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

  Future<Map<String, dynamic>?> evaluateSpeechPhrase(String userId, String phrase, String userSpeechBase64) async {
    final url = Uri.parse('$_baseUrl/speech/evaluate');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'frase': phrase,
          'fala_usuario': userSpeechBase64,
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

  Future<List<AttemptData>> getAttemptHistory(String userId) async {
    final List<AttemptData> history = [];
    history.add(AttemptData(correct: true, type: 'som'));
    history.add(AttemptData(correct: false, type: 'som'));
    history.add(AttemptData(correct: true, type: 'som'));
    history.add(AttemptData(correct: true, type: 'fala'));
    history.add(AttemptData(correct: false, type: 'fala'));
    history.add(AttemptData(correct: true, type: 'fala'));
    history.add(AttemptData(correct: true, type: 'som'));
    history.add(AttemptData(correct: false, type: 'fala'));
    history.add(AttemptData(correct: true, type: 'som'));
    history.add(AttemptData(correct: true, type: 'fala'));
    history.add(AttemptData(correct: false, type: 'som'));

    return history;
  }
}