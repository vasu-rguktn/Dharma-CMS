/// Legal Queries Provider — refactored to use backend API instead of direct Firestore.
///
/// BEFORE: Wrote messages directly to Firestore `legal_queries_chats` collection
///         and called the old backend URL directly with Dio.
/// AFTER:  All data goes through the new FastAPI backend.
///         Chat threads & messages stored via LEGAL_QUERY_THREADS API.
///         AI responses generated via the AI Gateway.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

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

  // ── Local caches (replaces Firestore streams) ──────────────────────

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

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

  /* ---------------- LOAD MESSAGES (replaces Firestore stream) -------- */
  Future<void> loadMessages() async {
    if (_currentSessionId == null) return;

    try {
      final results =
          await LegalQueriesApi.listMessages(_uid, _currentSessionId!);
      _messages = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ChatMessage(
          sender: map['role'] ?? map['sender'] ?? 'user',
          text: map['content'] ?? map['text'] ?? '',
          timestamp:
              DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
      // Reverse so newest is first (for ListView reverse)
      _messages = _messages.reversed.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /* ---------------- MESSAGES STREAM (compatibility wrapper) ---------- */
  /// Returns a stream that emits the current message list.
  /// Screens using StreamBuilder can switch to this.
  Stream<List<ChatMessage>> messagesStream() {
    return Stream.fromFuture(Future(() async {
      await loadMessages();
      return _messages;
    }));
  }

  /* ---------------- SEND MESSAGE ---------------- */
  Future<void> sendMessage(String message,
      {List<Map<String, dynamic>>? attachments, String language = 'en'}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;

    if (_currentSessionId == null) {
      await createNewSession();
    }

    // Optimistically add user message to local cache
    _messages.insert(
        0,
        ChatMessage(
          sender: 'user',
          text: trimmed,
          timestamp: DateTime.now(),
        ));
    _isLoading = true;
    notifyListeners();

    try {      // Save user message to backend
      await LegalQueriesApi.addMessage(_uid, _currentSessionId!, {
        'role': 'user',
        'content': trimmed,
      });

      // Call AI Gateway for response
      final data = await AiGatewayApi.legalChat(
        sessionId: _currentSessionId!,
        message: trimmed,
        language: language,
        attachments: attachments,
      );

      final reply = data['reply'] as String? ?? '';
      final rawTitle = data['title'] as String? ?? 'New Chat';
      final title = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;      // Save AI reply to backend
      await LegalQueriesApi.addMessage(_uid, _currentSessionId!, {
        'role': 'ai',
        'content': reply,
      });

      // Update thread title (only if still "New Chat")
      try {
        final threadData =
            await LegalQueriesApi.getThread(_uid, _currentSessionId!);
        final existingTitle = threadData['title'];
        if (existingTitle == null ||
            existingTitle == 'New Chat' ||
            existingTitle.toString().isEmpty) {
          await LegalQueriesApi.updateThread(
              _uid, _currentSessionId!, {'title': title});
        }
      } catch (_) {
        // Non-critical — title update failure shouldn't break chat
      }

      // Add AI reply to local cache
      _messages.insert(
          0,
          ChatMessage(
            sender: 'ai',
            text: reply,
            timestamp: DateTime.now(),
          ));
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ??
          e.message ??
          'Unable to get legal response. Please try again.';
      _messages.insert(
          0,
          ChatMessage(
            sender: 'ai',
            text: '⚠️ $errorMsg',
            timestamp: DateTime.now(),
          ));
    } catch (e) {
      _messages.insert(
          0,
          ChatMessage(
            sender: 'ai',
            text: '⚠️ Unable to get legal response. Please try again.',
            timestamp: DateTime.now(),
          ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /* ---------------- CHAT HISTORY (replaces Firestore stream) --------- */
  Future<void> loadSessions() async {
    try {
      final results = await LegalQueriesApi.listThreads(_uid);
      _sessions = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {
          'id': map['id'] ?? '',
          'title': map['title'] ?? 'New Chat',
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading legal chat sessions: $e');
    }
  }

  /// Compatibility: returns a stream wrapper around the loaded sessions.
  Stream<List<Map<String, dynamic>>> chatSessionsStream() {
    return Stream.fromFuture(Future(() async {
      await loadSessions();
      return _sessions;
    }));
  }
}
