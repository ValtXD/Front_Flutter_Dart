// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptHistory _$AttemptHistoryFromJson(Map<String, dynamic> json) =>
    AttemptHistory(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      original: json['original'] as String,
      correct: json['correct'] as bool,
      transcribed: json['transcribed'] as String?,
      feedback: json['feedback'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: json['type'] as String,
    );

Map<String, dynamic> _$AttemptHistoryToJson(AttemptHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'original': instance.original,
      'correct': instance.correct,
      'transcribed': instance.transcribed,
      'feedback': instance.feedback,
      'created_at': instance.createdAt.toIso8601String(),
      'type': instance.type,
    };
