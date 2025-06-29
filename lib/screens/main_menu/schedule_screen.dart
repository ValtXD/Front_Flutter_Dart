// lib/screens/main_menu/schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';
import 'package:funfono1/models/reminder.dart';
import 'package:funfono1/services/auth_state_service.dart';
import 'package:funfono1/models/user.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  User? _currentUser;
  bool _isLoading = true;
  List<Reminder> _reminders = [];
  int _selectedDay = 1; // 1 = Segunda, 7 = Domingo
  final TextEditingController _reminderTitleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndReminders();
  }

  @override
  void dispose() {
    _reminderTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserAndReminders() async {
    _currentUser = await AuthStateService().getLoggedInUser();
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não logado. Por favor, faça login novamente.')),
        );
        // Considere navegar para a tela de login
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
    await _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _reminders = await Provider.of<ApiService>(context, listen: false)
          .getReminders(_currentUser!.id);
    } catch (e) {
      print('Erro ao carregar lembretes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar lembretes.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addOrUpdateReminder({Reminder? reminderToEdit}) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado.')),
      );
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    bool success = false;
    String message = '';

    final String formattedTime = _selectedTime.hour.toString().padLeft(2, '0') +
        ':' +
        _selectedTime.minute.toString().padLeft(2, '0');

    if (reminderToEdit == null) { // Criar novo lembrete
      final newReminder = Reminder(
        userId: _currentUser!.id,
        title: _reminderTitleController.text,
        dayOfWeek: _selectedDay,
        time: formattedTime,
      );
      final created = await apiService.createReminder(newReminder);
      success = created != null;
      message = success ? 'Lembrete adicionado com sucesso!' : 'Falha ao adicionar lembrete.';
    } else { // Atualizar lembrete existente
      final updatedReminder = Reminder(
        id: reminderToEdit.id,
        userId: _currentUser!.id,
        title: _reminderTitleController.text,
        dayOfWeek: _selectedDay, // Ou use reminderToEdit.dayOfWeek se não for alterável no modal
        time: formattedTime,
        createdAt: reminderToEdit.createdAt,
      );
      success = await apiService.updateReminder(updatedReminder);
      message = success ? 'Lembrete atualizado com sucesso!' : 'Falha ao atualizar lembrete.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      if (success) {
        _reminderTitleController.clear();
        await _fetchReminders(); // Recarregar lembretes
        Navigator.of(context).pop(); // Fechar o modal
      }
    }
  }

  void _showReminderModal({Reminder? reminder}) {
    _reminderTitleController.text = reminder?.title ?? '';
    _selectedDay = reminder?.dayOfWeek ?? _selectedDay;
    _selectedTime = reminder != null
        ? TimeOfDay(
      hour: int.parse(reminder.time.split(':')[0]),
      minute: int.parse(reminder.time.split(':')[1]),
    )
        : TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reminder == null ? 'Novo Lembrete' : 'Editar Lembrete',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reminderTitleController,
                decoration: const InputDecoration(
                  labelText: 'Lembrete',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Dia da Semana',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Segunda')),
                        DropdownMenuItem(value: 2, child: Text('Terça')),
                        DropdownMenuItem(value: 3, child: Text('Quarta')),
                        DropdownMenuItem(value: 4, child: Text('Quinta')),
                        DropdownMenuItem(value: 5, child: Text('Sexta')),
                        DropdownMenuItem(value: 6, child: Text('Sábado')),
                        DropdownMenuItem(value: 7, child: Text('Domingo')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() { // setState do pai para atualizar o dia selecionado
                            _selectedDay = value;
                          });
                          // Rebuild do modal para refletir a mudança no dia selecionado
                          // O ideal seria usar um StateSetter ou outro gerenciador de estado para o modal
                          // Mas para simplicidade, um setState() externo ou um pop/push rápido funciona
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: Text(
                      'Horário: ${_selectedTime.format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _addOrUpdateReminder(reminderToEdit: reminder),
                    child: Text(reminder == null ? 'Salvar' : 'Atualizar'),
                  ),
                  if (reminder != null)
                    ElevatedButton(
                      onPressed: () async {
                        final bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Excluir Lembrete'),
                            content: const Text('Tem certeza que deseja excluir este lembrete?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
                            ],
                          ),
                        ) ?? false;
                        if (confirm) {
                          final success = await Provider.of<ApiService>(context, listen: false)
                              .deleteReminder(_currentUser!.id, reminder.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Lembrete excluído!' : 'Falha ao excluir.')),
                            );
                            if (success) {
                              await _fetchReminders(); // Recarregar lembretes
                              Navigator.of(context).pop(); // Fechar o modal
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Excluir'),
                    ),
                ],
              ),
              const SizedBox(height: 20), // Espaço para o teclado
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cronograma de Exercícios')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cronograma de Exercícios')),
        body: const Center(
          child: Text('Por favor, faça login para ver seu cronograma.'),
        ),
      );
    }

    final remindersByDay = <int, List<Reminder>>{};
    for (var i = 1; i <= 7; i++) {
      remindersByDay[i] = [];
    }
    for (var reminder in _reminders) {
      remindersByDay[reminder.dayOfWeek]?.add(reminder);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Exercícios'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Criar Lembrete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reminderTitleController,
              decoration: const InputDecoration(
                labelText: 'Título do Lembrete',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Dia da Semana',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Segunda')),
                      DropdownMenuItem(value: 2, child: Text('Terça')),
                      DropdownMenuItem(value: 3, child: Text('Quarta')),
                      DropdownMenuItem(value: 4, child: Text('Quinta')),
                      DropdownMenuItem(value: 5, child: Text('Sexta')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 7, child: Text('Domingo')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDay = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  child: Text(
                    'Horário: ${_selectedTime.format(context)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addOrUpdateReminder, // Sem argumento, para criar novo
              child: const Text('Adicionar Lembrete'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Meus Lembretes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            if (_reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Nenhum lembrete agendado ainda.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                children: remindersByDay.entries.map((entry) {
                  final day = entry.key;
                  final remindersForThisDay = entry.value;
                  if (remindersForThisDay.isEmpty) {
                    return const SizedBox.shrink(); // Não mostra dias sem lembretes
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: ExpansionTile(
                      title: Text(
                        _getDayName(day),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: remindersForThisDay.map((reminder) {
                        return ListTile(
                          title: Text(reminder.title),
                          subtitle: Text('Horário: ${reminder.time}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showReminderModal(reminder: reminder), // Abre modal para editar
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}