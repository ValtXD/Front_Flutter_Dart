// lib/screens/main_menu/tip_detail_modal.dart

import 'package:flutter/material.dart';
import 'package:funfono1/models/pronunciation_tip.dart'; // NOVO IMPORT

class TipDetailModal extends StatelessWidget {
  final PronunciationTip tip;

  const TipDetailModal({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tip.sound,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              // Área para o GIF de demonstração
              // Note: Usar Image.asset para GIFs é direto. Verifique o tamanho do GIF para melhor desempenho.
              if (tip.gifAssetPath.isNotEmpty)
                Container(
                  height: 150, // Ajuste a altura conforme necessário
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      tip.gifAssetPath,
                      fit: BoxFit.contain, // ou BoxFit.cover, dependendo do GIF
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.red, size: 50),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Dicas textuais
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tip.tips.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['title']!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t['description']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o modal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}