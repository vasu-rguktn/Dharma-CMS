// lib/screens/cases_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:Dharma/providers/auth_provider.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  bool _hasLoaded = false;
  String? _searchQuery;
  String? _selectedStation;
  String? _selectedStatus;
  String? _selectedAgeRange;

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.newCase:
        return const Color(0xFF1E88E5); // blue
      case CaseStatus.underInvestigation:
        return const Color(0xFFF9A825); // amber
      case CaseStatus.pendingTrial:
        return const Color(0xFF8E24AA); // purple
      case CaseStatus.resolved:
        return const Color(0xFF43A047); // green
      case CaseStatus.closed:
        return const Color(0xFF757575); // grey
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }

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

    return WillPopScope(
      onWillPop: () async {
        // Use GoRouter's canPop to check navigation history
        if (context.canPop()) {
          context.pop();
          return false; // Prevent default exit, we handled navigation
        }
        return true; // Allow exit only if truly root
      },
      child: Scaffold(
      // Slightly darker background so white cards stand out clearly
      backgroundColor: const Color(0xFFF1F3F6),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER: Arrow + Title + New Case Button (all in one row)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
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

            // Subheading under title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Manage and view details of FIRs / Cases you are involved in.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            // SEARCH & FILTERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by FIR number, title, complainant...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Filters:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip<String>(
                            label: 'Station',
                            value: _selectedStation,
                            options: {
                              for (final c in caseProvider.cases)
                                if (c.policeStation != null)
                                  c.policeStation!: c.policeStation!,
                            }.values.toList(),
                            onSelected: (value) {
                              setState(() => _selectedStation = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip<String>(
                            label: 'Status',
                            value: _selectedStatus,
                            options: CaseStatus.values
                                .map((s) => s.displayName)
                                .toList(),
                            onSelected: (value) {
                              setState(() => _selectedStatus = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip<String>(
                            label: 'Age',
                            value: _selectedAgeRange,
                            options: const [
                              'Below 18',
                              '18-30',
                              '31-50',
                              'Above 50',
                            ],
                            onSelected: (value) {
                              setState(() => _selectedAgeRange = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // MAIN LIST
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilteredList(caseProvider, localizations, orange),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFilteredList(
    CaseProvider caseProvider,
    AppLocalizations localizations,
    Color orange,
  ) {
    // Apply in-memory filters
    final filteredCases = caseProvider.cases.where((c) {
      // Search query
      final query = _searchQuery;
      if (query != null && query.isNotEmpty) {
        final haystack = [
          c.title,
          c.firNumber,
          c.complainantName,
          c.victimName,
          c.policeStation,
          c.district,
        ]
            .whereType<String>()
            .join(' ')
            .toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // Station filter
      if (_selectedStation != null &&
          _selectedStation!.isNotEmpty &&
          c.policeStation != _selectedStation) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null &&
          _selectedStatus!.isNotEmpty &&
          c.status.displayName != _selectedStatus) {
        return false;
      }

      // Age filter (based on complainantAge if available)
      if (_selectedAgeRange != null && _selectedAgeRange!.isNotEmpty) {
        final age = int.tryParse(c.complainantAge ?? '');
        if (age != null) {
          switch (_selectedAgeRange) {
            case 'Below 18':
              if (age >= 18) return false;
              break;
            case '18-30':
              if (age < 18 || age > 30) return false;
              break;
            case '31-50':
              if (age < 31 || age > 50) return false;
              break;
            case 'Above 50':
              if (age <= 50) return false;
              break;
          }
        }
      }

      return true;
    }).toList();

    if (filteredCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              localizations.noCasesFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCases.length,
      itemBuilder: (context, index) {
        final caseItem = filteredCases[index];
        final filedDate = _formatDate(caseItem.dateFiled.toDate());
        final lastUpdated = _formatDate(caseItem.lastUpdated.toDate());

        return Card(
          elevation: 2,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go('/cases/${caseItem.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: orange,
                        child: const Icon(Icons.gavel, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    caseItem.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(caseItem.status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    caseItem.status.displayName,
                                    style: TextStyle(
                                      color: _statusColor(caseItem.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'FIR No: ${caseItem.firNumber} | Filed: $filedDate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (caseItem.policeStation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Station: ${caseItem.policeStation!}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            if (caseItem.complainantName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Complainant: ${caseItem.complainantName!}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last Updated: $lastUpdated',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/cases/${caseItem.id}'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(
                          'View Details',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T? value,
    required List<T> options,
    required void Function(T?) onSelected,
  }) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<T>(
          value: null,
          child: Text('All $label'),
        ),
        ...options.toSet().map(
          (opt) => PopupMenuItem<T>(
            value: opt,
            child: Text(opt.toString()),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == null ? label : '$label: $value',
              style: const TextStyle(fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}