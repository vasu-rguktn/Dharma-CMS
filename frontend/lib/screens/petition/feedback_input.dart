
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
class FeedbackInput extends StatefulWidget {
  final String petitionId;
  final VoidCallback onSuccess;

  const FeedbackInput({
    super.key,
    required this.petitionId,
    required this.onSuccess,
  });

  @override
  State<FeedbackInput> createState() => _FeedbackInputState();
}

class _FeedbackInputState extends State<FeedbackInput> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);
    
    // Slight delay to simulate network/ensure UI updates
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (!mounted) return;
      await Provider.of<PetitionProvider>(context, listen: false).submitFeedback(
        widget.petitionId,
        _rating,
        _commentController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (_isSubmitting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.rateOfficerAndFeedback,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.pleaseRateOfficerHandling,
            style: TextStyle(fontSize: 12, color: Colors.brown),
          ),
          const SizedBox(height: 12),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() => _rating = index + 1.0);
                },
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: localizations.writeYourFeedbackOptional,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating == 0 ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.submitFeedback),
            ),
          ),
        ],
      ),
    );
  }
}
