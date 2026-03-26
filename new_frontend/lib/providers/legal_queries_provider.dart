import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dharma/services/api/legal_queries_api.dart';
import 'package:dharma/services/api/ai_gateway_api.dart';
import 'package:dharma/models/chat_message.dart';

class LegalQueriesProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _currentSessionId;

  bool get isLoading => _isLoading;
  String? get currentSessionId => _currentSessionId;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> get sessions => _sessions;

  Future<void> createNewSession() async {
    final result = await LegalQueriesApi.createThread({'title': 'New Chat', 'status': 'active'});
    _currentSessionId = result['id'];
    _messages = [];
    notifyListeners();
  }

  void openSession(String sessionId) {
    _currentSessionId = sessionId;
    _messages = [];
    notifyListeners();
  }

  Future<void> loadMessages() async {
    if (_currentSessionId == null) return;
    try {
      final results = await LegalQueriesApi.listMessages(_currentSessionId!);
      _messages = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ChatMessage(
          sender: map['role'] ?? map['sender'] ?? 'user',
          text: map['content'] ?? map['text'] ?? '',
          timestamp: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
      _messages = _messages.reversed.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Stream<List<ChatMessage>> messagesStream() {
    return Stream.fromFuture(Future(() async { await loadMessages(); return _messages; }));
  }

  Future<void> sendMessage(String message, {List<Map<String, dynamic>>? attachments, String language = 'en'}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;
    if (_currentSessionId == null) await createNewSession();

    _messages.insert(0, ChatMessage(sender: 'user', text: trimmed, timestamp: DateTime.now()));
    _isLoading = true;
    notifyListeners();

    try {
      await LegalQueriesApi.addMessage(_currentSessionId!, {'role': 'user', 'content': trimmed});
      final data = await AiGatewayApi.legalChat(sessionId: _currentSessionId!, message: trimmed, language: language, attachments: attachments);
      final reply = data['reply'] as String? ?? '';
      final rawTitle = data['title'] as String? ?? 'New Chat';
      final title = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;

      await LegalQueriesApi.addMessage(_currentSessionId!, {'role': 'ai', 'content': reply});
      try {
        final threadData = await LegalQueriesApi.getThread(_currentSessionId!);
        if ((threadData['title'] ?? 'New Chat') == 'New Chat') {
          await LegalQueriesApi.updateThread(_currentSessionId!, {'title': title});
        }
      } catch (_) {}

      _messages.insert(0, ChatMessage(sender: 'ai', text: reply, timestamp: DateTime.now()));
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? 'Unable to get legal response.';
      _messages.insert(0, ChatMessage(sender: 'ai', text: '⚠️ $msg', timestamp: DateTime.now()));
    } catch (_) {
      _messages.insert(0, ChatMessage(sender: 'ai', text: '⚠️ Unable to get legal response. Please try again.', timestamp: DateTime.now()));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessions() async {
    try {
      final results = await LegalQueriesApi.listThreads();
      _sessions = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {'id': map['id'] ?? '', 'title': map['title'] ?? 'New Chat'};
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading legal chat sessions: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> chatSessionsStream() {
    return Stream.fromFuture(Future(() async { await loadSessions(); return _sessions; }));
  }
}
