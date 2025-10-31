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
    _ChatQ(key: 'complaint_type', question: 'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)'),
    _ChatQ(key: 'details', question: 'Please describe your complaint in detail.'),
  ];
  Map<String, String> _answers = {};
  int _currentQ = -2; // -2 = Welcome, -1 = Let us begin, 0+ = questions
  bool _allowInput = false;
  bool _isLoading = false;
  bool _errored = false;
  bool _inputError = false;

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
      setState(() {
        _inputError = false;
      });
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
      String baseUrl;
      if (Theme.of(context).platform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:8000';
      } else {
        baseUrl = 'http://localhost:8000';
      }
      final url = '$baseUrl/complaint/summarize';
      final payload = {
        'full_name': _answers['full_name']!,
        'address': _answers['address']!,
        'phone': _answers['phone']!,
        'complaint_type': _answers['complaint_type']!,
        'details': _answers['details']!,
      };
      final resp = await _dio.post(url, data: payload);
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
        if (mounted) context.go(
          '/ai-chatbot-details',
          extra: {
            'answers': _answers,
            'summary': data['formal_summary'] ?? '',
            'classification': data['classification'] ?? ''
          },
        );
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
      setState(() { _inputError = true; });
      _inputFocus.requestFocus();
      return;
    }
    setState(() { _inputError = false; });
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
      backgroundColor: const Color(0xFFF5F8FE),
      body: SafeArea(
        child: Column(
          children: [
            ClipPath(
              clipper: _CurvedHeaderClipper(),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFFC633C),
                padding: const EdgeInsets.only(top: 24, left: 28, right: 28, bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Legal Assistant',
                      style: (theme.textTheme.headlineMedium ?? const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask me anything about legal matters',
                      style: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18, color: Colors.white)).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Loading...',
                      style: (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
                        color: Colors.grey[550],
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
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
                          margin: const EdgeInsets.symmetric(vertical: 3.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? const Color(0xFFFC633C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: msg.isUser
                                ? null
                                : Border.all(color: Colors.grey[200]!, width: 1.2),
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
            ),
            if (!_isLoading && !_errored && _allowInput)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Material(
                  elevation: 5,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _inputFocus,
                            enabled: _allowInput && !_isLoading,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: _currentQ >= 0 && _currentQ < _questions.length
                                  ? _questions[_currentQ].question
                                  : 'Type your message...',
                              errorText: _inputError ? "(Please enter your answer)" : null,
                              focusedBorder: _inputError
                                  ? OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red[300]!, width: 1.5), borderRadius: BorderRadius.circular(30))
                                  : InputBorder.none,
                            ),
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: "Voice input (coming soon)",
                            onPressed: () {},
                            icon: const Icon(Icons.mic, color: Color(0xFFFC633C)),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _handleSend,
                            icon: const Icon(Icons.send, color: Color(0xFFFC633C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(18.0),
                child: CircularProgressIndicator(color: Color(0xFFFC633C)),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25, size.height, size.width * 0.75, size.height - 32
    );
    path.quadraticBezierTo(
      size.width, size.height - 80, size.width, size.height - 12
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
