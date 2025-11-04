// lib/screens/ai_legal_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class AiLegalChatScreen extends StatefulWidget {
  const AiLegalChatScreen({super.key});

  @override
  State<AiLegalChatScreen> createState() => _AiLegalChatScreenState();
}

class _AiLegalChatScreenState extends State<AiLegalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final List<_ChatMessage> _messages = [];
  final Dio _dio = Dio();

  final List<_ChatQ> _questions = const [
    _ChatQ(key: 'full_name', question: 'What is your full name?'),
    _ChatQ(key: 'address', question: 'Where do you live (place / area)?'),
    _ChatQ(key: 'phone', question: 'What is your phone number?'),
    _ChatQ(
        key: 'complaint_type',
        question:
            'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)'),
    _ChatQ(key: 'details', question: 'Please describe your complaint in detail.'),
  ];

  Map<String, String> _answers = {};
  int _currentQ = -2; // -2 = Welcome, -1 = Let us begin, 0+ = questions
  bool _allowInput = false;
  bool _isLoading = false;
  bool _errored = false;
  bool _inputError = false;

  // Orange color
  static const Color orange = Color(0xFFFC633C);
  static const Color background = Color(0xFFF5F8FE);

  @override
  void initState() {
    super.initState();
    _startChatFlow();
  }

  Future<void> _startChatFlow() async {
    setState(() {
      _messages.clear();
      _currentQ = -2;
      _allowInput = false;
    });
    _addBot('Welcome to NyayaSetu');
    await Future.delayed(const Duration(seconds: 1));
    _addBot('Let us begin...');
    _currentQ = -1;
    setState(() {});
    await Future.delayed(const Duration(seconds: 2));
    _askNextQ();
  }

  void _addBot(String content) {
    _messages.add(_ChatMessage(user: 'AI', content: content, isUser: false));
    setState(() {});
  }

  void _addUser(String content) {
    _messages.add(_ChatMessage(user: 'You', content: content, isUser: true));
    setState(() {});
  }

  void _askNextQ() {
    _currentQ++;
    if (_currentQ < _questions.length) {
      _addBot(_questions[_currentQ].question);
      _allowInput = true;
      setState(() => _inputError = false);
      Timer(const Duration(milliseconds: 600), () => _inputFocus.requestFocus());
    } else {
      _submitToBackend();
    }
  }

  Future<void> _submitToBackend() async {
    setState(() {
      _isLoading = true;
      _allowInput = false;
    });
    try {
      final baseUrl = Theme.of(context).platform == TargetPlatform.android
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000';
      final resp = await _dio.post('$baseUrl/complaint/summarize', data: {
        'full_name': _answers['full_name']!,
        'address': _answers['address']!,
        'phone': _answers['phone']!,
        'complaint_type': _answers['complaint_type']!,
        'details': _answers['details']!,
      });

      final data = resp.data;
      _addBot('Complaint Summary:');
      _messages.add(_ChatMessage(
        user: 'AI',
        content: data['formal_summary'] ?? '(no summary)',
        isUser: false,
      ));
      _addBot('Classification: ${data['classification'] ?? '(none)'}');

      setState(() {
        _isLoading = false;
        _allowInput = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go(
            '/ai-chatbot-details',
            extra: {
              'answers': _answers,
              'summary': data['formal_summary'] ?? '',
              'classification': data['classification'] ?? '',
            },
          );
        }
      });
    } catch (e) {
      _addBot('Sorry, something went wrong. Please try again later.');
      setState(() {
        _isLoading = false;
        _allowInput = false;
        _errored = true;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (!_allowInput || _isLoading) return;
    if (text.isEmpty) {
      setState(() => _inputError = true);
      _inputFocus.requestFocus();
      return;
    }
    setState(() => _inputError = false);
    _controller.clear();
    _addUser(text);
    _answers[_questions[_currentQ].key] = text;
    _allowInput = false;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), _askNextQ);
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: orange,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Legal Assistant',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ask me anything about legal matters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── CHAT MESSAGES ──
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Loading...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser ? orange : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: msg.isUser
                                ? null
                                : Border.all(color: Colors.grey.shade300, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── INPUT FIELD ──
          if (!_isLoading && !_errored && _allowInput)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              color: background,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocus,
                          decoration: InputDecoration(
                            hintText: _currentQ >= 0 && _currentQ < _questions.length
                                ? _questions[_currentQ].question
                                : 'Type your message...',
                            border: InputBorder.none,
                            errorText: _inputError ? "Please enter your answer" : null,
                            errorStyle: const TextStyle(fontSize: 12),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: orange),
                        onPressed: () {},
                        tooltip: "Voice input (coming soon)",
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: orange),
                        onPressed: _handleSend,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── LOADER ──
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: orange),
            ),
        ],
      ),
    );
  }
}

// ── Helper Classes ──
class _ChatQ {
  final String key;
  final String question;
  const _ChatQ({required this.key, required this.question});
}

class _ChatMessage {
  final String user;
  final String content;
  final bool isUser;
  _ChatMessage({required this.user, required this.content, required this.isUser});
}