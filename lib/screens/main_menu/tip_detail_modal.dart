import 'package:flutter/material.dart';
import 'package:funfono1/models/pronunciation_tip.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TipDetailModal extends StatefulWidget {
  final PronunciationTip tip;
  final FlutterTts flutterTts;

  const TipDetailModal({
    super.key,
    required this.tip,
    required this.flutterTts,
  });

  @override
  State<TipDetailModal> createState() => _TipDetailModalState();
}

class _TipDetailModalState extends State<TipDetailModal> {
  @override
  void initState() {
    super.initState();
    _speakOnOpen(); // Toca o som quando o modal é aberto
  }

  Future<void> _speakOnOpen() async {
    await widget.flutterTts.speak(widget.tip.sound);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Removido o 'title' padrão do AlertDialog para customizar o cabeçalho
      contentPadding: const EdgeInsets.all(0), // Remover padding padrão do content
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Para manter bordas arredondadas

      content: Column(
        mainAxisSize: MainAxisSize.min, // Para que o Column ocupe o mínimo de espaço vertical
        children: [
          // Título centralizado com estilo azul
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Text(
              widget.tip.sound,
              textAlign: TextAlign.center, // Centraliza o texto
              style: const TextStyle(
                fontSize: 34, // Um pouco maior para destaque
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Cor azul
              ),
            ),
          ),

          // Imagens (se existirem)
          if (widget.tip.gifAssetPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: ClipRRect( // Para arredondar as bordas das imagens
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(widget.tip.gifAssetPath, fit: BoxFit.cover),
              ),
            ),

          // Dicas de pronúncia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.tip.tips.map((tipDetail) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Espaçamento entre as dicas
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipDetail['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(tipDetail['description']!),
                  ],
                ),
              )).toList(),
            ),
          ),

          // Botões de Repetir Som e Fechar
          Padding(
            padding: const EdgeInsets.all(20.0), // Padding para os botões
            child: Column(
              children: [
                // Botão Repetir Som
                SizedBox(
                  width: double.infinity, // Ocupa a largura total disponível
                  child: ElevatedButton(
                    onPressed: () {
                      _speakOnOpen();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Cor de fundo azul
                      foregroundColor: Colors.white, // Cor do texto branco
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Borda arredondada
                      ),
                    ),
                    child: const Text(
                      'Repetir Som',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Espaço entre os botões
                // Botão Fechar (em formato de texto)
                SizedBox(
                  width: double.infinity, // Ocupa a largura total disponível
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue, // Cor do texto azul
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.blue, width: 2), // Borda azul
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}