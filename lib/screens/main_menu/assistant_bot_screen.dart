import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:funfono1/api/api_service.dart';

class AssistantBotScreen extends StatefulWidget {
  const AssistantBotScreen({super.key});

  @override
  State<AssistantBotScreen> createState() => _AssistantBotScreenState();
}

class _AssistantBotScreenState extends State<AssistantBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text': 'Olá! Sou seu assistente FunFono. Posso ajudar com dúvidas sobre fonoaudiologia, pronúncia, ou sobre o aplicativo. No que posso ajudar?',
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': userMessage});
      _isSending = true;
    });

    _scrollToBottom();

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.askAssistantBot(userMessage);
      final botResponse = (response?['response'] ?? 'Desculpe, não consegui processar sua pergunta no momento.')
          .replaceAll('**', '');

      setState(() {
        _messages.add({'role': 'bot', 'text': botResponse});
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Ocorreu um erro ao tentar obter a resposta. Tente novamente.'});
        _isSending = false;
      });
      print('Erro ao chamar API do bot: $e');
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInsets = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente FunFono'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                          color: isUser ? Colors.blue.shade900 : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input bar with perfect positioning
          Container(
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: bottomInsets > 0 ? bottomInsets : bottomPadding + 8.0,
              top: 8.0,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 12.0),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                _isSending
                    ? const CircularProgressIndicator()
                    : FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}