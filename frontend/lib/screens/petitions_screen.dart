import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/services/local_storage_service.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class PetitionsScreen extends StatefulWidget {
  const PetitionsScreen({super.key});

  @override
  State<PetitionsScreen> createState() => _PetitionsScreenState();
}

class _PetitionsScreenState extends State<PetitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPetitions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPetitions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);

    if (authProvider.user != null) {
      await petitionProvider.fetchPetitions(authProvider.user!.uid);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.draft:
        return Colors.grey;
      case PetitionStatus.filed:
        return Colors.blue;
      case PetitionStatus.underReview:
        return Colors.orange;
      case PetitionStatus.hearingScheduled:
        return Colors.purple;
      case PetitionStatus.granted:
        return Colors.green;
      case PetitionStatus.rejected:
        return Colors.red;
      case PetitionStatus.withdrawn:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        appBar: AppBar(
          title: const Text('Petition Management'),
          bottom: TabBar(
            isScrollable: true,
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'My Petitions'),
              Tab(icon: Icon(Icons.add_circle), text: 'Create New'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPetitionsListTab(theme),
            _buildCreatePetitionTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Title, ID, or Petitioner Name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPetitionsListTab(ThemeData theme) {
    return Consumer<PetitionProvider>(
      builder: (context, petitionProvider, child) {
        if (petitionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Apply Search Filter
        final petitions = petitionProvider.petitions.where((petition) {
          final query = _searchQuery.toLowerCase();
          final title = petition.title.toLowerCase();
          final id = petition.id?.toLowerCase() ?? '';
          final petitioner = petition.petitionerName.toLowerCase();

          return title.contains(query) ||
              id.contains(query) ||
              petitioner.contains(query);
        }).toList();

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: petitions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching petitions found'
                                : 'No Petitions Yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              'Create your first petition using the "Create New" tab',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPetitions,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: petitions.length,
                        itemBuilder: (context, index) {
                          final petition = petitions[index];
                          return _buildPetitionCard(petition, theme);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPetitionCard(Petition petition, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPetitionDetails(petition),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      petition.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(petition.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      petition.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      petition.petitionerName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (petition.phoneNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      petition.isAnonymous
                          ? maskPhoneNumber(petition.phoneNumber)
                          : petition.phoneNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatTimestamp(petition.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  if (petition.nextHearingDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Next Hearing: ${petition.nextHearingDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPetitionDetails(Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        petition.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(petition.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    petition.status.displayName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 32),
                _buildDetailRow('Petitioner', petition.petitionerName),
                if (petition.phoneNumber != null)
                  _buildDetailRow(
                    'Phone',
                    petition.isAnonymous
                        ? maskPhoneNumber(petition.phoneNumber)
                        : petition.phoneNumber!,
                  ),
                if (petition.address != null)
                  _buildDetailRow('Address', petition.address!),
                if (petition.firNumber != null)
                  _buildDetailRow('FIR Number', petition.firNumber!),
                const SizedBox(height: 16),
                Text(
                  'Grounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(petition.grounds),
                if (petition.prayerRelief != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Prayer / Relief Sought',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(petition.prayerRelief!),
                ],
                if (petition.filingDate != null)
                  _buildDetailRow('Filing Date', petition.filingDate!),
                if (petition.nextHearingDate != null)
                  _buildDetailRow('Next Hearing', petition.nextHearingDate!),
                if (petition.orderDate != null)
                  _buildDetailRow('Order Date', petition.orderDate!),
                if (petition.orderDetails != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Order Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(petition.orderDetails!),
                ],
                if (petition.extractedText != null &&
                    petition.extractedText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Extracted Text from Documents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      petition.extractedText!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'Extracted Text from Documents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Documents Uploaded...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Documents Section
                if (petition.proofDocumentUrls != null &&
                    petition.proofDocumentUrls!.isNotEmpty) ...[
                  Text(
                    'Uploaded Documents/Proofs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120, // Thumbnail strip
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: petition.proofDocumentUrls!.map((url) {
                          // Determine file type
                          final lowerUrl = url.toLowerCase();
                          final isPdf = lowerUrl.contains('.pdf');
                          final isDoc = lowerUrl.contains('.doc') ||
                              lowerUrl.contains('.docx');
                          final isTxt = lowerUrl.contains('.txt');

                          // Assume image ONLY if specific image extension is present
                          // Removed 'alt=media' check as it causes PDFs to be treated as images
                          final isImage = lowerUrl.contains('.jpg') ||
                              lowerUrl.contains('.png') ||
                              lowerUrl.contains('.jpeg') ||
                              lowerUrl.contains('.webp') ||
                              lowerUrl.contains('.heic');

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                if (isImage) {
                                  // Opens expanded view for images
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Stack(
                                        children: [
                                          InteractiveViewer(
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.contain,
                                              errorBuilder: (c, o, s) =>
                                                  const Center(
                                                      child: Icon(Icons.error,
                                                          color: Colors.white)),
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 30),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  // Launch URL for documents
                                  launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: isImage
                                    ? Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey)),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isPdf
                                                ? Icons.picture_as_pdf
                                                : (isDoc
                                                    ? Icons.description
                                                    : Icons.insert_drive_file),
                                            size: 32,
                                            color: isPdf
                                                ? Colors.red
                                                : (isDoc
                                                    ? Colors.blue
                                                    : Colors.grey[700]),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            isPdf
                                                ? 'PDF'
                                                : (isDoc ? 'DOC' : 'FILE'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Uploaded Documents/Proofs: None',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // DEBUG: Remove this later
                  Builder(builder: (c) {
                    // print(
                        // 'DEBUG: proofDocumentUrls is ${petition.proofDocumentUrls}');
                    return const SizedBox.shrink();
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCreatePetitionTab(ThemeData theme) {
    return CreatePetitionForm(
      onCreatedSuccess: () {
        _tabController.index = 0;
      },
    );
  }
}

class CreatePetitionForm extends StatefulWidget {
  const CreatePetitionForm({super.key, this.onCreatedSuccess});

  final VoidCallback? onCreatedSuccess;

  @override
  State<CreatePetitionForm> createState() => _CreatePetitionFormState();
}

class _CreatePetitionFormState extends State<CreatePetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petitionerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _groundsController = TextEditingController();
  final _prayerReliefController = TextEditingController();

  bool _isSubmitting = false;
  List<PlatformFile> _pickedFiles = []; // Handwritten documents
  List<PlatformFile> _proofFiles = []; // Related proof documents

  bool _isExtracting = false;
  Map<String, dynamic>? _ocrResult;
  final Dio _dio = Dio();
  String _ocrEndpoint = '';
  List<String> _ocrEndpointFallbacks = <String>[];

  @override
  void initState() {
    super.initState();
    _initBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndConsumeEvidence();
  }

  void _checkAndConsumeEvidence() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // print('🔍 [DEBUG] Petition Screen: Checking for evidence...');
      final petitionProvider =
          Provider.of<PetitionProvider>(context, listen: false);

      // 1. Try Provider (Best for Web/Bytes & Mobile Stashing)
      if (petitionProvider.tempEvidence.isNotEmpty) {
        // debugPrint(
            // '📥 Found ${petitionProvider.tempEvidence.length} stashed files in Provider');
        setState(() {
          // Avoid adding duplicates if already added
          final existingNames = _proofFiles.map((e) => e.name).toSet();
          final newFiles = petitionProvider.tempEvidence
              .where((e) => !existingNames.contains(e.name))
              .toList();

          if (newFiles.isNotEmpty) {
            _proofFiles.addAll(newFiles);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Auto-attached ${newFiles.length} proofs from chat')),
            );
          }
        });
        // Clear temp evidence to prevent processing again
        petitionProvider.clearTempEvidence();
      }
      // 2. Fallback to Router 'extra' (Legacy/Android Paths)
      else {
        final extra = GoRouterState.of(context).extra;
        if (extra is Map && extra['evidencePaths'] is List) {
          final paths = extra['evidencePaths'] as List;
          if (paths.isNotEmpty) {
            // Only process if we haven't already (simple check)
            if (_proofFiles.isEmpty) {
              setState(() {
                _proofFiles = paths.map((p) {
                  final name = p.toString().split('/').last;
                  return PlatformFile(name: name, size: 0, path: p.toString());
                }).toList();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Auto-attached ${paths.length} proofs from chat')),
              );
            }
          }
        }
      }

      // Also check for auto-fill fields from Router
      final extra = GoRouterState.of(context).extra;
      if (extra is Map) {
        if (extra.containsKey('complaintType') &&
            _titleController.text.isEmpty) {
          _titleController.text = extra['complaintType'].toString();
        }
        if (extra.containsKey('fullName') &&
            _petitionerNameController.text.isEmpty) {
          _petitionerNameController.text = extra['fullName'].toString();
        }
        if (extra.containsKey('phone') && _phoneNumberController.text.isEmpty) {
          _phoneNumberController.text = extra['phone'].toString();
        }
        if (extra.containsKey('address') && _addressController.text.isEmpty) {
          _addressController.text = extra['address'].toString();
        }

        if (_groundsController.text.isEmpty &&
            (extra.containsKey('details') ||
                extra.containsKey('incident_details'))) {
          String combined = "";
          if (extra['incident_address'] != null &&
              extra['incident_address'].toString().isNotEmpty) {
            combined += "Location: ${extra['incident_address']}\n\n";
          }
          combined += extra['details']?.toString() ??
              extra['incident_details']?.toString() ??
              '';
          _groundsController.text = combined;
        }

        if (_prayerReliefController.text.isEmpty &&
            _titleController.text.isNotEmpty) {
          _prayerReliefController.text =
              "I request the police authorities to register an FIR and take necessary action to trace and recover my stolen belongings.";
        }
      }
    });
  }

  Future<void> _initBackend() async {
    final List<String> candidates = <String>[];

    if (kIsWeb) {
      final Uri u = Uri.base;
      final String scheme = u.scheme.isNotEmpty ? u.scheme : 'http';
      final String host = u.host.isNotEmpty ? u.host : 'localhost';
      candidates.add('$scheme://$host:8000');
      candidates.add('$scheme://$host');
    }

    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      // candidates.add('http://10.0.2.2:8000');
      // candidates.add('http://10.0.2.2');
      candidates.add('https://fastapi-app-335340524683.asia-south1.run.app');
    }

    // candidates.add('https://fastapi-app-335340524683.asia-south1.run.app');
    // candidates.add('http://localhost');
    candidates.add('https://fastapi-app-335340524683.asia-south1.run.app');
    candidates.add('http://localhost');

    String? resolved;
    for (final String base in candidates) {
      if (await _isBackendHealthy(base)) {
        resolved = base;
        break;
      }
    }

    resolved ??= candidates.first;
    setState(() {
      _ocrEndpoint = '$resolved/api/ocr/extract';
      _ocrEndpointFallbacks = <String>[
        '$resolved/api/ocr/extract-case/',
        '$resolved/extract-case/',
      ];
    });
  }

  Future<bool> _isBackendHealthy(String baseUrl) async {
    try {
      final List<String> healthPaths = <String>[
        '/api/ocr/health',
        '/api/health',
        '/ocr/health',
        '/',
        '/Root',
      ];
      for (final String p in healthPaths) {
        final resp = await _dio.get(
          '$baseUrl$p',
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            validateStatus: (_) => true,
          ),
        );
        if (resp.statusCode != null &&
            resp.statusCode! >= 200 &&
            resp.statusCode! < 400) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _petitionerNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _groundsController.dispose();
    _prayerReliefController.dispose();
    super.dispose();
  }

  Widget _buildOcrSummaryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extracted Text', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (_ocrResult?['text'] as String?) ?? '',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPetition() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);

    try {
      if (_ocrResult == null && _pickedFiles.isNotEmpty) {
        await _runOcrOnFile(_pickedFiles.first);
      }
    } catch (_) {}

    final String? extractedText =
        ((_ocrResult?['text'] as String?)?.trim().isNotEmpty == true)
            ? _ocrResult!['text']
            : null;

    final petition = Petition(
      title: _titleController.text,
      type: PetitionType.other, // default
      status: PetitionStatus.draft, // default
      petitionerName: _petitionerNameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
      grounds: _groundsController.text,
      prayerRelief: _prayerReliefController.text.isEmpty
          ? null
          : _prayerReliefController.text,
      extractedText: extractedText,
      userId: authProvider.user!.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      if (_pickedFiles.isNotEmpty) {
        final String folderName = _titleController.text.isNotEmpty
            ? _titleController.text
            : 'petition_${DateTime.now().millisecondsSinceEpoch}';
        await LocalStorageService.savePickedFiles(
          files: _pickedFiles,
          subfolderName: folderName,
        );
      }
    } catch (e) {
      // Silently ignore
    }

    // Pass files to provider for upload
    final success = await petitionProvider.createPetition(
      petition: petition,
      handwrittenFile: _pickedFiles.isNotEmpty ? _pickedFiles.first : null,
      proofFiles: _proofFiles,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Petition created successfully!'),
              backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _petitionerNameController.clear();
        _phoneNumberController.clear();
        _addressController.clear();
        _groundsController.clear();
        _prayerReliefController.clear();
        setState(() {
          _pickedFiles = [];
          _proofFiles = [];
          _ocrResult = null;
        });
        await petitionProvider.fetchPetitions(authProvider.user!.uid);
        widget.onCreatedSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to create petition'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runOcrOnFile(PlatformFile file) async {
    if (_isExtracting) return;
    setState(() => _isExtracting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extracting text from document...')),
    );

    try {
      if (_ocrEndpoint.isEmpty) await _initBackend();
      if (_ocrEndpoint.isEmpty) throw Exception('OCR service not available');

      if (file.size <= 0) throw Exception('Selected file is empty');
      if (file.size > 5 * 1024 * 1024)
        throw Exception('File too large (max 5MB)');

      MultipartFile mFile;
      if (file.bytes != null) {
        mFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else if (file.path != null) {
        mFile = await MultipartFile.fromFile(file.path!, filename: file.name);
      } else {
        throw Exception('File content unavailable');
      }

      final formData = FormData.fromMap({'file': mFile});

      Response? response;
      final List<String> allEndpoints = [
        _ocrEndpoint,
        ..._ocrEndpointFallbacks
      ];
      DioException? lastError;

      for (final endpoint in allEndpoints) {
        try {
          response = await _dio.post(
            endpoint,
            data: formData,
            options: Options(
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
              followRedirects: false,
              validateStatus: (code) =>
                  code != null && code >= 200 && code < 400,
            ),
          );
          break;
        } on DioException catch (e) {
          lastError = e;
          final sc = e.response?.statusCode;
          if (sc == null) await _initBackend();
          continue;
        }
      }

      if (response == null) throw lastError ?? Exception('OCR request failed');

      final data = Map<String, dynamic>.from(response.data);
      final extracted = (data['text'] as String?)?.trim() ?? '';

      if (extracted.isNotEmpty) {
        setState(() => _ocrResult = {'text': extracted});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text extraction successful')),
        );
      } else {
        setState(() => _ocrResult = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No text detected in the selected file.')),
        );
      }
    } catch (e) {
      String msg = 'OCR failed';
      if (e is DioException) {
        final sc = e.response?.statusCode;
        final body = e.response?.data;
        msg =
            'OCR failed (${sc ?? 'network'}): ${body is String ? body : body?['detail'] ?? e.message}';
      } else {
        msg = 'OCR failed: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === BASIC INFORMATION: ONLY Name, Phone, Address ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Petition type (Theft/ Robery,etc) *',
                        hintText: 'Enter a short title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petitionerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please enter phone number';
                        if (!RegExp(r'^\d{10}$').hasMatch(v))
                          return 'Enter valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        hintText: 'Full residential / office address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Please enter address' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === PETITION DETAILS ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Petition Details',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _groundsController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Grounds / Reasons *',
                        hintText: 'Explain why you are filing this petition...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Please enter grounds' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _prayerReliefController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Prayer / Relief Sought (Optional)',
                        hintText: 'What do you want the court to do?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // === HANDWRITTEN DOCUMENT ===
                    Text(
                      'HandWritten Document',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Handwritten'),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    allowMultiple: false,
                                    withData: true,
                                    type: FileType.image,
                                  );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setState(() => _pickedFiles = result.files);
                                    await _runOcrOnFile(result.files.first);
                                  }
                                },
                        ),
                        if (_pickedFiles.isNotEmpty)
                          Text('${_pickedFiles.length} file selected'),
                        if (_isExtracting)
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (_pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(_pickedFiles.first.name,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${(_pickedFiles.first.size / 1024).toStringAsFixed(1)} KB'),
                          trailing: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                      _pickedFiles = [];
                                      _ocrResult = null;
                                    }),
                          ),
                        ),
                      ),
                    ],
                    if (_ocrResult != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Extracted Details',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildOcrSummaryCard(theme),
                    ],

                    const SizedBox(height: 24),

                    // === RELATED DOCUMENT PROOFS ===
                    Text(
                      'Related Document Proofs (Optional)',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Proofs'),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    withData: true,
                                    type: FileType.any,
                                  );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setState(() {
                                      _proofFiles.addAll(result.files);
                                    });
                                  }
                                },
                        ),
                        if (_proofFiles.isNotEmpty)
                          Text('${_proofFiles.length} file(s) selected'),
                      ],
                    ),
                    if (_proofFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _proofFiles.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final f = _proofFiles[index];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: const Icon(Icons.attach_file),
                              title:
                                  Text(f.name, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${(f.size / 1024).toStringAsFixed(1)} KB'),
                              trailing: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.close),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _proofFiles.removeAt(index)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPetition,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Petition',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
