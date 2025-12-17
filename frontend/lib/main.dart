import 'package:Dharma/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:Dharma/config/theme.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/legal_queries_provider.dart';
import 'package:Dharma/providers/settings_provider.dart';

import 'package:Dharma/router/app_router.dart';
import 'package:Dharma/services/firestore_service.dart';
import 'firebase_options.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirestoreService.configureFirestore();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// 🔹 Citizen Auth
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
         ChangeNotifierProvider<PoliceAuthProvider>(
  create: (_) => PoliceAuthProvider()..loadPoliceProfileIfLoggedIn(),
),

        /// 🔹 Police Auth (NEW)
        

        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),

        ChangeNotifierProvider<LegalQueriesProvider>(
          create: (_) => LegalQueriesProvider(),
        ),

        /// 🔹 Feature providers
        ChangeNotifierProxyProvider<AuthProvider, CaseProvider>(
          create: (_) => CaseProvider(),
          update: (_, auth, previous) => previous ?? CaseProvider(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, ComplaintProvider>(
          create: (_) => ComplaintProvider(),
          update: (_, auth, previous) => previous ?? ComplaintProvider(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, PetitionProvider>(
          create: (_) => PetitionProvider(),
          update: (_, auth, previous) => previous ?? PetitionProvider(),
        ),
      ],

      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, _) {
          return MaterialApp.router(
            title: 'Dharma',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            routerConfig: AppRouter.router,

            locale: settingsProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('te'),
            ],
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
