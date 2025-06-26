// lib/screens/exercises/sounds_exercise_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:funfono1/screens/exercises/sound_exercise_screen.dart';

class SoundsExerciseSelectionScreen extends StatefulWidget {
  const SoundsExerciseSelectionScreen({super.key});

  @override
  State<SoundsExerciseSelectionScreen> createState() => _SoundsExerciseSelectionScreenState();
}

class _SoundsExerciseSelectionScreenState extends State<SoundsExerciseSelectionScreen> {
  String? _selectedCategory; // 'Vogais', 'Consoantes', 'Combinações'
  List<String> _selectedSounds = []; // Sons específicos (ex: 'r', 's', 'ch')

  // Listas de sons baseadas no seu formulário e exemplos
  final List<String> _vowels = ['a', 'e', 'i', 'o', 'u'];
  final List<String> _consonants = [
    'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q',
    'r', 's', 't', 'v', 'w', 'x', 'y', 'z'
  ]; // Adicione consoantes que fazem sentido para fonoaudiologia
  final List<String> _combinations = [
    'bl', 'br', 'ch', 'cl', 'cr', 'dr', 'fl', 'fr', 'gl', 'gr', 'lh', 'nh',
    'pl', 'pr', 'tr', 'vr'
  ]; // Combinações comuns (ajuste conforme necessário)

  List<String> get _availableSounds {
    switch (_selectedCategory) {
      case 'Vogais':
        return _vowels;
      case 'Consoantes':
        return _consonants;
      case 'Combinações':
        return _combinations;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher Sons para Praticar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecione uma categoria:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escolha a categoria'),
              items: ['Vogais', 'Consoantes', 'Combinações']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedSounds = []; // Limpa seleções anteriores ao mudar de categoria
                });
              },
              validator: (value) => value == null ? 'Selecione uma categoria' : null,
            ),
            const SizedBox(height: 20),
            if (_selectedCategory != null) ...[
              const Text(
                'Selecione os sons específicos:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0, // Espaço horizontal entre os chips
                runSpacing: 4.0, // Espaço vertical entre as linhas de chips
                children: _availableSounds.map((sound) {
                  final isSelected = _selectedSounds.contains(sound);
                  return FilterChip(
                    label: Text(sound.toUpperCase()),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedSounds.add(sound);
                        } else {
                          _selectedSounds.remove(sound);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),
              if (_selectedSounds.isEmpty && _selectedCategory != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Selecione pelo menos um som.', style: TextStyle(color: Colors.red)),
                ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _selectedSounds.isNotEmpty
                  ? () {
                // Navegar para a tela de exercício de som, passando os sons selecionados
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SoundExerciseScreen(
                      selectedSounds: _selectedSounds,
                      selectedCategory: _selectedCategory,
                    ),
                  ),
                );
              }
                  : null, // Desabilita o botão se nenhum som for selecionado
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Iniciar Exercício de Sons',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}