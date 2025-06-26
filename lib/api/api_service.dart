import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:funfono1/models/user.dart';
import 'package:funfono1/models/questionnaire.dart';

import '../models/attempt_data.dart';

class ApiService {
  // Use o IP do seu computador ou '10.0.2.2' para emulador Android
  // Se estiver testando em um dispositivo físico, use o IP real do seu computador na rede local
  // Ex: 'http://192.168.1.100:8080/api'
  static const String _baseUrl = 'http://192.168.0.4:8080/api'; // Para emulador Android

  // --- Rotas de Autenticação ---

  Future<User?> registerUser(String fullName, String email, String password, String phone, bool isInTherapy) async {
    final url = Uri.parse('$_baseUrl/auth/register'); // [cite: 14]
    try {
      final response = await http.post( // [cite: 14]
        url,
        headers: {'Content-Type': 'application/json'}, // [cite: 14]
        body: json.encode({ // [cite: 14]
          'fullName': fullName, // [cite: 14]
          'email': email, // [cite: 14]
          'password': password, // [cite: 14]
          'phone': phone, // [cite: 14]
          'isInTherapy': isInTherapy, // [cite: 14]
        }),
      );

      if (response.statusCode == 200) { // Sucesso no backend (HTTP 200 OK ou 201 Created) [cite: 14]
        // O backend register.txt retorna 200 com o objeto 'user' [cite: 14]
        final Map<String, dynamic> responseBody = json.decode(response.body); // [cite: 14]
        if (responseBody.containsKey('user')) { // [cite: 14]
          return User.fromJson(responseBody['user']); // [cite: 14]
        }
        return null; // Caso a chave 'user' não esteja presente [cite: 14]
      } else {
        // Erro: Email já cadastrado (HTTP 409 Conflict), erro de validação (HTTP 400 Bad Request), etc. [cite: 14]
        print('Erro ao registrar usuário: ${response.statusCode} - ${response.body}'); // [cite: 14]
        return null;
      }
    } catch (e) {
      print('Exceção ao registrar usuário: $e'); // [cite: 14]
      return null;
    }
  }

  // --- Rotas de Questionário ---

  Future<bool> saveQuestionnaire(Questionnaire questionnaire) async {
    final url = Uri.parse('$_baseUrl/questionnaires/save'); // [cite: 15]
    try {
      final response = await http.post( // [cite: 15]
        url,
        headers: {'Content-Type': 'application/json'}, // [cite: 15]
        body: json.encode(questionnaire.toJson()), // [cite: 15]
      );

      if (response.statusCode == 200) { // [cite: 15]
        print('Questionário salvo com sucesso!'); // [cite: 15]
        return true;
      } else {
        print('Erro ao salvar questionário: ${response.statusCode} - ${response.body}'); // [cite: 15]
        return false;
      }
    } catch (e) {
      print('Exceção ao salvar questionário: $e'); // [cite: 15]
      return false;
    }
  }

  Future<bool> checkUserQuestionnaireStatus(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId/status'); // [cite: 16]
    try {
      final response = await http.get(url); // [cite: 16]

      if (response.statusCode == 200) { // [cite: 16]
        final data = json.decode(response.body); // [cite: 16]
        return data['has_questionnaire'] ?? false; // [cite: 16]
      } else {
        print('Erro ao verificar status do questionário: ${response.statusCode} - ${response.body}'); // [cite: 16]
        return false;
      }
    } catch (e) {
      print('Exceção ao verificar status do questionário: $e'); // [cite: 16]
      return false;
    }
  }

  // --- Rotas de Exercícios (Sons e Fala) ---

