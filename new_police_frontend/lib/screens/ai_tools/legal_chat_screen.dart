import 'package:flutter/material.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class LegalChatScreen extends StatefulWidget {
  const LegalChatScreen({super.key});
  @override
  State<LegalChatScreen> createState() => _LegalChatScreenState();
}

class _LegalChatScreenState extends State<LegalChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  String? _sessionId;
  bool _isSending = false;

  @override
  void dispose() { _msgController.dispose(); _scrollController.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final result = await AiGatewayApi.legalChat(message: text, sessionId: _sessionId);
      _sessionId ??= result['sessionId']?.toString();
      setState(() {
        _messages.add({'role': 'assistant', 'content': result['response']?.toString() ?? result.toString()});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'error', 'content': 'Error: $e'});
      });
    }
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Legal AI Chat', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Ask any legal question', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ]))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF1A237E) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(m['content'] ?? '', style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.4)),
                      ),
                    );
                  },
                ),
        ),
        if (_isSending) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(hintText: 'Type your question...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _isSending ? null : _send, icon: const Icon(Icons.send, color: Color(0xFF1A237E))),
          ]),
        ),
      ],
    );
  }
}
