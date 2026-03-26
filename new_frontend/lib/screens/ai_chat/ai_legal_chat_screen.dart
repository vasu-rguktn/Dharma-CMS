import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dharma/core/api_service.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/complaint_provider.dart';
import 'package:dharma/providers/settings_provider.dart';
import 'package:dharma/l10n/app_localizations.dart';

/// Statically held chat state so it persists across route pushes.
class _ChatState {
  static final List<_Msg> messages = [];
  static final Map<String, String> answers = {};
  static final List<PlatformFile> evidence = [];
  static int currentQ = -2;
  static bool hasStarted = false;
  static bool allowInput = false;
  static bool isLoading = false;
  static void reset() { messages.clear(); answers.clear(); evidence.clear(); currentQ = -2; hasStarted = false; allowInput = false; isLoading = false; }
}

class _Msg {
  final String sender;
  final String text;
  _Msg(this.sender, this.text);
}

class AiLegalChatScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDraft;
  const AiLegalChatScreen({super.key, this.initialDraft});
  @override
  State<AiLegalChatScreen> createState() => _AiLegalChatScreenState();
}

class _AiLegalChatScreenState extends State<AiLegalChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Dio get _dio => ApiService.dio;
  static const Color orange = Color(0xFFFC633C);

  bool _isAnonymous = false;
  bool _isChatCompleted = false;
  String? _finalSummary;
  String? _finalClassification;
  List<Map<String, String>> _dynamicHistory = [];
  bool _isDynamicMode = false;

  static final _questions = [
    _Q('What is your full name?', 'full_name'),
    _Q('What is your phone number?', 'phone'),
    _Q('What is your address?', 'address'),
    _Q('What type of complaint? (e.g., Theft, Assault, Harassment, Fraud, Cyber Crime, Other)', 'complaint_type'),
    _Q('Please describe what happened in detail:', 'initial_details'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) _loadDraft(widget.initialDraft!);
    if (_ChatState.isLoading) { _ChatState.isLoading = false; _ChatState.allowInput = true; }
  }

  void _loadDraft(Map<String, dynamic> draft) {
    _ChatState.reset();
    final chatData = draft['chatData'] as Map<String, dynamic>?;
    if (chatData != null) {
      final msgs = chatData['messages'] as List<dynamic>?;
      if (msgs != null) {
        for (final m in msgs) { _ChatState.messages.add(_Msg(m['sender'], m['text'])); }
      }
      final ans = chatData['answers'] as Map<String, dynamic>?;
      if (ans != null) { ans.forEach((k, v) => _ChatState.answers[k] = v.toString()); }
    }
  }

  void _scroll() { Future.delayed(const Duration(milliseconds: 100), () { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  void _addMsg(String sender, String text) { setState(() => _ChatState.messages.add(_Msg(sender, text))); _scroll(); }

  Future<void> _startChat() async {
    final proceed = await _showTypeDialog();
    if (!proceed) return;
    _ChatState.reset();
    _ChatState.hasStarted = true;
    _ChatState.currentQ = 0;
    _isDynamicMode = false;
    _isChatCompleted = false;
    _dynamicHistory = [];

    if (_isAnonymous) {
      _ChatState.answers['full_name'] = 'Anonymous';
      _ChatState.answers['phone'] = 'N/A';
      _ChatState.answers['address'] = 'N/A';
      _ChatState.currentQ = 3;
    }

    setState(() => _ChatState.allowInput = true);
    _addMsg('bot', _questions[_ChatState.currentQ].question);
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _addMsg('user', text);

    if (_isDynamicMode) {
      await _sendDynamicMessage(text);
      return;
    }

    final q = _questions[_ChatState.currentQ];
    _ChatState.answers[q.key] = text;
    _ChatState.currentQ++;

    if (_ChatState.currentQ < _questions.length) {
      _addMsg('bot', _questions[_ChatState.currentQ].question);
    } else {
      _isDynamicMode = true;
      await _sendDynamicMessage(text);
    }
  }

  Future<void> _sendDynamicMessage(String text) async {
    setState(() { _ChatState.isLoading = true; _ChatState.allowInput = false; });
    _addMsg('bot', '...');

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final lang = settingsProvider.chatLanguageCode ?? settingsProvider.locale?.languageCode ?? 'en';
      _dynamicHistory.add({'role': 'user', 'content': text});

      final data = FormData();
      data.fields.addAll([
        MapEntry('full_name', _ChatState.answers['full_name'] ?? ''),
        MapEntry('address', _ChatState.answers['address'] ?? ''),
        MapEntry('phone', _ChatState.answers['phone'] ?? ''),
        MapEntry('complaint_type', _ChatState.answers['complaint_type'] ?? ''),
        MapEntry('initial_details', _ChatState.answers['initial_details'] ?? ''),
        MapEntry('language', lang),
        MapEntry('is_anonymous', _isAnonymous.toString()),
        MapEntry('chat_history', jsonEncode(_dynamicHistory)),
      ]);

      final res = await _dio.post('/ai/complaint/chat-step', data: data);
      final body = res.data as Map<String, dynamic>;

      setState(() => _ChatState.messages.removeLast()); // Remove "..."

      if (body['status'] == 'complete') {
        _finalSummary = body['summary'] ?? body['reply'] ?? '';
        _finalClassification = body['classification'] ?? '';
        _isChatCompleted = true;
        _addMsg('bot', '✅ Your complaint has been recorded.\n\n📋 Summary:\n$_finalSummary\n\n🔍 Classification: $_finalClassification');
        setState(() => _ChatState.allowInput = false);
      } else {
        final reply = body['reply'] ?? body['question'] ?? 'Please continue...';
        _dynamicHistory.add({'role': 'assistant', 'content': reply});
        _addMsg('bot', reply);
        setState(() => _ChatState.allowInput = true);
      }
    } catch (e) {
      setState(() => _ChatState.messages.removeLast());
      _addMsg('bot', '⚠️ Error: ${e is DioException ? (e.response?.data?['detail'] ?? e.message) : e}');
      setState(() => _ChatState.allowInput = true);
    } finally {
      setState(() => _ChatState.isLoading = false);
    }
  }

  Future<void> _createPetition() async {    if (_finalSummary == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.user?.uid ?? '';

    context.push('/petitions/create', extra: {
      'petitionerName': _isAnonymous ? 'Anonymous' : (_ChatState.answers['full_name'] ?? ''),
      'phoneNumber': _ChatState.answers['phone'] ?? '',
      'address': _ChatState.answers['address'] ?? '',
      'type': _ChatState.answers['complaint_type'] ?? 'Other',
      'grounds': _finalSummary ?? '',
      'classification': _finalClassification ?? '',
      'isAnonymous': _isAnonymous,
      'userId': uid,
    });
  }

  Future<void> _saveDraft() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final complaint = Provider.of<ComplaintProvider>(context, listen: false);
    final uid = auth.user?.uid ?? '';
    final saved = await complaint.saveChatAsDraft(
      userId: uid,
      title: 'Chat Draft - ${DateTime.now().toString().split('.').first}',
      chatData: {
        'messages': _ChatState.messages.map((m) => {'sender': m.sender, 'text': m.text}).toList(),
        'answers': _ChatState.answers,
      },
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Draft saved!' : 'Failed to save draft'), backgroundColor: saved ? Colors.green : Colors.red));
  }

  Future<bool> _showTypeDialog() async {
    _isAnonymous = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.gavel_rounded, color: orange)), const SizedBox(width: 12), const Expanded(child: Text('Select Type'))]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _typeBtn(ctx, 'Complaint for Self', Icons.person, Colors.blue, () { _isAnonymous = false; Navigator.pop(ctx, true); }),
          const SizedBox(height: 12),
          _typeBtn(ctx, 'Complaint for Others', Icons.group, Colors.purple, () { _isAnonymous = false; Navigator.pop(ctx, true); }),
          const SizedBox(height: 16),
          TextButton.icon(icon: const Icon(Icons.visibility_off, size: 16), label: const Text('Anonymous'), onPressed: () { _isAnonymous = true; Navigator.pop(ctx, true); }),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))],
      ),
    );
    return result ?? false;
  }

  Widget _typeBtn(BuildContext ctx, String title, IconData icon, Color c, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: c, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        title: Text(l.aiChat),
        actions: [
          if (_ChatState.hasStarted) IconButton(icon: const Icon(Icons.save_outlined), tooltip: 'Save Draft', onPressed: _saveDraft),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'New Chat', onPressed: _startChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _ChatState.messages.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: orange.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Start a new conversation', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(onPressed: _startChat, icon: const Icon(Icons.add), label: Text(l.newCase), style: ElevatedButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
                    ]))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _ChatState.messages.length,
                    itemBuilder: (_, i) {
                      final m = _ChatState.messages[i];
                      final isUser = m.sender == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? orange : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                          ),
                          child: m.text == '...' ? const SizedBox(width: 40, child: LinearProgressIndicator(color: orange)) : Text(m.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
                        ),
                      );
                    },
                  ),
          ),
          // Completed actions
          if (_isChatCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(children: [
                Expanded(child: ElevatedButton.icon(onPressed: _createPetition, icon: const Icon(Icons.post_add), label: const Text('Create Petition'), style: ElevatedButton.styleFrom(backgroundColor: orange))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: _startChat, icon: const Icon(Icons.refresh), label: const Text('New Chat'))),
              ]),
            ),
          // Input area
          if (_ChatState.hasStarted && !_isChatCompleted)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _ChatState.allowInput,
                    decoration: InputDecoration(hintText: 'Type your message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF0F2F5), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _ChatState.allowInput ? orange : Colors.grey,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _ChatState.allowInput ? _handleSend : null),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Q {
  final String question;
  final String key;
  const _Q(this.question, this.key);
}
