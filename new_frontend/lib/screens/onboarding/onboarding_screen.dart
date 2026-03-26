import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  static const Color orange = Color(0xFFFC633C);

  final _pages = const [
    _OnboardingPage(icon: Icons.chat, title: 'AI Legal Assistant', desc: 'Chat with our AI-powered legal assistant for guidance on legal matters in your language.', color: Colors.blue),
    _OnboardingPage(icon: Icons.gavel, title: 'File Petitions', desc: 'Create and track petitions digitally. Get real-time updates on your case status.', color: Colors.deepPurple),
    _OnboardingPage(icon: Icons.phone, title: 'Emergency Helplines', desc: 'Quick access to all emergency helplines. One tap to call police, ambulance, or other services.', color: Colors.red),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topRight, child: TextButton(onPressed: _finish, child: const Text('Skip', style: TextStyle(color: orange, fontSize: 16)))),
            Expanded(child: PageView.builder(controller: _controller, itemCount: _pages.length, itemBuilder: (_, i) => _pages[i])),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(controller: _controller, count: _pages.length, effect: const WormEffect(activeDotColor: orange, dotHeight: 10, dotWidth: 10)),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.page?.round() == _pages.length - 1) { _finish(); }
                      else { _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: orange, shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
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

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _OnboardingPage({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(desc, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
