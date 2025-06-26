// lib/screens/main_menu/questionnaire_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/models/questionnaire.dart';
import 'package:funfono1/models/user.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/screens/main_menu/menu_screen.dart';
import 'package:funfono1/screens/auth/welcome_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  bool _isLoading = true;

  // Variáveis para as respostas do questionário
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedRespondentType;
  List<String> _selectedSpeechDiagnoses = [];
  List<String> _selectedPronunciationDifficulties = [];
  String? _speechTherapyHistory;
  List<String> _selectedFavoriteFoods = [];
  List<String> _selectedHobbies = [];
  List<String> _selectedMovieGenres = [];
  String? _selectedOccupation;
  List<String> _selectedMusicTypes = [];
  List<String> _selectedDailyInteractions = [];
  String? _selectedCommunicationPreference;
  List<String> _selectedAppExpectations = [];
  String? _selectedPracticeFrequency;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndCheckQuestionnaire();
  }

  Future<void> _loadCurrentUserAndCheckQuestionnaire() async {
    _currentUser = await AuthStateService().getLoggedInUser();
    if (!mounted) return;

    if (_currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    // Verificar se o questionário já foi preenchido
    // A rota /users/[id]/status do backend verifica se existe um questionário para o user_id.
    final hasQuestionnaire = await apiService.checkUserQuestionnaireStatus(_currentUser!.id);

    if (mounted) {
      if (hasQuestionnaire) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      } else {
        setState(() {
          _isLoading = false; // Pronto para exibir o formulário
        });
      }
    }
  }

  Future<void> _submitQuestionnaire() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não logado. Tente novamente.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final apiService = Provider.of<ApiService>(context, listen: false);

      // Garanta que todas as listas não sejam nulas, mesmo que vazias
      final questionnaire = Questionnaire(
        userId: _currentUser!.id,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender ?? 'Prefiro não dizer',
        respondentType: _selectedRespondentType ?? 'Outros',
        speechDiagnoses: _selectedSpeechDiagnoses.isEmpty ? ['Não informado'] : _selectedSpeechDiagnoses, // Garante que a lista não é vazia se backend não aceitar
        difficultSounds: _selectedPronunciationDifficulties.isEmpty ? ['Não informado'] : _selectedPronunciationDifficulties, // Garante que a lista não é vazia
        speechTherapyHistory: _speechTherapyHistory ?? 'Não informado',
        favoriteFoods: _selectedFavoriteFoods.isEmpty ? ['Não informado'] : _selectedFavoriteFoods, // Garante que a lista não é vazia
        hobbies: _selectedHobbies.isEmpty ? ['Não informado'] : _selectedHobbies, // Garante que a lista não é vazia
        movieGenres: _selectedMovieGenres.isEmpty ? ['Não informado'] : _selectedMovieGenres, // Garante que a lista não é vazia
        occupation: _selectedOccupation ?? 'Não informado',
        musicTypes: _selectedMusicTypes.isEmpty ? ['Não informado'] : _selectedMusicTypes, // Garante que a lista não é vazia
        communicationPeople: _selectedDailyInteractions.isEmpty ? ['Não informado'] : _selectedDailyInteractions, // Garante que a lista não é vazia
        communicationPreference: _selectedCommunicationPreference ?? 'Não informado',
        appExpectations: _selectedAppExpectations.isEmpty ? ['Não informado'] : _selectedAppExpectations, // Garante que a lista não é vazia
        practiceFrequency: _selectedPracticeFrequency ?? 'Não informado',
      );

      final success = await apiService.saveQuestionnaire(questionnaire);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Questionário salvo com sucesso!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao salvar questionário. Tente novamente.')),
          );
        }
      }
    }
  }

  // Widget auxiliar para CheckboxListTile ou FilterChip (usado para múltiplas escolhas)
  Widget _buildMultiChoiceChips({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selected) {
                onChanged(option);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    // Adicione dispose para outros TextEditingControllers aqui, se houver
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionário Inicial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('1. Informações Pessoais', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: '1.1. Qual a sua idade?',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Idade inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('1.2. Gênero:', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione seu gênero'),
                items: ['Masculino', 'Feminino', 'Prefiro não dizer', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              const Text('1.3. Você é o paciente ou está respondendo como responsável?', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedRespondentType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione'),
                items: ['Sou o paciente', 'Sou pai/mãe/responsável', 'Sou cuidador ou acompanhante', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRespondentType = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 30),
              const Text('2. Informações Clínicas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildMultiChoiceChips(
                title: '2.1. Qual o diagnóstico relacionado à sua fala ou linguagem?',
                options: ['Atraso de fala', 'Apraxia de fala', 'Dislalia', 'Disfemia', 'Disartria', 'Outros'],
                selectedValues: _selectedSpeechDiagnoses,
                onChanged: (item) {
                  setState(() {
                    if (_selectedSpeechDiagnoses.contains(item)) {
                      _selectedSpeechDiagnoses.remove(item);
                    } else {
                      _selectedSpeechDiagnoses.add(item);
                    }
                  });
                },
              ),
              _buildMultiChoiceChips(
                title: '2.2. Quais sons ou letras vocais você tem mais dificuldade em pronunciar?',
                options: ['Sons com “R”', 'Sons com “S” ou “Z”', 'Sons nasais', 'Vogais abertas/fechadas', 'Combinações consonantais', 'Outros'],
                selectedValues: _selectedPronunciationDifficulties,
                onChanged: (item) {
                  setState(() {
                    if (_selectedPronunciationDifficulties.contains(item)) {
                      _selectedPronunciationDifficulties.remove(item);
                    } else {
                      _selectedPronunciationDifficulties.add(item);
                    }
                  });
                },
              ),
              const Text('2.3. Você já realizou acompanhamento com fonoaudiólogo anteriormente?', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _speechTherapyHistory,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione'),
                items: ['Sim, atualmente estou em acompanhamento', 'Sim, mas não faço mais', 'Não, será minha primeira vez', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _speechTherapyHistory = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 30),
              const Text('3. Estilo de Vida e Preferências', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildMultiChoiceChips(
                title: '3.1. Quais são suas comidas favoritas? (Selecione até 3)',
                options: ['Massas', 'Doces', 'Frutas', 'Salgados', 'Lanches rápidos', 'Outros'],
                selectedValues: _selectedFavoriteFoods,
                onChanged: (item) {
                  setState(() {
                    if (_selectedFavoriteFoods.contains(item)) {
                      _selectedFavoriteFoods.remove(item);
                    } else if (_selectedFavoriteFoods.length < 3) {
                      _selectedFavoriteFoods.add(item);
                    }
                  });
                },
              ),
              _buildMultiChoiceChips(
                title: '3.2. Quais são seus hobbies ou atividades de lazer?',
                options: ['Esportes', 'Desenhar ou pintar', 'Jogar videogame', 'Ler livros ou gibis', 'Ouvir música', 'Outros'],
                selectedValues: _selectedHobbies,
                onChanged: (item) {
                  setState(() {
                    if (_selectedHobbies.contains(item)) {
                      _selectedHobbies.remove(item);
                    } else {
                      _selectedHobbies.add(item);
                    }
                  });
                },
              ),
              _buildMultiChoiceChips(
                title: '3.3. Você costuma assistir a séries ou filmes? Quais gêneros prefere?',
                options: ['Ação ou aventura', 'Comédia', 'Animação', 'Romance', 'Ficção científica ou fantasia', 'Outros'],
                selectedValues: _selectedMovieGenres,
                onChanged: (item) {
                  setState(() {
                    if (_selectedMovieGenres.contains(item)) {
                      _selectedMovieGenres.remove(item);
                    } else {
                      _selectedMovieGenres.add(item);
                    }
                  });
                },
              ),
              const Text('3.4. Qual sua profissão ou ocupação atual?', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedOccupation,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione'),
                items: ['Estudante', 'Profissional da área da saúde', 'Trabalhador do comércio/serviços', 'Profissional autônomo', 'Aposentado/desempregado', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOccupation = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildMultiChoiceChips(
                title: '3.5. Que tipo de música você costuma ouvir?',
                options: ['Pop', 'Sertanejo', 'Funk', 'Rock', 'Música infantil', 'Outros'],
                selectedValues: _selectedMusicTypes,
                onChanged: (item) {
                  setState(() {
                    if (_selectedMusicTypes.contains(item)) {
                      _selectedMusicTypes.remove(item);
                    } else {
                      _selectedMusicTypes.add(item);
                    }
                  });
                },
              ),

              const SizedBox(height: 30),
              const Text('4. Hábitos de Comunicação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildMultiChoiceChips(
                title: '4.1. Com quem você mais conversa no dia a dia?',
                options: ['Pais ou responsáveis', 'Amigos', 'Colegas de escola/trabalho', 'Professores', 'Cuidadores ou profissionais da saúde', 'Outros'],
                selectedValues: _selectedDailyInteractions,
                onChanged: (item) {
                  setState(() {
                    if (_selectedDailyInteractions.contains(item)) {
                      _selectedDailyInteractions.remove(item);
                    } else {
                      _selectedDailyInteractions.add(item);
                    }
                  });
                },
              ),
              const Text('4.2. Você prefere se comunicar por:', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedCommunicationPreference,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione'),
                items: ['Conversa falada (voz)', 'Conversa por mensagens (texto)', 'Áudios gravados', 'Mistura de todos', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCommunicationPreference = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 30),
              const Text('5. Expectativas com o App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildMultiChoiceChips(
                title: '5.1. O que você espera melhorar com este aplicativo?',
                options: ['Falar com mais clareza', 'Ter mais confiança ao conversar', 'Aprender a pronunciar sons corretamente', 'Treinar sozinho(a) de forma divertida', 'Ajudar na continuidade da terapia', 'Outros'],
                selectedValues: _selectedAppExpectations,
                onChanged: (item) {
                  setState(() {
                    if (_selectedAppExpectations.contains(item)) {
                      _selectedAppExpectations.remove(item);
                    } else {
                      _selectedAppExpectations.add(item);
                    }
                  });
                },
              ),
              const Text('5.2. Com que frequência você gostaria de praticar com o app?', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedPracticeFrequency,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione'),
                items: ['Todos os dias', 'De 2 a 3 vezes por semana', 'Apenas nos dias de terapia', 'Quando estiver com tempo livre', 'Outros']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPracticeFrequency = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuestionnaire,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Salvar Questionário',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}