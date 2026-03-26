import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'package:Dharma/services/api/ai_gateway_api.dart';

class LegalSuggestionScreen extends StatefulWidget {
  const LegalSuggestionScreen({super.key});

  @override
  State<LegalSuggestionScreen> createState() => _LegalSuggestionScreenState();
}

class _LegalSuggestionScreenState extends State<LegalSuggestionScreen> {
  final TextEditingController _incidentController = TextEditingController();

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

    final settings = context.read<SettingsProvider>();
    final lang = settings.locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    String description = _incidentController.text.trim();

    // Prompt injection workaround
    if (lang == 'te') {
      description += " (Please reply in Telugu language)";
    } else if (lang != 'en') {
      description += " (Please reply in $lang language)";
    }

    try {
      final res = await AiGatewayApi.legalSuggestions(
        incidentDescription: description,
        language: lang,
      );

      setState(() {
        _sectionsText = res['suggestedSections'];
        _reasoning = res['reasoning'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to generate Legal Section Suggester"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Helper method to get localized label based on current locale
  String _getLocalizedLabel(String english, String telugu) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'te' ? telugu : english;
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
        _getLocalizedLabel("Suggested Legal Sections", "సూచించబడిన చట్ట ధారలు"),
        Icons.gavel,
        Text(
          _getLocalizedLabel(
            "No applicable sections found.",
            "వర్తించే ధారలు కనుగొనబడలేదు.",
          ),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final sections =
        _sectionsText!.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return _cardWrapper(
      _getLocalizedLabel("Suggested Legal Sections", "సూచించబడిన చట్ట ధారలు"),
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

  Widget _buildReasoning() {
    return _cardWrapper(
      _getLocalizedLabel("Reasoning", "కారణం"),
      Icons.lightbulb_outline,
      Text(
        _reasoning ?? _getLocalizedLabel(
          "Reasoning not available.",
          "కారణం అందుబాటులో లేదు.",
        ),
        style: const TextStyle(fontSize: 15, height: 1.6),
      ),
    );
  }

  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // print('📱 [LEGAL_SUGGESTION] Screen built');
    // print('📚 [LEGAL_SUGGESTION] Can pop: ${Navigator.of(context).canPop()}');

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
                    onPressed: () {
                      // print('⬅️ [LEGAL_SUGGESTION] Back button pressed');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.legalSuggestion,
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
                      : Text(
                          _getLocalizedLabel(
                            "Get Legal Section Suggester",
                            "చట్ట సూచనలను పొందండి",
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ───── LOADING STATE ─────
              if (_loading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: orange),
                      const SizedBox(height: 16),
                      Text(
                        _getLocalizedLabel(
                          "Analyzing incident and generating Legal Section Suggester...",
                          "సంఘటనను విశ్లేషించి చట్ట సూచనలను రూపొందిస్తోంది...",
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // ───── RESULT ─────
              if (_sectionsText != null && !_loading) ...[
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
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getLocalizedLabel(
                            "This is informational only, not legal advice.",
                            "ఇది కేవలం సమాచారం మాత్రమే, చట్ట సలహా కాదు.",
                          ),
                          style: const TextStyle(fontSize: 13),
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
