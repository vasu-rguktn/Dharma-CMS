import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharma/l10n/app_localizations.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({super.key});
  static const Color orange = Color(0xFFFC633C);

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) debugPrint('Cannot call $number');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final helplines = [
      {'type': l.helplineEmergencyAll, 'number': '112', 'desc': l.helplineEmergencyAllDesc, 'icon': '🚨'},
      {'type': l.helplinePolice, 'number': '100', 'desc': l.helplinePoliceDesc, 'icon': '👮'},
      {'type': l.helplineFire, 'number': '101', 'desc': l.helplineFireDesc, 'icon': '🚒'},
      {'type': l.helplineAmbulance, 'number': '102', 'desc': l.helplineAmbulanceDesc, 'icon': '🚑'},
      {'type': l.helplineWomen, 'number': '1091', 'desc': l.helplineWomenDesc, 'icon': '👩'},
      {'type': l.helplineChild, 'number': '1098', 'desc': l.helplineChildDesc, 'icon': '👶'},
      {'type': l.helplineCyber, 'number': '1930', 'desc': l.helplineCyberDesc, 'icon': '💻'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(backgroundColor: orange, foregroundColor: Colors.white, title: Text(l.emergencyHelplines, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: helplines.length,
        itemBuilder: (_, i) {
          final h = helplines[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [Colors.white, const Color(0xFFFFE4DD).withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: orange.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _call(h['number']!),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: orange.withOpacity(0.12), shape: BoxShape.circle), alignment: Alignment.center, child: Text(h['icon']!, style: const TextStyle(fontSize: 32))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h['type']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(h['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(24)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.phone, color: Colors.white, size: 16), const SizedBox(width: 6), Text(h['number']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
