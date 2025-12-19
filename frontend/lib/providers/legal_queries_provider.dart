import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';

class LegalQueriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  /* ---------------- BASE URL ---------------- */
  String get _baseUrl {
    // Use deployed Cloud Run backend URL
    return 'https://fastapi-app-335340524683.asia-south1.run.app';
    
    // Uncomment below for local development
    // if (kIsWeb) {
    //   return 'http://localhost:8000';
    // } else {
    //   return 'http://10.0.2.2:8000';
    // }
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
        .orderBy('timestamp')
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
  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    if (_currentSessionId == null) {
      await createNewSession();
    }

    final sessionRef =
        _firestore.collection('legal_queries_chats').doc(_currentSessionId);

    // 1️⃣ Save USER message
    await sessionRef.collection('messages').add({
      'sender': 'user',
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      final token = await _auth.currentUser!.getIdToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/legal-chat/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionId': _currentSessionId,
          'message': trimmed,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final reply = data['reply'] as String;
      final rawTitle = data['title'] as String;

      final title =
          rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;

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
    } catch (e) {
      // Graceful fallback
      await sessionRef.collection('messages').add({
        'sender': 'ai',
        'text': '⚠️ Unable to get legal response. Please try again.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /* ---------------- CHAT HISTORY STREAM ---------------- */
  Stream<List<Map<String, dynamic>>> chatSessionsStream() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection('legal_queries_chats')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;

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
