import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

class LegalSuggestionScreen extends StatefulWidget {
  const LegalSuggestionScreen({super.key});

  @override
  State<LegalSuggestionScreen> createState() =>
      _LegalSuggestionScreenState();
}

class _LegalSuggestionScreenState extends State<LegalSuggestionScreen> {
  final TextEditingController _incidentController =
      TextEditingController();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://fastapi-app-335340524683.asia-south1.run.app",
      headers: {"Content-Type": "application/json"},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  bool _loading = false;
  String? _sectionsText;
  String? _reasoning;

  static const Color orange = Color(0xFFFC633C);

  @override
  void dispose() {
    _incidentController.dispose();
    super.dispose();
  }

  // ───────── API CALL ─────────
  Future<void> _submit() async {
    if (_incidentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please describe the incident"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _sectionsText = null;
      _reasoning = null;
    });

    try {
      final res = await _dio.post(
        "/api/legal-suggestions/",
        data: {
          "incident_description": _incidentController.text.trim(),
        },
      );

      setState(() {
        _sectionsText = res.data['suggestedSections'];
        _reasoning = res.data['reasoning'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to generate legal suggestions"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ───────── COMMON CARD ─────────
  Widget _cardWrapper(String title, IconData icon, Widget child) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: orange),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  // ───────── SECTIONS LIST ─────────
  Widget _buildSectionsTimeline() {
  if (_sectionsText == null || _sectionsText!.isEmpty) {
    return _cardWrapper(
      "Suggested Legal Sections",
      Icons.gavel,
      const Text(
        "No applicable sections found.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  final sections = _sectionsText!
      .split('\n')
      .where((s) => s.trim().isNotEmpty)
      .toList();

  return _cardWrapper(
    "Suggested Legal Sections",
    Icons.gavel,
    Stack(
      children: [
        // 🔹 CONTINUOUS VERTICAL LINE
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: orange,
          ),
        ),

        // 🔹 TIMELINE ITEMS
        Column(
          children: List.generate(sections.length, (index) {
            final raw = sections[index];

            String sectionText = raw;
            String meaningText = "";

            final match =
                RegExp(r'^(.*?)(?:\s*\(([^)]+)\))$').firstMatch(raw);
            if (match != null) {
              sectionText = match.group(1)!.trim();
              meaningText = match.group(2)!.trim();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 DOT (CENTERED)
                  Container(
                    margin: const EdgeInsets.only(left: 13),
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 🔹 CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: orange),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sectionText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (meaningText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              meaningText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    ),
  );
}

// ───────── REASONING ─────────
Widget _buildReasoning() {
  return _cardWrapper(
    "Reasoning",
    Icons.lightbulb_outline,
    Text(
      _reasoning ?? "Reasoning not available.",
      style: const TextStyle(fontSize: 15, height: 1.6),
    ),
  );
}


  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───── HEADER ─────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: orange,
                    onPressed: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Legal Section Suggester",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ───── INPUT ─────
              TextField(
                controller: _incidentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: loc.describeIncidentHint,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ───── BUTTON ─────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Get Legal Suggestions",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),




              const SizedBox(height: 24),

              // ───── RESULT ─────
              if (_sectionsText != null) ...[
                _buildSectionsTimeline(),
                _buildReasoning(),

                // ───── DISCLAIMER ─────
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "This is informational only, not legal advice.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