  // Adaptação para o retorno do seu backend (sounds.txt) que é {"palavras": [{"palavra": "chácara", "som": "ch"}]}
  Future<List<Map<String, String>>?> getSoundsWords(List<String> preferences, List<String> targets) async {
    final url = Uri.parse('$_baseUrl/exercises/sounds'); //
    try {
      final response = await http.post( //
        url,
        headers: {'Content-Type': 'application/json'}, //
        body: json.encode({ //
          'preferences': preferences, //
          'targets': targets, //
        }),
      );

      if (response.statusCode == 200) { //
        final data = json.decode(response.body); //
        if (data != null && data['palavras'] is List) { //
          // Mapeia a lista de mapas para o formato esperado List<Map<String, String>>
          return (data['palavras'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
        return null;
      } else {
        print('Erro ao obter palavras de sons: ${response.statusCode} - ${response.body}'); //
        return null;
      }
    } catch (e) {
      print('Exceção ao obter palavras de sons: $e'); //
      return null;
    }
  }

  Future<Map<String, dynamic>?> evaluatePronunciation(String userId, String word, String sound, String userSpeechBase64) async {
    final url = Uri.parse('$_baseUrl/exercises/evaluate'); // [cite: 18]
    try {
      final response = await http.post( // [cite: 18]
        url,
        headers: {'Content-Type': 'application/json'}, // [cite: 18]
        body: json.encode({ // [cite: 18]
          'user_id': userId, // [cite: 18]
          'palavra': word, // [cite: 18]
          'som': sound, // [cite: 18]
          'fala_usuario': userSpeechBase64, // Áudio em Base64 [cite: 18]
        }),
      );

      if (response.statusCode == 200) { // [cite: 18]
        return json.decode(response.body); // Retorna o resultado da avaliação (correto, dica, etc.) [cite: 18]
      } else {
        print('Erro ao avaliar pronúncia: ${response.statusCode} - ${response.body}'); // [cite: 18]
        return null;
      }
    } catch (e) {
      print('Exceção ao avaliar pronúncia: $e'); // [cite: 18]
      return null;
    }
  }

  // Adaptação para o retorno do seu backend (generate.txt) que é {"frase": "..."}
  Future<String?> generateSpeechPhrases() async { // Retorna uma única frase como String?
    final url = Uri.parse('$_baseUrl/speech/generate'); //
    try {
      final response = await http.get(url); // Assumindo que não precisa de corpo para gerar frases

      if (response.statusCode == 200) { //
        final data = json.decode(response.body); //
        return data['frase'] as String?; // Extrai a frase do JSON
      } else {
        print('Erro ao gerar frases: ${response.statusCode} - ${response.body}'); //
        return null;
      }
    } catch (e) {
      print('Exceção ao gerar frases: $e'); //
      return null;
    }
  }

  Future<Map<String, dynamic>?> evaluateSpeechPhrase(String userId, String phrase, String userSpeechBase64) async {
    final url = Uri.parse('$_baseUrl/speech/evaluate'); // [cite: 1]
    try {
      final response = await http.post( // [cite: 1]
        url,
        headers: {'Content-Type': 'application/json'}, // [cite: 1]
        body: json.encode({ // [cite: 1]
          'user_id': userId, // [cite: 1]
          'frase': phrase, // [cite: 1]
          'fala_usuario': userSpeechBase64, // Áudio em Base64 [cite: 1]
        }),
      );

      if (response.statusCode == 200) { // [cite: 1]
        return json.decode(response.body); // Retorna o resultado da avaliação [cite: 1]
      } else {
        print('Erro ao avaliar frase: ${response.statusCode} - ${response.body}'); // [cite: 1]
        return null;
      }
    } catch (e) {
      print('Exceção ao avaliar frase: $e'); // [cite: 1]
      return null;
    }
  }

  Future<bool> recordAttempt(String userId, String word, String sound, bool correct) async {
    final url = Uri.parse('$_baseUrl/exercises/record_attempt'); // [cite: 19]
    try {
      final response = await http.post( // [cite: 19]
        url,
        headers: {'Content-Type': 'application/json'}, // [cite: 19]
        body: json.encode({ // [cite: 19]
          'user_id': userId, // [cite: 19]
          'palavra': word, // [cite: 19]
          'som': sound, // [cite: 19]
          'correto': correct, // [cite: 19]
        }),
      );

      if (response.statusCode == 200) { // [cite: 19]
        return true;
      } else {
        print('Erro ao registrar tentativa: ${response.statusCode} - ${response.body}'); // [cite: 19]
        return false;
      }
    } catch (e) {
      print('Exceção ao registrar tentativa: $e'); // [cite: 19]
      return false;
    }
  }

  // Novo método para buscar histórico de tentativas para o gráfico
  Future<List<AttemptData>> getAttemptHistory(String userId) async {
    final List<AttemptData> history = [];

    // --- IMPORTANTE: SUBSTITUA ESTA SIMULAÇÃO POR CHAMADAS REAIS AO BACKEND ---
    // Seu backend precisaria de novas rotas GET para buscar:
    // 1. /api/attempts/pronunciation/{userId} (para histórico de sons/palavras)
    // 2. /api/attempts/speech/{userId} (para histórico de frases)

    // EXEMPLO DE COMO SERIA SE HOUVESSE UMA ROTA NO BACKEND (ex: /api/attempts/pronunciation)
    // try {
    //   final pronunciationResponse = await http.get(Uri.parse('$_baseUrl/attempts/pronunciation/$userId'));
    //   if (pronunciationResponse.statusCode == 200) {
    //     final List<dynamic> data = json.decode(pronunciationResponse.body);
    //     for (var item in data) {
    //       history.add(AttemptData(correct: item['correto'] as bool, type: 'som'));
    //     }
    //   }
    // } catch (e) {
    //   print('Erro ao buscar histórico de pronúncia: $e');
    // }

    // EXEMPLO DE COMO SERIA SE HOUVESSE UMA ROTA NO BACKEND (ex: /api/attempts/speech)
    // try {
    //   final speechResponse = await http.get(Uri.parse('$_baseUrl/attempts/speech/$userId'));
    //   if (speechResponse.statusCode == 200) {
    //     final List<dynamic> data = json.decode(speechResponse.body);
    //     for (var item in data) {
    //       history.add(AttemptData(correct: item['acertou'] as bool, type: 'fala'));
    //     }
    //   }
    // } catch (e) {
    //   print('Erro ao buscar histórico de fala: $e');
    // }

    // --- SIMULAÇÃO PARA PROPÓSITOS DO GRÁFICO (REMOVER EM PRODUÇÃO) ---
    // Estes dados simulados farão o gráfico aparecer mesmo sem o backend completo.
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
    // ------------------------------------------------------------------

    return history;
  }
}
