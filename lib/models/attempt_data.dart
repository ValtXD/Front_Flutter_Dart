// lib/models/attempt_data.dart

class AttemptData {
  final bool correct;
  final String type; // 'som' ou 'fala'

  AttemptData({required this.correct, required this.type});
}