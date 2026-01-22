// lib/screens/police_dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'dashboard_body.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  Timer? _refreshTimer;

  // @override
  // void initState() {
  //   super.initState();

  //   // 1. Load the count immediately
  //   final petitionProvider =
  //       Provider.of<PetitionProvider>(context, listen: false);
  //   petitionProvider.fetchPetitionCount();

  //   // 2. Auto‑refresh every 30 seconds
  //   _refreshTimer = Timer.periodic(
  //     const Duration(seconds: 30),
  //     (_) => petitionProvider.fetchPetitionCount(),
  //   );
  // }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petitionProvider = Provider.of<PetitionProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      final profile = auth.userProfile;
      
      // ✅ Load organizational stats initially
      petitionProvider.fetchPetitionStats(
        officerId: profile?.uid,
        stationName: profile?.stationName,
        district: profile?.district,
      );

      // ✅ Load recent petitions for activity section
      petitionProvider.fetchFilteredPetitions(
        isPolice: true,
        officerId: profile?.uid,
        stationName: profile?.stationName,
        district: profile?.district,
        filter: PetitionFilter.all,
      );

      // ✅ Auto-refresh every 30 seconds
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (mounted) {
            petitionProvider.fetchPetitionStats(
              officerId: profile?.uid,
              stationName: profile?.stationName,
              district: profile?.district,
            );
            petitionProvider.fetchFilteredPetitions(
              isPolice: true,
              officerId: profile?.uid,
              stationName: profile?.stationName,
              district: profile?.district,
              filter: PetitionFilter.all,
            );
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cases = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Use GoRouter's canPop to check navigation history
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return false; // Prevent default exit, we handled navigation
        }
        return true; // Allow exit only if truly root
      },
      child: DashboardBody(
        auth: auth,
        cases: cases,
        theme: theme,
        isPolice: true,
      ),
    );
  }
}