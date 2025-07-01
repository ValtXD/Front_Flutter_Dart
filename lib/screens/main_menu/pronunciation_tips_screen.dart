import 'package:flutter/material.dart';
import 'package:funfono1/models/pronunciation_tip.dart';
import 'package:funfono1/screens/main_menu/tip_detail_modal.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Importe o flutter_tts

class PronunciationTipsScreen extends StatelessWidget {
  PronunciationTipsScreen({super.key});

  // Crie uma única instância de FlutterTts para ser reutilizada
  final FlutterTts flutterTts = FlutterTts();

  // Configuração inicial do TTS
  void _initializeTts() async {
    await flutterTts.setLanguage("pt-BR"); // Define o idioma para Português (Brasil)
    await flutterTts.setSpeechRate(0.5); // Define a velocidade da fala (0.0 a 1.0)
    await flutterTts.setVolume(1.0); // Define o volume (0.0 a 1.0)
    await flutterTts.setPitch(1.0); // Define o tom (0.5 a 2.0)
  }

  // Função para falar o texto
  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // LISTA COMPLETA DE DICAS (TODAS VOGAIS, CONSOANTES E COMBINAÇÕES)
  final List<PronunciationTip> _allTips = [
    // ===== VOGAIS COMPLETAS =====
    PronunciationTip(
      sound: 'A',
      type: 'Vogal',
      gifAssetPath: 'assets/gifs/a_vowel.jpg',
      tips: const [
        {'title': 'Boca Aberta', 'description': 'Abra bem a boca, língua relaxada no fundo. Ex: "Casa"'},
      ],
    ),
    PronunciationTip(
      sound: 'E',
      type: 'Vogal',
      gifAssetPath: 'assets/gifs/e_vowel.jpg',
      tips: const [
        {'title': 'Semiaberto (É)', 'description': 'Boca semiaberta, lábios esticados. Ex: "Pé"'},
        {'title': 'Fechado (Ê)', 'description': 'Boca mais fechada, língua elevada. Ex: "Mesa"'},
      ],
    ),
    PronunciationTip(
      sound: 'I',
      type: 'Vogal',
      gifAssetPath: 'assets/gifs/i_vowel.jpg',
      tips: const [
        {'title': 'Língua Alta', 'description': 'Lábios esticados, língua no céu da boca. Ex: "Dia"'},
      ],
    ),
    PronunciationTip(
      sound: 'O',
      type: 'Vogal',
      gifAssetPath: 'assets/gifs/o_vowel.jpg',
      tips: const [
        {'title': 'Semiaberto (Ó)', 'description': 'Lábios arredondados. Ex: "Avó"'},
        {'title': 'Fechado (Ô)', 'description': 'Lábios mais fechados. Ex: "Avô"'},
      ],
    ),
    PronunciationTip(
      sound: 'U',
      type: 'Vogal',
      gifAssetPath: 'assets/gifs/u_vowel.jpg',
      tips: const [
        {'title': 'Boca Arredondada', 'description': 'Lábios projetados para frente. Ex: "Lua"'},
      ],
    ),

    // ===== CONSOANTES COMPLETAS =====
    PronunciationTip(
      sound: 'B',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/b_consonant.jpg',
      tips: const [
        {'title': 'Lábios Juntos', 'description': 'Explosão com vibração. Ex: "Bola"'},
      ],
    ),
    PronunciationTip(
      sound: 'C',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/c_consonant.jpg',
      tips: const [
        {'title': 'C (Forte)', 'description': 'Som de "K" (antes de A, O, U). Ex: "Casa"'},
        {'title': 'C (Suave)', 'description': 'Som de "S" (antes de E, I). Ex: "Cedo"'},
      ],
    ),
    PronunciationTip(
      sound: 'D',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/d_consonant.jpg',
      tips: const [
        {'title': 'Língua nos Dentes', 'description': 'Toque a língua atrás dos dentes. Ex: "Dado"'},
      ],
    ),
    PronunciationTip(
      sound: 'F',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/f_consonant.jpg',
      tips: const [
        {'title': 'Lábio e Dentes', 'description': 'Sopro contínuo. Ex: "Faca"'},
      ],
    ),
    PronunciationTip(
      sound: 'G',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/g_consonant.jpg',
      tips: const [
        {'title': 'G (Forte)', 'description': 'Som gutural (antes de A, O, U). Ex: "Gato"'},
        {'title': 'G (Suave)', 'description': 'Som de "J" (antes de E, I). Ex: "Gelo"'},
      ],
    ),
    PronunciationTip(
      sound: 'H',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/h_consonant.jpg',
      tips: const [
        {'title': 'Mudo', 'description': 'Geralmente não tem som. Ex: "Hora"'},
      ],
    ),
    PronunciationTip(
      sound: 'J',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/j_consonant.jpg',
      tips: const [
        {'title': 'Som de "J"', 'description': 'Língua no céu da boca. Ex: "Janela"'},
      ],
    ),
    PronunciationTip(
      sound: 'L',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/l_consonant.jpg',
      tips: const [
        {'title': 'L Claro', 'description': 'Toque a língua atrás dos dentes. Ex: "Lua"'},
        {'title': 'L Escuro', 'description': 'Som de "U" no final. Ex: "Brasil"'},
      ],
    ),
    PronunciationTip(
      sound: 'M',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/m_consonant.jpg',
      tips: const [
        {'title': 'Som Nasal', 'description': 'Lábios fechados. Ex: "Mão"'},
      ],
    ),
    PronunciationTip(
      sound: 'N',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/n_consonant.jpg',
      tips: const [
        {'title': 'Som Nasal', 'description': 'Língua no céu da boca. Ex: "Nariz"'},
      ],
    ),
    PronunciationTip(
      sound: 'P',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/p_consonant.jpg',
      tips: const [
        {'title': 'Lábios Juntos', 'description': 'Explosão sem vibração. Ex: "Pato"'},
      ],
    ),
    PronunciationTip(
      sound: 'Q',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/q_consonant.jpg',
      tips: const [
        {'title': 'Q (com U)', 'description': 'Sempre acompanhado de U. Ex: "Queijo"'},
      ],
    ),
    PronunciationTip(
      sound: 'R',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/r_consonant.jpg',
      tips: const [
        {'title': 'R Forte', 'description': 'Vibração (início/palavras com RR). Ex: "Rato"'},
        {'title': 'R Fraco', 'description': 'Toque leve (meio/fim). Ex: "Cara"'},
      ],
    ),
    PronunciationTip(
      sound: 'S',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/s_consonant.jpg',
      tips: const [
        {'title': 'S (Forte)', 'description': 'Som de "SS". Ex: "Passo"'},
        {'title': 'S (Suave)', 'description': 'Som de "Z". Ex: "Casa"'},
      ],
    ),
    PronunciationTip(
      sound: 'T',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/t_consonant.jpg',
      tips: const [
        {'title': 'Língua nos Dentes', 'description': 'Toque a língua atrás dos dentes. Ex: "Tatu"'},
      ],
    ),
    PronunciationTip(
      sound: 'V',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/v_consonant.jpg',
      tips: const [
        {'title': 'Lábio e Dentes', 'description': 'Com vibração. Ex: "Vaca"'},
      ],
    ),
    PronunciationTip(
      sound: 'X',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/x_consonant.jpg',
      tips: const [
        {'title': 'X (CH)', 'description': 'Ex: "Xícara"'},
        {'title': 'X (Z)', 'description': 'Ex: "Exame"'},
        {'title': 'X (S)', 'description': 'Ex: "Texto"'},
      ],
    ),
    PronunciationTip(
      sound: 'Z',
      type: 'Consoante',
      gifAssetPath: 'assets/gifs/z_consonant.jpg',
      tips: const [
        {'title': 'Som de "Z"', 'description': 'Com vibração. Ex: "Zebra"'},
      ],
    ),

    // ===== COMBINAÇÕES COMPLETAS =====
    PronunciationTip(
      sound: 'CH',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/ch_combination.jpg',
      tips: const [
        {'title': 'Som de "CH"', 'description': 'Lábios para frente. Ex: "Chave"'},
      ],
    ),
    PronunciationTip(
      sound: 'LH',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/lh_combination.jpg',
      tips: const [
        {'title': 'Som de "LH"', 'description': 'Língua no céu da boca. Ex: "Folha"'},
      ],
    ),
    PronunciationTip(
      sound: 'NH',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/nh_combination.jpg',
      tips: const [
        {'title': 'Som de "NH"', 'description': 'Som nasal. Ex: "Banho"'},
      ],
    ),
    PronunciationTip(
      sound: 'QU',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/qu_combination.jpg',
      tips: const [
        {'title': 'QU (com U mudo)', 'description': 'Ex: "Queijo"'},
        {'title': 'QU (com U pronunciado)', 'description': 'Ex: "Quase"'},
      ],
    ),
    PronunciationTip(
      sound: 'GU',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/gu_combination.jpg',
      tips: const [
        {'title': 'GU (com U mudo)', 'description': 'Ex: "Guitarra"'},
        {'title': 'GU (com U pronunciado)', 'description': 'Ex: "Água"'},
      ],
    ),
    PronunciationTip(
      sound: 'SS',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/ss_combination.jpg',
      tips: const [
        {'title': 'SS (Forte)', 'description': 'Som de "S" marcado. Ex: "Passo"'},
      ],
    ),
    PronunciationTip(
      sound: 'RR',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/rr_combination.jpg',
      tips: const [
        {'title': 'RR (Forte)', 'description': 'Vibração acentuada. Ex: "Carro"'},
      ],
    ),
    PronunciationTip(
      sound: 'SC',
      type: 'Combinação',
      gifAssetPath: 'assets/gifs/sc_combination.jpg',
      tips: const [
        {'title': 'SC (com som de S)', 'description': 'Ex: "Nascer"'},
        {'title': 'SC (com som de SK)', 'description': 'Ex: "Piscina"'},
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Inicializa o TTS quando o widget é construído pela primeira vez
    _initializeTts();

    final vowels = _allTips.where((tip) => tip.type == 'Vogal').toList();
    final consonants = _allTips.where((tip) => tip.type == 'Consoante').toList();
    final combinations = _allTips.where((tip) => tip.type == 'Combinação').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicas de Pronúncia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCategory('Vogais', vowels, context),
            _buildCategory('Consoantes', consonants, context),
            _buildCategory('Encontros Consonantais', combinations, context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String title, List<PronunciationTip> tips, BuildContext context) {
    tips.sort((a, b) => a.sound.compareTo(b.sound));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tips.map((tip) => _buildSoundButton(tip, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildSoundButton(PronunciationTip tip, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _speak(tip.sound); // Toca o texto da pronúncia usando TTS
        _showTipDetail(tip, context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Center(
          child: Text(
            tip.sound,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  void _showTipDetail(PronunciationTip tip, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TipDetailModal(tip: tip, flutterTts: flutterTts), // Passe a instância do flutterTts para o modal
    );
  }
}