import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class HelplineScreen extends StatelessWidget {
  static const Color primaryColor = Color(0xFFFC633C);

  const HelplineScreen({super.key});

  Future<void> _makeCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(url)) { 
     debugPrint("Cannot call $number");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final localization = AppLocalizations.of(context)!;

    final List<Map<String, String>> helplines = [
      {"type": localization.helplineEmergencyAll, "number": "112", "description": localization.helplineEmergencyAllDesc, "icon": "🚨"},
      {"type": localization.helplinePolice, "number": "100", "description": localization.helplinePoliceDesc, "icon": "👮"},
      {"type": localization.helplineFire, "number": "101", "description": localization.helplineFireDesc, "icon": "🚒"},
      {"type": localization.helplineAmbulance, "number": "102", "description": localization.helplineAmbulanceDesc, "icon": "🚑"},
      {"type": localization.helplineAmbulanceAlt, "number": "108", "description": localization.helplineAmbulanceAltDesc, "icon": "🚑"},
      {"type": localization.helplineWomen, "number": "1091", "description": localization.helplineWomenDesc, "icon": "👩‍🦰"},
      {"type": localization.helplineDomestic, "number": "181", "description": localization.helplineDomesticDesc, "icon": "🛡️"},
      {"type": localization.helplineChild, "number": "1098", "description": localization.helplineChildDesc, "icon": "👶"},
      {"type": localization.helplineCyber, "number": "1930", "description": localization.helplineCyberDesc, "icon": "💻"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          localization.emergencyHelplines,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: helplines.length,
        itemBuilder: (context, index) {
          final item = helplines[index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFFFE4DD).withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _makeCall(item['number']!),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item['icon']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['type']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.call_rounded, color: primaryColor, size: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 8,
        label: Text(
          localization.sos112,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.warning_rounded, size: 28),
        onPressed: () => _makeCall("112"),
      ),
    );
  }
}
