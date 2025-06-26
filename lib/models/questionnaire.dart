// lib/models/questionnaire.dart

import 'package:json_annotation/json_annotation.dart';

part 'questionnaire.g.dart';

@JsonSerializable()
class Questionnaire {
  @JsonKey(name: 'user_id')
  final String? userId; // Corresponde 'user_id' no JSON do backend

  final int age;
  final String gender;

  // Corresponde 'respondent_type' no JSON do backend.
  // O nome do campo no Dart é 'respondentType'.
  @JsonKey(name: 'respondent_type')
  final String respondentType;

  // Corresponde 'speech_diagnosis' (plural no Dart) no JSON do backend.
  @JsonKey(name: 'speech_diagnosis')
  final List<String> speechDiagnoses;

  // Corresponde 'difficult_sounds' no JSON do backend.
  @JsonKey(name: 'difficult_sounds')
  final List<String> difficultSounds;

  // Corresponde 'speech_therapy_history' no JSON do backend.
  // A pergunta no formulário era "Você já realizou acompanhamento com fonoaudiólogo anteriormente?"
  // O valor do campo selecionado (String) é mapeado para esta propriedade.
  @JsonKey(name: 'speech_therapy_history')
  final String speechTherapyHistory;

  @JsonKey(name: 'favorite_foods')
  final List<String> favoriteFoods;

  final List<String> hobbies;

  @JsonKey(name: 'preferred_movie_genres')
  final List<String> movieGenres;

  // Corresponde 'occupation' no JSON do backend (e no formulário).
  final String occupation;

  // Corresponde 'music_preferences' no JSON do backend.
  @JsonKey(name: 'music_preferences')
  final List<String> musicTypes;

  @JsonKey(name: 'daily_interactions')
  final List<String> communicationPeople;

  @JsonKey(name: 'preferred_communication')
  final String communicationPreference;

  @JsonKey(name: 'improvement_goals')
  final List<String> appExpectations;

  @JsonKey(name: 'practice_frequency')
  final String practiceFrequency;

  Questionnaire({
    this.userId,
    required this.age,
    required this.gender,
    required this.respondentType, // Usado na tela, mapeado para 'respondent_type' no JSON
    required this.speechDiagnoses, // Usado na tela, mapeado para 'speech_diagnosis' no JSON
    required this.difficultSounds,
    required this.speechTherapyHistory, // Usado na tela, mapeado para 'speech_therapy_history' no JSON
    required this.favoriteFoods,
    required this.hobbies,
    required this.movieGenres,
    required this.occupation, // Usado na tela, mapeado para 'occupation' no JSON
    required this.musicTypes, // Usado na tela, mapeado para 'music_preferences' no JSON
    required this.communicationPeople,
    required this.communicationPreference,
    required this.appExpectations,
    required this.practiceFrequency,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) => _$QuestionnaireFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionnaireToJson(this);
}