import 'package:flutter/material.dart';
import 'package:Dharma/models/onboarding_content.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;
  final bool isLastPage;

  const OnboardingPage({
    super.key,
    required this.content,
    this.isLastPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: content.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              content.icon,
              size: 80,
              color: content.color,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            content.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: content.color,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            content.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Features List
          ...content.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: content.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),

          // Example Text (if provided)
          if (content.exampleText != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: content.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: content.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                content.exampleText!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: content.color.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
