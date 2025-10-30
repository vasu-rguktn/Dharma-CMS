import 'package:flutter/material.dart';

class LegalQueriesScreen extends StatefulWidget {
  const LegalQueriesScreen({super.key});

  @override
  State<LegalQueriesScreen> createState() => _LegalQueriesScreenState();
}

class _LegalQueriesScreenState extends State<LegalQueriesScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _queries = [];

  // ---- NEW: Orange colour -------------------------------------------------
  static const Color primaryOrange = Color(0xFFFC633C);
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submitQuery() {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _queries.insert(0, {
        'query': _queryController.text,
        'status': 'Answered',
        'date': DateTime.now().toString().split(' ')[0],
      });
    });

    _queryController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Query submitted successfully!'),
        backgroundColor: primaryOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Wrap the whole screen in a Theme so the ElevatedButton uses our orange
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryOrange,
            ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal Queries',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask legal questions and get AI-powered answers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit a Query',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _queryController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter your legal question here...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitQuery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Query'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Previous Queries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _queries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.question_answer,
                            size: 64,
                            color: primaryOrange.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No queries yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Submit your first legal query above',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _queries.length,
                      itemBuilder: (context, index) {
                        final query = _queries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryOrange,
                              child: const Icon(
                                Icons.question_answer,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              query['query']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${query['status']} • ${query['date']}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'Query Details',
                                    style: TextStyle(color: primaryOrange),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(query['query']!),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
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
    );
  }
}