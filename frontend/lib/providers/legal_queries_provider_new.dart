/// Refactored Legal Queries Provider — uses backend API instead of direct Firestore.
///
/// BEFORE: Wrote messages directly to Firestore `legal_queries_chats` collection
///         and called the old backend URL directly with Dio.
/// AFTER:  All data goes through the new FastAPI backend.
///         Chat threads & messages stored via LEGAL_QUERY_THREADS API.
///         AI responses generated via the AI Gateway.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Dharma/services/api/legal_queries_api.dart';
import 'package:Dharma/services/api/ai_gateway_api.dart';
import '../models/chat_message.dart';

class LegalQueriesProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  String get _uid => _auth.currentUser!.uid;

  // Local message cache (replaces Firestore stream)
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Session list cache
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> get sessions => _sessions;

  /* ---------------- CREATE NEW SESSION ---------------- */
  Future<void> createNewSession() async {
    final result = await LegalQueriesApi.createThread(_uid, {
      'title': 'New Chat',
      'status': 'active',
    });
    _currentSessionId = result['id'];
    _messages = [];
    notifyListeners();
  }

  /* ---------------- OPEN SESSION ---------------- */
  void openSession(String sessionId) {
    _currentSessionId = sessionId;
    _messages = [];
    notifyListeners();
  }

  /* ---------------- LOAD MESSAGES FOR CURRENT SESSION ---------------- */
  Future<void> loadMessages() async {
    if (_currentSessionId == null) return;

    try {
      final results =
          await LegalQueriesApi.listMessages(_uid, _currentSessionId!);
      _messages = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ChatMessage(
          sender: map['role'] ?? 'user',
          text: map['content'] ?? '',
          timestamp: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
      // Reverse so newest is first (for ListView reverse)
      _messages = _messages.reversed.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /* ---------------- SEND MESSAGE ---------------- */
  Future<void> sendMessage(String message,
      {List<Map<String, dynamic>>? attachments, String language = 'en'}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;

    if (_currentSessionId == null) {
      await createNewSession();
    }

    // 1️⃣ Save USER message to backend
    String attachText = "";
    if (attachments != null && attachments.isNotEmpty) {
      final names = attachments.map((a) => a['name']).join(', ');
      attachText = " [Attached: $names]";
    }

    await LegalQueriesApi.addMessage(_uid, _currentSessionId!, {
      'role': 'user',
      'content': trimmed + attachText,
    });

    // Add to local cache immediately for responsiveness
    _messages.insert(
      0,
      ChatMessage(
          sender: 'user', text: trimmed + attachText, timestamp: DateTime.now()),
    );

    _isLoading = true;
    notifyListeners();

    try {
      // 2️⃣ Call AI Gateway
      String backendMessage = trimmed;
      if (language == 'te') {
        backendMessage += " (Please reply in Telugu language)";
      } else if (language != 'en') {
        backendMessage += " (Please reply in $language language)";
      }

      final response = await AiGatewayApi.legalChat(
        sessionId: _currentSessionId!,
        message: backendMessage,
        language: language,
        attachments: attachments,
      );

      final reply = response['reply'] as String? ?? 'No response received.';
      final rawTitle = response['title'] as String? ?? '';

      // 3️⃣ Save AI reply to backend
      await LegalQueriesApi.addMessage(_uid, _currentSessionId!, {
        'role': 'assistant',
        'content': reply,
      });

      _messages.insert(
        0,
        ChatMessage(sender: 'ai', text: reply, timestamp: DateTime.now()),
      );

      // 4️⃣ Update thread title if still "New Chat"
      if (rawTitle.isNotEmpty) {
        final title =
            rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;
        await LegalQueriesApi.updateThread(_uid, _currentSessionId!, {
          'title': title,
        });
      }
    } catch (e) {
      debugPrint('Legal Chat Error: $e');
      final errorMsg = '⚠️ Unable to get legal response. Please try again.';
      await LegalQueriesApi.addMessage(_uid, _currentSessionId!, {
        'role': 'assistant',
        'content': errorMsg,
      });
      _messages.insert(
        0,
        ChatMessage(sender: 'ai', text: errorMsg, timestamp: DateTime.now()),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /* ---------------- CHAT HISTORY (SESSIONS) ---------------- */
  Future<void> loadSessions() async {
    try {
      final results = await LegalQueriesApi.listThreads(_uid);
      _sessions = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {
          'id': map['id'],
          'title': map['title'] ?? 'New Chat',
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  /// Legacy compatibility: returns a stream-like wrapper.
  /// In the refactored version, call [loadSessions] then read [sessions].
  Stream<List<Map<String, dynamic>>> chatSessionsStream() async* {
    await loadSessions();
    yield _sessions;
  }

  /// Legacy compatibility: returns a stream-like wrapper for messages.
  Stream<List<ChatMessage>> messagesStream() async* {
    await loadMessages();
    yield _messages;
  }
}
