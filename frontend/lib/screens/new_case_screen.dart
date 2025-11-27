import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _firNumberController = TextEditingController();
  final _districtController = TextEditingController();
  final _policeStationController = TextEditingController();
  final _complainantNameController = TextEditingController();
  final _incidentDetailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _firNumberController.dispose();
    _districtController.dispose();
    _policeStationController.dispose();
    _complainantNameController.dispose();
    _incidentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);

      final newCase = CaseDoc(
        title: _titleController.text,
        firNumber: _firNumberController.text,
        district: _districtController.text.isNotEmpty
            ? _districtController.text
            : null,
        policeStation: _policeStationController.text.isNotEmpty
            ? _policeStationController.text
            : null,
        complainantName: _complainantNameController.text.isNotEmpty
            ? _complainantNameController.text
            : null,
        incidentDetails: _incidentDetailsController.text.isNotEmpty
            ? _incidentDetailsController.text
            : null,
        status: CaseStatus.newCase,
        dateFiled: Timestamp.now(),
        lastUpdated: Timestamp.now(),
        userId: authProvider.userProfile?.uid,
      );

      await caseProvider.addCase(newCase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.caseCreatedSuccess)),
        );
        context.go('/cases');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingCase(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/cases'),
                ),
                Expanded(
                  child: Text(
                    localizations.createNewCase,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.basicInformation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.caseTitleRequired,
                        hintText: localizations.caseTitleHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.pleaseEnterCaseTitle;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firNumberController,
                      decoration: InputDecoration(
                        labelText: localizations.firNumberRequired,
                        hintText: localizations.firNumberHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.pleaseEnterFirNumber;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.locationDetails,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: localizations.district,
                        hintText: localizations.enterDistrict,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _policeStationController,
                      decoration: InputDecoration(
                        labelText: localizations.policeStation,
                        hintText: localizations.enterPoliceStation,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.additionalInformation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _complainantNameController,
                      decoration: InputDecoration(
                        labelText: localizations.complainantName,
                        hintText: localizations.enterComplainantName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _incidentDetailsController,
                      decoration: InputDecoration(
                        labelText: localizations.incidentDetails,
                        hintText: localizations.describeIncident,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        localizations.createCase,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
