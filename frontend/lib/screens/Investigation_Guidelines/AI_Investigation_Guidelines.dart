import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/l10n/app_localizations.dart';

const Color orange = Color(0xFFFC633C);

class AiInvestigationGuidelinesScreen extends StatefulWidget {
  final String? caseId;

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

  Petition? _petition;
  bool _fetchingPetition = false;
  bool _loadingAI = false;

  Map<String, dynamic>? _aiReport;

  // 🔗 Backend API
  final String _apiUrl =
      "https://fastapi-app-335340524683.asia-south1.run.app/api/ai-investigation/";

  @override
  void initState() {
    super.initState();

    if (widget.caseId != null && widget.caseId!.isNotEmpty) {
      _caseIdController.text = widget.caseId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPetitionDetails();
      });
    }
  }

  /* ---------------- FETCH PETITION ---------------- */
  Future<void> _fetchPetitionDetails() async {
    final caseId = _caseIdController.text.trim();
    if (caseId.isEmpty) {
      _showSnackbar('Please enter Case ID');
      return;
    }

    setState(() {
      _fetchingPetition = true;
      _petition = null;
      _aiReport = null;
    });

    try {
      final petitionProvider =
          Provider.of<PetitionProvider>(context, listen: false);

      final petition =
          await petitionProvider.fetchPetitionByCaseId(caseId);

      if (petition == null) {
        _showSnackbar('No petition found for Case ID: $caseId');
      } else {
        setState(() => _petition = petition);
      }
    } catch (e) {
      _showSnackbar('Error fetching petition');
    }

    setState(() => _fetchingPetition = false);
  }

  /* ---------------- BUILD FIR DETAILS ---------------- */
  String _buildFirDetails(Petition p) {
    return '''
Case ID: ${p.caseId ?? 'N/A'}
Petition Title: ${p.title}
Petition Type: ${p.type.displayName}

Petitioner Name: ${p.petitionerName}
Phone Number: ${p.phoneNumber ?? 'N/A'}

District: ${p.district ?? 'N/A'}
Police Station: ${p.stationName ?? 'N/A'}

Incident Address:
${p.incidentAddress ?? 'N/A'}

Incident Date:
${p.incidentDate != null ? p.incidentDate!.toDate() : 'N/A'}

Complaint / Grounds:
${p.grounds}
''';
  }

  /* ---------------- GENERATE AI INVESTIGATION ---------------- */
  Future<void> _generateInvestigation() async {
    if (_petition == null) return;

    setState(() {
      _loadingAI = true;
      _aiReport = null;
    });

    final firDetails = _buildFirDetails(_petition!);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fir_id": _petition!.caseId,
          "fir_details": firDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiReport = data["report"];
        });
      } else {
        _showSnackbar('AI generation failed');
      }
    } catch (e) {
      _showSnackbar(
          AppLocalizations.of(context)!.errorContactingInvestigationAI);
    }

    setState(() => _loadingAI = false);
  }

  /* ---------------- UI HELPERS ---------------- */
  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 🎨 Build section cards
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor ?? Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Build investigation tasks
  Widget _buildInvestigationTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return const Text(
        "No tasks identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: tasks.map((task) {
        final priority = task['priority']?.toString() ?? 'Routine';
        final isUrgent = priority.toLowerCase().contains('urgent');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUrgent 
                ? Colors.red.shade50 
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent 
                  ? Colors.red.shade300 
                  : Colors.blue.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['task'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent 
                          ? Colors.red.shade100 
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUrgent 
                            ? Colors.red.shade900 
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build applicable laws
  Widget _buildApplicableLaws(List<dynamic> laws) {
    if (laws.isEmpty) {
      return const Text(
        "No specific laws identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: laws.map((law) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      law['section'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                law['justification'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build list items
  Widget _buildListItems(List<dynamic> items, Color color) {
    if (items.isEmpty) {
      return const Text(
        "None identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build forensic suggestions
  Widget _buildForensicSuggestions(List<dynamic> suggestions) {
    if (suggestions.isEmpty) {
      return const Text(
        "No forensic suggestions.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science,
                    color: Colors.purple.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion['evidence_type'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                suggestion['protocol'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build tags
  Widget _buildTags(List<dynamic> tags) {
    if (tags.isEmpty) {
      return const Text(
        "No tags.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: orange.withOpacity(0.3),
            ),
          ),
          child: Text(
            tag.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: orange,
            ),
          ),
        );
      }).toList(),
    );
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title:
            Text(AppLocalizations.of(context)!.aiInvestigationGuidelines),
        backgroundColor: orange,
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      // 🔹 CASE ID INPUT
      if (_petition == null) ...[
        TextField(
          controller: _caseIdController,
          decoration: const InputDecoration(
            labelText: 'Case ID',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _fetchingPetition ? null : _fetchPetitionDetails,
          icon: _fetchingPetition
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search),
          label: const Text('Load Petition'),
        ),
      ],

      // 🔹 PETITION DETAILS
      if (_petition != null) ...[
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _petition!.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _infoRow('Type', _petition!.type.displayName),
                _infoRow('Petitioner', _petition!.petitionerName),
                _infoRow('District', _petition!.district ?? 'N/A'),
                _infoRow('Station', _petition!.stationName ?? 'N/A'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _loadingAI ? null : _generateInvestigation,
          icon: _loadingAI
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.psychology),
          label: const Text('Generate Investigation Guidelines'),
        ),
      ],

      // 🔹 AI REPORT (SCROLLS WITH ABOVE)
      if (_aiReport != null) ...[
        const SizedBox(height: 16),

        if (_aiReport!['summary'] != null)
          _buildSectionCard(
            title: 'Investigation Summary',
            icon: Icons.summarize,
            backgroundColor: Colors.orange.shade50.withOpacity(0.5),
            borderColor: orange.withOpacity(0.3),
            content: Text(
              _aiReport!['summary'],
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),

        if (_aiReport!['case_type_tags'] != null)
          _buildSectionCard(
            title: 'Case Type Tags',
            icon: Icons.label,
            backgroundColor: Colors.blue.shade50.withOpacity(0.5),
            borderColor: Colors.blue.shade200,
            content: _buildTags(_aiReport!['case_type_tags']),
          ),

        if (_aiReport!['modus_operandi_tags'] != null)
          _buildSectionCard(
            title: 'Modus Operandi Tags',
            icon: Icons.visibility,
            backgroundColor: Colors.indigo.shade50.withOpacity(0.5),
            borderColor: Colors.indigo.shade200,
            content: _buildTags(_aiReport!['modus_operandi_tags']),
          ),

        if (_aiReport!['investigation_tasks'] != null)
          _buildSectionCard(
            title: 'Investigation Tasks',
            icon: Icons.task_alt,
            backgroundColor: Colors.teal.shade50.withOpacity(0.5),
            borderColor: Colors.teal.shade200,
            content: _buildInvestigationTasks(
              _aiReport!['investigation_tasks'],
            ),
          ),

        if (_aiReport!['applicable_laws'] != null)
          _buildSectionCard(
            title: 'Applicable Laws',
            icon: Icons.gavel,
            backgroundColor: Colors.green.shade50.withOpacity(0.5),
            borderColor: Colors.green.shade200,
            content: _buildApplicableLaws(
              _aiReport!['applicable_laws'],
            ),
          ),

        if (_aiReport!['precautions_and_protocols'] != null)
          _buildSectionCard(
            title: 'Precautions & Protocols',
            icon: Icons.shield,
            backgroundColor: Colors.amber.shade50.withOpacity(0.5),
            borderColor: Colors.amber.shade200,
            content: _buildListItems(
              _aiReport!['precautions_and_protocols'],
              Colors.amber.shade700,
            ),
          ),

        if (_aiReport!['forensic_suggestions'] != null)
          _buildSectionCard(
            title: 'Forensic Suggestions',
            icon: Icons.science,
            backgroundColor: Colors.purple.shade50.withOpacity(0.5),
            borderColor: Colors.purple.shade200,
            content: _buildForensicSuggestions(
              _aiReport!['forensic_suggestions'],
            ),
          ),
      ],
    ],
  ),
),

    );
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    super.dispose();
  }
}
