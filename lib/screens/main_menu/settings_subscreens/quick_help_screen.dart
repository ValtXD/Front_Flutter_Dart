// lib/screens/main_menu/settings_subscreens/quick_help_screen.dart

import 'package:flutter/material.dart';

class QuickHelpScreen extends StatelessWidget {
  const QuickHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda Rápida'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vindo à Ajuda Rápida do FunFono!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              'Este mini tutorial irá guiá-lo pelas principais funcionalidades do aplicativo. '
                  'Você encontrará informações sobre como usar os exercícios de pronúncia, '
                  'acompanhar seu progresso e muito mais.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            _buildHelpSection(
              context,
              'Como usar os Exercícios?',
              'Navegue até a seção "Exercícios" no menu principal. '
                  'Escolha o tipo de exercício (sons ou frases). '
                  'Siga as instruções na tela para pronunciar as palavras ou frases. '
                  'O aplicativo fornecerá feedback sobre sua pronúncia.',
            ),
            _buildHelpSection(
              context,
              'Acompanhando seu Progresso',
              'Na tela "Progresso", você pode visualizar gráficos do seu desempenho '
                  'e um histórico detalhado das suas tentativas de pronúncia. '
                  'Isso o ajudará a identificar áreas de melhoria.',
            ),
            _buildHelpSection(
              context,
              'O Mini Game "Foguete da Pronúncia"',
              'Na seção "Mini Games", selecione "Foguete da Pronúncia". '
                  'Desvie dos meteoros e atire para ganhar pontos. A cada 100 pontos, '
                  'você terá que pronunciar uma palavra para reabastecer seu foguete. '
                  'Acerte a pronúncia para continuar a aventura!',
            ),
            const SizedBox(height: 20),
            const Text(
              'Ainda tem dúvidas? Visite a seção "Contato / Suporte" para mais ajuda.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}