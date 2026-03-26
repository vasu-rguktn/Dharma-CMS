import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dharma_police/firebase_options.dart';
import 'package:dharma_police/config/theme.dart';
import 'package:dharma_police/l10n/app_localizations.dart';

import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/providers/settings_provider.dart';
import 'package:dharma_police/providers/case_provider.dart';
import 'package:dharma_police/providers/petition_provider.dart';

import 'package:dharma_police/router/app_router.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init ──
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  runApp(const DharmaPoliceApp());
}

class DharmaPoliceApp extends StatelessWidget {
  const DharmaPoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── If Firebase failed to init, show setup instructions ──
    if (!_firebaseInitialized) {
      return MaterialApp(
        title: 'Dharma Police — Setup Required',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _FirebaseSetupScreen(),
      );
    }

    return MultiProvider(
      providers: [
        // ── Auth ──
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // ── Settings (language) ──
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),

        // ── Cases ──
        ChangeNotifierProvider<CaseProvider>(
          create: (_) => CaseProvider(),
        ),

        // ── Petitions ──
        ChangeNotifierProvider<PetitionProvider>(
          create: (_) => PetitionProvider(),
        ),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, _) {
          return MaterialApp.router(
            title: 'Dharma Police',
            debugShowCheckedModeBanner: false,

            // ── Theme (navy-accented for police) ──
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // ── Router ──
            routerConfig: AppRouter.router,

            // ── Localization ──
            locale: settingsProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}

/// Shown when Firebase credentials are missing (placeholder API keys).
class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 80, color: Colors.indigo.shade400),
              const SizedBox(height: 24),
              const Text(
                'Dharma Police Command Center',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Firebase Setup Required',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To run this app, configure Firebase:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    _Step(n: '1', text: 'Install FlutterFire CLI:\n  dart pub global activate flutterfire_cli'),
                    _Step(n: '2', text: 'Run from new_police_frontend/:\n  flutterfire configure --project=ap-dharma-cms-1998'),
                    _Step(n: '3', text: 'Restart the app:\n  flutter run -d chrome --web-port 5556'),
                    SizedBox(height: 16),
                    Text(
                      'This will generate lib/firebase_options.dart\nwith your real Firebase project credentials.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Backend should be running at http://localhost:8000 ✓\nSwagger docs: http://localhost:8000/docs',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.indigo.shade400,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, fontFamily: 'monospace', height: 1.5)),
          ),
        ],
      ),
    );
  }
}
