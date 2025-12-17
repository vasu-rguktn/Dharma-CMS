// lib/screens/cases_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';

import 'package:Dharma/providers/auth_provider.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        caseProvider.fetchCases(
          userId: auth.user?.uid,
          isAdmin: auth.role == 'police',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER: Arrow + Title + New Case Button (all in one row)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              child: Row(
                children: [
                  // Pure Orange Back Arrow
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Title
                  Expanded(
                    child: Text(
                      localizations.allCases,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  // New Case Button — same row, right aligned
                  ElevatedButton.icon(
                    onPressed: () => context.go('/cases/new'),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(localizations.newCase),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),

            // MAIN LIST
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: caseProvider.cases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 24),
                            Text(
                              localizations.noCasesFound,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(localizations.createFirstCase, style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/cases/new'),
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(localizations.createNewCase),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 6,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: caseProvider.cases.length,
                        itemBuilder: (context, index) {
                          final caseItem = caseProvider.cases[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: orange,
                                child: const Icon(Icons.gavel, color: Colors.white, size: 24),
                              ),
                              title: Text(
                                caseItem.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${caseItem.status.displayName} • FIR: ${caseItem.firNumber}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                              onTap: () => context.go('/cases/${caseItem.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}