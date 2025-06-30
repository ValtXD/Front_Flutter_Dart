// lib/models/pronunciation_tip.dart

class PronunciationTip {
  final String sound;       // O som (ex: "A", "G", "CH")
  final String type;        // "Vogal", "Consoante", "Combinação"
  final String gifAssetPath; // Caminho para o arquivo GIF (ex: 'assets/gifs/g_strong.gif')
  final List<Map<String, String>> tips; // Lista de mapas com {'title': '...', 'description': '...'}

  PronunciationTip({
    required this.sound,
    required this.type,
    required this.gifAssetPath,
    required this.tips,
  });
}