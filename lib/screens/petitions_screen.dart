import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class PetitionsScreen extends StatefulWidget {
  const PetitionsScreen({super.key});

  @override
  State<PetitionsScreen> createState() => _PetitionsScreenState();
}

class _PetitionsScreenState extends State<PetitionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPetitions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPetitions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider = Provider.of<PetitionProvider>(context, listen: false);
    
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petition Management'),
        bottom: TabBar(
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
    );
  }

  Widget _buildPetitionsListTab(ThemeData theme) {
    return Consumer<PetitionProvider>(
      builder: (context, petitionProvider, child) {
        if (petitionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (petitionProvider.petitions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Petitions Yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first petition using the "Create New" tab',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchPetitions,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petitionProvider.petitions.length,
            itemBuilder: (context, index) {
              final petition = petitionProvider.petitions[index];
              return _buildPetitionCard(petition, theme);
            },
          ),
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
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    petition.type.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      petition.courtName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    petition.petitionerName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (petition.firNumber != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'FIR: ${petition.firNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(petition.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    petition.status.displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 32),
                _buildDetailRow('Type', petition.type.displayName),
                _buildDetailRow('Petitioner', petition.petitionerName),
                if (petition.respondentName != null)
                  _buildDetailRow('Respondent', petition.respondentName!),
                _buildDetailRow('Court', petition.courtName),
                if (petition.caseNumber != null)
                  _buildDetailRow('Case Number', petition.caseNumber!),
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
    return const CreatePetitionForm();
  }
}

class CreatePetitionForm extends StatefulWidget {
  const CreatePetitionForm({super.key});

  @override
  State<CreatePetitionForm> createState() => _CreatePetitionFormState();
}

class _CreatePetitionFormState extends State<CreatePetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petitionerNameController = TextEditingController();
  final _respondentNameController = TextEditingController();
  final _courtNameController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _groundsController = TextEditingController();
  final _prayerReliefController = TextEditingController();
  
  PetitionType _selectedType = PetitionType.bail;
  PetitionStatus _selectedStatus = PetitionStatus.draft;
  String? _selectedCaseId;
  String? _firNumber;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _petitionerNameController.dispose();
    _respondentNameController.dispose();
    _courtNameController.dispose();
    _caseNumberController.dispose();
    _groundsController.dispose();
    _prayerReliefController.dispose();
    super.dispose();
  }

  Future<void> _submitPetition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider = Provider.of<PetitionProvider>(context, listen: false);

    final petition = Petition(
      title: _titleController.text,
      type: _selectedType,
      status: _selectedStatus,
      caseId: _selectedCaseId,
      firNumber: _firNumber,
      petitionerName: _petitionerNameController.text,
      respondentName: _respondentNameController.text.isEmpty 
          ? null 
          : _respondentNameController.text,
      courtName: _courtNameController.text,
      caseNumber: _caseNumberController.text.isEmpty 
          ? null 
          : _caseNumberController.text,
      grounds: _groundsController.text,
      prayerRelief: _prayerReliefController.text.isEmpty 
          ? null 
          : _prayerReliefController.text,
      userId: authProvider.user!.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    final success = await petitionProvider.createPetition(petition);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Petition created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _petitionerNameController.clear();
        _respondentNameController.clear();
        _courtNameController.clear();
        _caseNumberController.clear();
        _groundsController.clear();
        _prayerReliefController.clear();
        await petitionProvider.fetchPetitions(authProvider.user!.uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create petition'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Petition Title *',
                        hintText: 'Enter a descriptive title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PetitionType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Petition Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: PetitionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PetitionStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: PetitionStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (caseProvider.cases.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedCaseId,
                        decoration: const InputDecoration(
                          labelText: 'Link to Case (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No case linked'),
                          ),
                          ...caseProvider.cases.map((caseDoc) {
                            return DropdownMenuItem(
                              value: caseDoc.id,
                              child: Text('${caseDoc.firNumber} - ${caseDoc.title}'),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCaseId = value;
                            if (value != null) {
                              final selectedCase = caseProvider.cases
                                  .firstWhere((c) => c.id == value);
                              _firNumber = selectedCase.firNumber;
                            } else {
                              _firNumber = null;
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parties & Court Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petitionerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Petitioner Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter petitioner name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _respondentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Respondent Name (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _courtNameController,
                      decoration: const InputDecoration(
                        labelText: 'Court Name *',
                        hintText: 'e.g., High Court of Delhi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter court name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Case Number (Optional)',
                        hintText: 'e.g., CRL.M.C. 1234/2024',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Petition Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groundsController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Grounds / Reasons *',
                        hintText: 'Enter detailed grounds for the petition...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter grounds';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prayerReliefController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Prayer / Relief Sought (Optional)',
                        hintText: 'Enter the relief or remedy being requested...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPetition,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Petition',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
