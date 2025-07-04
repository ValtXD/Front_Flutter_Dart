// lib/models/attempt_history.dart

import 'package:json_annotation/json_annotation.dart';

part 'attempt_history.g.dart';

@JsonSerializable()
class AttemptHistory {
  final int id; // ID do registro no banco de dados
  @JsonKey(name: 'user_id')
  final String userId; // ID do usuário
  final String original; // 'palavra' ou 'frase' que o usuário tentou falar
  final bool correct; // Se acertou ou não
  final String? transcribed; // Transcrição da AssemblyAI (para 'som' e 'fala')
  final String? feedback; // Dica/feedback da IA (para 'som' e 'fala')
  @JsonKey(name: 'created_at')
  final DateTime createdAt; // Timestamp da tentativa
  final String type; // 'som' ou 'frase' para distinguir no frontend

  AttemptHistory({
    required this.id,
    required this.userId,
    required this.original,
    required this.correct,
    this.transcribed,
    this.feedback,
    required this.createdAt,
    required this.type,
  });

  factory AttemptHistory.fromJson(Map<String, dynamic> json) => _$AttemptHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$AttemptHistoryToJson(this);
}