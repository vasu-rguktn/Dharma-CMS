import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../models/chat_message.dart';

class LegalQueriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  /* ---------------- BASE URL ---------------- */
  String get _baseUrl {
    // Local development
    return 'https://fastapi-app-335340524683.asia-south1.run.app';
  }

  /* ---------------- CREATE NEW SESSION ---------------- */
  Future<void> createNewSession() async {
    final uid = _auth.currentUser!.uid;

    final doc = await _firestore.collection('legal_queries_chats').add({
      'userId': uid,
      'title': 'New Chat', // TEMP TITLE
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    _currentSessionId = doc.id;
    notifyListeners();
  }

  /* ---------------- OPEN SESSION ---------------- */
  void openSession(String sessionId) {
    _currentSessionId = sessionId;
    notifyListeners();
  }

  /* ---------------- MESSAGES STREAM ---------------- */
  Stream<List<ChatMessage>> messagesStream() {
    if (_currentSessionId == null) return const Stream.empty();

    return _firestore
        .collection('legal_queries_chats')
        .doc(_currentSessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Reverse order for Chat UI
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatMessage(
                sender: data['sender'],
                text: data['text'],
                timestamp: data['timestamp'].toDate(),
              );
            }).toList());
  }

  /* ---------------- SEND MESSAGE ---------------- */
  Future<void> sendMessage(String message,
      {List<Map<String, dynamic>>? attachments, String language = 'en'}) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;

    if (_currentSessionId == null) {
      await createNewSession();
    }

    final sessionRef =
        _firestore.collection('legal_queries_chats').doc(_currentSessionId);

    // Generate attachment text
    String attachText = "";
    if (attachments != null && attachments.isNotEmpty) {
      final names = attachments.map((a) => a['name']).join(', ');
      attachText = " [Attached: $names]";
    }

    // 1️⃣ Save USER message
    await sessionRef.collection('messages').add({
      'sender': 'user',
      'text': trimmed + attachText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _isLoading = true;
    notifyListeners();

    try {
      final token = await _auth.currentUser!.getIdToken();
      final dio = Dio();

      // FormData construction
      String backendMessage = trimmed;
      if (language == 'te') {
        backendMessage += " (Please reply in Telugu language)";
      } else if (language != 'en') {
        backendMessage += " (Please reply in $language language)";
      }

      final formData = FormData.fromMap({
        'sessionId': _currentSessionId,
        'message': backendMessage,
        'language': language, // Send language to backend
      });
      // debugPrint(
          // "DEBUG: LegalQueriesProvider sending to backend with language: $language");
      // debugPrint("DEBUG: Appended Prompt Message: $backendMessage");

      if (attachments != null) {
        // debugPrint("DEBUG: Preparing ${attachments.length} attachments...");
        for (var file in attachments) {
          final bytes = file['bytes'] as Uint8List;
          final name = file['name'] as String;

          formData.files.add(MapEntry(
            'files', // Backend expects 'files' list
            MultipartFile.fromBytes(bytes, filename: name),
          ));
        }
      }

      final response = await dio.post(
        '$_baseUrl/api/legal-chat/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: formData,
      );

      if (response.statusCode != 200) {
        throw Exception('Backend error ${response.statusCode}');
      }

      final data = response.data;
      final reply = data['reply'] as String;
      final rawTitle = data['title'] as String;

      final title = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;

      // 2️⃣ Save AI reply
      await sessionRef.collection('messages').add({
        'sender': 'ai',
        'text': reply,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Update title ONLY ONCE
      final snap = await sessionRef.get();
      final existingTitle = snap.data()?['title'];

      if (existingTitle == null ||
          existingTitle == 'New Chat' ||
          existingTitle.toString().isEmpty) {
        await sessionRef.update({'title': title});
      }

      // 4️⃣ Update last activity
      await sessionRef.update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } on DioException catch (e) {
      // debugPrint("Legal Chat DioError: ${e.message}");
      // debugPrint("Status: ${e.response?.statusCode}");
      // debugPrint("Response: ${e.response?.data}");
      // Graceful fallback
      final errorMsg = e.response?.data?['detail'] ??
          e.message ??
          'Unable to get legal response. Please try again.';
      await sessionRef.collection('messages').add({
        'sender': 'ai',
        'text': '⚠️ $errorMsg',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // debugPrint("Legal Chat Error: $e");
      // Graceful fallback
      await sessionRef.collection('messages').add({
        'sender': 'ai',
        'text': '⚠️ Unable to get legal response. Please try again.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /* ---------------- CHAT HISTORY STREAM ---------------- */
  Stream<List<Map<String, dynamic>>> chatSessionsStream() {
    final uid = _auth.currentUser!.uid;
    // debugPrint('🔍 [LEGAL_QUERIES] Querying chat sessions for userId: $uid');

    return _firestore
        .collection('legal_queries_chats')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      // debugPrint('📚 [LEGAL_QUERIES] Found ${docs.length} chat sessions');

      if (docs.isNotEmpty) {
        for (var doc in docs) {
          // debugPrint('  - Session: ${doc.id}, Title: ${doc.data()['title']}');
        }
      }

      // Sort latest first
      docs.sort((a, b) {
        final aTime = a.data()['lastMessageAt'];
        final bTime = b.data()['lastMessageAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      return docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc.data()['title'] ?? 'New Chat',
        };
      }).toList();
    });
  }
}
