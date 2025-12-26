// lib/screens/police_dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';   // <-- add this
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

  final petitionProvider =
      Provider.of<PetitionProvider>(context, listen: false);
  final auth =
      Provider.of<AuthProvider>(context, listen: false);

  // ✅ Load station-wise stats
  petitionProvider.fetchPetitionStats(
    stationName: auth.userProfile!.stationName,
  );

  // ✅ Auto-refresh every 30 seconds (station-wise)
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) {
      petitionProvider.fetchPetitionStats(
        stationName: auth.userProfile!.stationName,
      );
    },
  );
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

    return DashboardBody(
      auth: auth,
      cases: cases,
      theme: theme,
      isPolice: true,
    );
  }
}