import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:Dharma/models/onboarding_content.dart';
import 'package:Dharma/screens/onboarding/onboarding_page.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late List<OnboardingContent> _pages;
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = OnboardingContent.getCitizenOnboarding(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.completeOnboarding();
    if (mounted) {
      // Go to dashboard first, then push to AI chat
      context.go('/dashboard');
      // Wait a moment for dashboard to load, then push to AI chat
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          context.push('/ai-legal-chat');
        }
      });
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final localizations = AppLocalizations.of(context)!;
    final isTelugu = Localizations.localeOf(context).languageCode == 'te';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                localizations.skip,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return OnboardingPage(
                  content: _pages[index],
                  isLastPage: index == _pages.length - 1,
                );
              },
            ),
          ),

          // Bottom Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: WormEffect(
                    dotHeight: 12,
                    dotWidth: 12,
                    activeDotColor: _pages[_currentPage].color,
                    dotColor: Colors.grey.shade300,
                  ),
                ),

                const SizedBox(height: 24),

                // Next/Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      isLastPage 
                        ? (isTelugu ? 'ధర్మ వాడటం మొదలుపెట్టండి' : 'Start Using Dharma') 
                        : localizations.next,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
