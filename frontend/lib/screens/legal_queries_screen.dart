// lib/screens/legal_queries_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

class LegalQueriesScreen extends StatefulWidget {
  const LegalQueriesScreen({super.key});

  @override
  State<LegalQueriesScreen> createState() => _LegalQueriesScreenState();
}

class _LegalQueriesScreenState extends State<LegalQueriesScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _queries = [];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submitQuery() {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _queries.insert(0, {
        'query': _queryController.text.trim(),
        'status': AppLocalizations.of(context)!.answered,
        'date': DateTime.now().toString().split(' ')[0],
      });
    });

    _queryController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFC633C),
        content: Text(AppLocalizations.of(context)!.querySubmittedSuccessfully),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER: Pure Orange Arrow + Title (very close)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  // PURE ORANGE ARROW — NO BACKGROUND CIRCLE
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Super tight gap — feels connected
                  const SizedBox(width: 8),

                  // Title
                  Text(
                    localizations.legalQueries,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle (aligned under title)
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
              child: Text(
                localizations.askLegalQuestions,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Submit Query Card
                    Card(
                      elevation: 6,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit_note, color: orange, size: 26),
                                const SizedBox(width: 10),
                                Text(
                                  localizations.submitAQuery,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _queryController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: localizations.enterLegalQuestion,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitQuery,
                                icon: const Icon(Icons.send_rounded),
                                label: Text(localizations.submitQuery, style: const TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Previous Queries Title
                    Row(
                      children: [
                        Icon(Icons.history, color: orange, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          localizations.previousQueries,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Queries List
                    Expanded(
                      child: _queries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 20),
                                  Text(
                                    localizations.noQueriesYet,
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(localizations.submitFirstQuery, style: TextStyle(color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _queries.length,
                              itemBuilder: (context, index) {
                                final query = _queries[index];
                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: orange,
                                      child: const Icon(Icons.gavel, color: Colors.white),
                                    ),
                                    title: Text(
                                      query['query']!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${query['status']} • ${query['date']}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Row(
                                            children: [
                                              Icon(Icons.question_answer, color: orange),
                                              const SizedBox(width: 8),
                                              Text(localizations.queryDetails),
                                            ],
                                          ),
                                          content: SingleChildScrollView(child: Text(query['query']!)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(localizations.close, style: TextStyle(color: orange)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}