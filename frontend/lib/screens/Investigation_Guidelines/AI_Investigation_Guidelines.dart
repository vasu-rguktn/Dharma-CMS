import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';

const Color orange = Color(0xFFFC633C);

class AiInvestigationGuidelinesScreen extends StatefulWidget {
  final String? caseId; // Optional: can be passed from navigation
  
  const AiInvestigationGuidelinesScreen({
    super.key,
    this.caseId,
  });

  @override
  State<AiInvestigationGuidelinesScreen> createState() =>
      _AiInvestigationGuidelinesScreenState();
}

class _AiInvestigationGuidelinesScreenState
    extends State<AiInvestigationGuidelinesScreen> {
  final TextEditingController _caseIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<_ChatMessage> _messages = [];

  bool _loading = false;
  bool _fetchingPetition = false;
  String _currentCaseId = "";
  Petition? _petition;

  // 🔗 CHANGE THIS TO YOUR BACKEND IP
  final String _apiUrl = "http://127.0.0.1:8000/api/ai-investigation";

  @override
  void initState() {
    super.initState();
    // If caseId is provided via navigation, auto-fetch
    if (widget.caseId != null && widget.caseId!.isNotEmpty) {
      _caseIdController.text = widget.caseId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPetitionDetails();
      });
    }
  }

  /* ---------------- FETCH PETITION DETAILS ---------------- */
  Future<void> _fetchPetitionDetails() async {
    final caseId = _caseIdController.text.trim();
    if (caseId.isEmpty) {
      _showSnackbar('Please enter a Case ID');
      return;
    }

    setState(() {
      _fetchingPetition = true;
      _petition = null;
      _currentCaseId = "";
      _messages.clear();
    });

    try {
      final petitionProvider =
          Provider.of<PetitionProvider>(context, listen: false);
      final petition = await petitionProvider.fetchPetitionByCaseId(caseId);

      if (petition == null) {
        _showSnackbar('No petition found with Case ID: $caseId');
        setState(() {
          _fetchingPetition = false;
        });
        return;
      }

      setState(() {
        _petition = petition;
        _currentCaseId = caseId;
        _fetchingPetition = false;
      });

      _showSnackbar('Petition loaded successfully!');
    } catch (e) {
      debugPrint('Error fetching petition: $e');
      _showSnackbar('Error fetching petition details');
      setState(() {
        _fetchingPetition = false;
      });
    }
  }

  /* ---------------- START INVESTIGATION ---------------- */
  Future<void> _startInvestigation() async {
    if (_petition == null) {
      _showSnackbar('Please load petition details first');
      return;
    }

    await _sendToAI("Start investigation");
  }

  /* ---------------- SEND MESSAGE ---------------- */
  Future<void> _sendToAI(String officerMessage) async {
    if (_petition == null) return;

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

    // Build petition details string
    final petitionDetails = """
Type: ${_petition!.type.displayName}
Petitioner: ${_petition!.petitionerName}
Grounds: ${_petition!.grounds}
District: ${_petition!.district ?? 'N/A'}
Station: ${_petition!.stationName ?? 'N/A'}
Incident Address: ${_petition!.incidentAddress ?? 'N/A'}
""";

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fir_number": _currentCaseId,
          "message": officerMessage,
          "chat_history": chatHistory,
          "language": "English",
          "petition_title": _petition!.title,
          "petition_details": petitionDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _messages.add(_ChatMessage(
            sender: "ai",
            text: data["reply"],
          ));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(
            sender: "ai",
            text: "Error: ${response.statusCode} - ${response.body}",
          ));
        });
      }
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

  /* ---------------- SHOW SNACKBAR ---------------- */
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  /* ---------------- PETITION INFO CARD ---------------- */
  Widget _buildPetitionInfoCard() {
    if (_petition == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _petition!.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _infoRow('Type', _petition!.type.displayName),
            _infoRow('Petitioner', _petition!.petitionerName),
            _infoRow('District', _petition!.district ?? 'N/A'),
            _infoRow('Station', _petition!.stationName ?? 'N/A'),
            _infoRow('Status', _petition!.policeStatus ?? 'Pending'),
            const SizedBox(height: 8),
            Text(
              'Grounds: ${_petition!.grounds}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
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
            // CASE ID INPUT & FETCH
            if (_petition == null) ...[
              TextField(
                controller: _caseIdController,
                decoration: InputDecoration(
                  labelText: 'Enter Case ID',
                  hintText: 'e.g., case-Guntur-Elluru-20231219-12345',
                  border: const OutlineInputBorder(),
                  suffixIcon: _fetchingPetition
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _fetchingPetition ? null : _fetchPetitionDetails,
                icon: const Icon(Icons.search),
                label: const Text('Load Petition Details'),
              ),
            ],

            // PETITION INFO & CHAT AREA
            if (_petition != null) ...[
              _buildPetitionInfoCard(),

              // START INVESTIGATION BUTTON (if chat not started)
              if (_messages.isEmpty) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _startInvestigation,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppLocalizations.of(context)!.startInvestigation),
                ),
                const SizedBox(height: 16),
              ],

              // CHAT MESSAGES
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _bubble(_messages[i]),
                ),
              ),

              // INPUT BAR (if investigation started)
              if (_messages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.enterOfficerResponse,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: orange),
                      onPressed: _loading
                          ? null
                          : () {
                              final text = _messageController.text.trim();
                              if (text.isEmpty) return;
                              _messageController.clear();
                              _sendToAI(text);
                            },
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

/* ---------------- MODEL ---------------- */
class _ChatMessage {
  final String sender; // officer | ai
  final String text;

  _ChatMessage({required this.sender, required this.text});
}
