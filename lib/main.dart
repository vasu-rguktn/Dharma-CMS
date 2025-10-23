import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:nyay_setu_flutter/config/theme.dart';
import 'package:nyay_setu_flutter/providers/auth_provider.dart';
import 'package:nyay_setu_flutter/providers/case_provider.dart';
import 'package:nyay_setu_flutter/providers/complaint_provider.dart';
import 'package:nyay_setu_flutter/providers/petition_provider.dart';
import 'package:nyay_setu_flutter/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Dharma',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
