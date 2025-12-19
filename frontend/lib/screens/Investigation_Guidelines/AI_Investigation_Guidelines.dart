import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Dharma/l10n/app_localizations.dart';

const Color orange = Color(0xFFFC633C);

class AiInvestigationGuidelinesScreen extends StatefulWidget {
  const AiInvestigationGuidelinesScreen({super.key});

  @override
  State<AiInvestigationGuidelinesScreen> createState() =>
      _AiInvestigationGuidelinesScreenState();
}

class _AiInvestigationGuidelinesScreenState
    extends State<AiInvestigationGuidelinesScreen> {
  final TextEditingController _firController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<_ChatMessage> _messages = [];

  bool _loading = false;
  String _firNumber = "";

  // 🔗 CHANGE THIS TO YOUR BACKEND IP
  final String _apiUrl =
      "http://127.0.0.1:8000/api/ai-investigation";

  /* ---------------- START INVESTIGATION ---------------- */
  Future<void> _startInvestigation() async {
    final fir = _firController.text.trim();
    if (fir.isEmpty) return;

    setState(() {
      _firNumber = fir;
      _messages.clear();
    });

    await _sendToAI("Start investigation");
  }

  /* ---------------- SEND MESSAGE ---------------- */
  Future<void> _sendToAI(String officerMessage) async {
    setState(() {
      _loading = true;
      _messages.add(_ChatMessage(
        sender: "officer",
        text: officerMessage,
      ));
    });

    final chatHistory = _messages
        .map((m) => "${m.sender.toUpperCase()}: ${m.text}")
        .join("\n");

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fir_number": _firNumber,
          "message": officerMessage,
          "chat_history": chatHistory,
          "language": "English"
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        _messages.add(_ChatMessage(
          sender: "ai",
          text: data["reply"],
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          sender: "ai",
          text: AppLocalizations.of(context)!.errorContactingInvestigationAI,
        ));
      });
    }

    setState(() => _loading = false);
  }

  /* ---------------- CHAT BUBBLE ---------------- */
  Widget _bubble(_ChatMessage msg) {
    final isOfficer = msg.sender == "officer";

    return Align(
      alignment: isOfficer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isOfficer ? orange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isOfficer ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiInvestigationGuidelines),
        backgroundColor: orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FIR INPUT
            if (_firNumber.isEmpty) ...[
              TextField(
                controller: _firController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enterFirNumber,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                ),
                onPressed: _startInvestigation,
                child: Text(AppLocalizations.of(context)!.startInvestigation),
              ),
            ],

            // CHAT AREA
            if (_firNumber.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _bubble(_messages[i]),
                ),
              ),

              // INPUT BAR
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterOfficerResponse,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _loading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send, color: orange),
                    onPressed: _loading
                        ? null
                        : () {
                            final text =
                                _messageController.text.trim();
                            if (text.isEmpty) return;
                            _messageController.clear();
                            _sendToAI(text);
                          },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ---------------- MODEL ---------------- */
class _ChatMessage {
  final String sender; // officer | ai
  final String text;

  _ChatMessage({required this.sender, required this.text});
}
