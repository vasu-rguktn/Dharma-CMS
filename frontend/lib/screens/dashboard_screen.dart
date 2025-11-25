// // Dashboard Screen - Placeholder
// // Full implementation with charts would require fl_chart package
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:Dharma/providers/auth_provider.dart';
// import 'package:Dharma/providers/case_provider.dart';
// import 'package:Dharma/models/case_status.dart';
// import 'package:go_router/go_router.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final caseProvider = Provider.of<CaseProvider>(context);
//     final theme = Theme.of(context);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Welcome Section
//           Text(
//             'Welcome, ${authProvider.userProfile?.displayName ?? "User"}!',
//             style: theme.textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Here\'s an overview of your legal assistance dashboard',
//             style: theme.textTheme.bodyLarge?.copyWith(
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Statistics Cards
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'Total Cases',
//                   '${caseProvider.cases.length}',
//                   Icons.folder_open,
//                   Colors.blue,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'Active Cases',
//                   '${caseProvider.cases.where((c) => c.status != CaseStatus.closed && c.status != CaseStatus.resolved).length}',
//                   Icons.pending_actions,
//                   Colors.orange,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'Closed Cases',
//                   '${caseProvider.cases.where((c) => c.status == CaseStatus.closed).length}',
//                   Icons.check_circle,
//                   Colors.green,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'AI Queries',
//                   '0',
//                   Icons.psychology,
//                   Colors.purple,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),

//           // Quick Actions
//           Text(
//             'Quick Actions',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children: [
//               _buildQuickActionCard(
//                 context,
//                 'AI Chat',
//                 Icons.chat,
//                 Colors.blue,
//                 '/chat',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Legal Queries',
//                 Icons.psychology,
//                 Colors.purple,
//                 '/legal-queries',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'View Cases',
//                 Icons.folder_open,
//                 Colors.orange,
//                 '/cases',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Complaints',
//                 Icons.archive,
//                 Colors.teal,
//                 '/complaints',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Legal Suggestion',
//                 Icons.gavel,
//                 Colors.indigo,
//                 '/legal-suggestion',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Document Drafting',
//                 Icons.edit_document,
//                 Colors.green,
//                 '/document-drafting',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Chargesheet Gen',
//                 Icons.file_present,
//                 Colors.deepOrange,
//                 '/chargesheet-generation',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Chargesheet Vetting',
//                 Icons.fact_check,
//                 Colors.brown,
//                 '/chargesheet-vetting',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Witness Prep',
//                 Icons.people,
//                 Colors.pink,
//                 '/witness-preparation',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Media Analysis',
//                 Icons.image_search,
//                 Colors.cyan,
//                 '/media-analysis',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Case Journal',
//                 Icons.book,
//                 Colors.deepPurple,
//                 '/case-journal',
//               ),
//               _buildQuickActionCard(
//                 context,
//                 'Petitions',
//                 Icons.gavel,
//                 Colors.amber,
//                 '/petitions',
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),

//           // Recent Activity
//           Text(
//             'Recent Activity',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildRecentActivityCard(
//             context,
//             'No recent activity',
//             'Your recent cases and queries will appear here',
//             Icons.history,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context,
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Icon(icon, color: color, size: 32),
//                 Text(
//                   value,
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActionCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     String route,
//   ) {
//     return SizedBox(
//       width: (MediaQuery.of(context).size.width - 48) / 2,
//       child: Card(
//         elevation: 2,
//         child: InkWell(
//           onTap: () => context.go(route),
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Icon(icon, color: color, size: 40),
//                 const SizedBox(height: 8),
//                 Text(
//                   title,
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivityCard(
//     BuildContext context,
//     String title,
//     String subtitle,
//     IconData icon,
//   ) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Icon(icon, size: 40, color: Colors.grey[400]),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
















import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),

      // === Floating Chatbot Button with Label ===
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ai-legal-guider'),
        backgroundColor: const Color(0xFFFC633C),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        icon: const Icon(
          Icons.chat_bubble_outline,
          size: 26,
          color: Colors.white,
        ),
        label: Text(
          localizations.newCase,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // === Main Scrollable Body ===
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              localizations.welcomeUser(authProvider.userProfile?.displayName ?? "User"),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.legalAssistanceHub,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    localizations.totalCases,
                    '${caseProvider.cases.length}',
                    Icons.folder_open,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    localizations.activeCases,
                    '${caseProvider.cases.where((c) => c.status != CaseStatus.closed && c.status != CaseStatus.resolved).length}',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    localizations.closedCases,
                    '${caseProvider.cases.where((c) => c.status == CaseStatus.closed).length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    localizations.legalQueries,
                    '0',
                    Icons.psychology,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              localizations.quickActions,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionCard(
                  context,
                  localizations.aiChat,
                  Icons.chat,
                  Colors.blue,
                  '/chat',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.legalQueries,
                  Icons.psychology,
                  Colors.purple,
                  '/legal-queries',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.viewCases,
                  Icons.folder_open,
                  Colors.orange,
                  '/cases',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.complaints,
                  Icons.archive,
                  Colors.teal,
                  '/complaints',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.legalSuggestion,
                  Icons.gavel,
                  Colors.indigo,
                  '/legal-suggestion',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.documentDrafting,
                  Icons.edit_document,
                  Colors.green,
                  '/document-drafting',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.chargesheetGen,
                  Icons.file_present,
                  Colors.deepOrange,
                  '/chargesheet-generation',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.chargesheetVetting,
                  Icons.fact_check,
                  Colors.brown,
                  '/chargesheet-vetting',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.witnessPrep,
                  Icons.people,
                  Colors.pink,
                  '/witness-preparation',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.mediaAnalysis,
                  Icons.image_search,
                  Colors.cyan,
                  '/media-analysis',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.caseJournal,
                  Icons.book,
                  Colors.deepPurple,
                  '/case-journal',
                ),
                _buildQuickActionCard(
                  context,
                  localizations.petitions,
                  Icons.gavel,
                  Colors.amber,
                  '/petitions',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Text(
              localizations.recentActivity,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivityCard(
              context,
              localizations.noRecentActivity,
              'Your recent cases and queries will appear here',
              Icons.history,
            ),
            const SizedBox(height: 80), // safe space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
