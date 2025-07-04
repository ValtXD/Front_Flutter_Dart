// lib/screens/main_menu/about_screen.dart

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o FunFono'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desenvolvedor:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'O FunFono foi desenvolvido como parte de um projeto acadêmico/final. Nosso objetivo é criar uma ferramenta acessível e divertida para auxiliar no desenvolvimento da fala e pronúncia, atendendo a diversas necessidades.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify, // <--- CORRIGIDO: textAlign é uma propriedade do Text
            ),
            SizedBox(height: 30),
            Text(
              'O que é o FunFono?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'O FunFono é um aplicativo inovador projetado para apoiar indivíduos no aprimoramento de suas habilidades de pronúncia. Utilizando a tecnologia de reconhecimento de voz e gamificação, o app oferece exercícios interativos e feedback em tempo real. É ideal para pessoas de todas as idades que buscam melhorar a clareza da fala, seja por desenvolvimento pessoal, reabilitação após condições como acidentes ou doenças, ou para quem está aprendendo um novo idioma. Nosso mini-game "Foguete da Pronúncia" é um exemplo de como tornamos o aprendizado divertido e engajador.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify, // <--- CORRIGIDO: textAlign é uma propriedade do Text
            ),
            SizedBox(height: 30),
            Text(
              'Versão: 1.0.0', // Você pode ajustar a versão
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}