import 'package:flutter/material.dart';

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final List<String> features;
  final String? exampleText;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
    this.exampleText,
    required this.color,
  });

  static List<OnboardingContent> getCitizenOnboarding(BuildContext context) {
    // App's primary orange color
    const Color primaryOrange = Color(0xFFFC633C);
    const Color darkOrange = Color(0xFFE55530);
    const Color lightOrange = Color(0xFFFF7F50);
    const Color accentOrange = Color(0xFFFF8C42);
    const Color warmOrange = Color(0xFFFF6B35);
    const Color softOrange = Color(0xFFFFB347);

    try {
      final locale = Localizations.localeOf(context);
      final isTelugu = locale.languageCode == 'te';
      // debugPrint('🌍 Onboarding Locale: ${locale.languageCode}, isTelugu: $isTelugu');

      if (isTelugu) {
        return [
          // Screen 1: Welcome (Telugu)
          OnboardingContent(
            title: 'ధర్మకు స్వాగతం',
            description: 'న్యాయానికి మీ AI ఆధారిత డిజిటల్ సహచరుడు, సులభంగా.',
            icon: Icons.balance,
            features: [
              'రోజులో 24 గంటలు ఫిర్యాదులు చేయండి',
              'తక్షణ న్యాయ సలహా పొందండి',
              'మీ కేసులను ట్రాక్ చేయండి',
              'అత్యవసర హెల్ప్‌లైన్‌లను యాక్సెస్ చేయండి',
            ],
            color: primaryOrange,
          ),

          // Screen 2: AI Virtual Police Officer (Telugu)
          OnboardingContent(
            title: 'మీ 24/7 వర్చువల్ పోలీస్ ఆఫీసర్',
            description: 'ఫిర్యాదులు చేయండి, ఆధారాలు అప్‌లోడ్ చేయండి మరియు తక్షణ న్యాయ సహాయం పొందండి - అన్నీ AI ద్వారా',
            icon: Icons.smart_toy,
            features: [
              '🎤 వాయిస్ ఇన్‌పుట్ (ASR): ఏదైనా భారతీయ భాషలో మాట్లాడండి',
              '📸 జియో-కామెరా: లొకేషన్ ప్రూఫ్‌తో ఆధారాలు క్యాప్చర్ చేయండి',
              '📄 డాక్యుమెంట్ అప్‌లోడ్: న్యాయ పత్రాలను తక్షణమే విశ్లేషించండి',
              '📝 ఆటో పిటిషన్: AI మీ కోసం FIR/పిటిషన్‌లను రూపొందిస్తుంది',
              '👮‍♂️ వర్చువల్ ఆఫీసర్: AI మిమ్మల్ని నిజమైన పోలీస్ ఆఫీసర్ లాగా నడిపిస్తుంది',
            ],
            exampleText: 'నాకు దొంగతనం గురించి ఫిర్యాదు చేయాలి',
            color: darkOrange,
          ),

          // Screen 3: File Petitions (Telugu)
          OnboardingContent(
            title: 'నిమిషాల్లో పిటిషన్లు దాఖలు చేయండి',
            description: 'సంక్లిష్టమైన పత్రాలు లేకుండా FIR అభ్యర్థనలు, బెయిల్ అప్లికేషన్లు మరియు ఫిర్యాదులను సమర్పించండి',
            icon: Icons.description,
            features: [
              'సులభమైన పిటిషన్ సృష్టి',
              'ముందుగా రూపొందించిన టెంప్లేట్‌లు',
              'రియల్ టైమ్ స్టేటస్ ట్రాకింగ్',
              'అధికారులకు నేరుగా సమర్పణ',
            ],
            color: lightOrange,
          ),

          // Screen 4: Expert Legal Help (Telugu)
          OnboardingContent(
            title: 'నిపుణుల న్యాయ సహాయం',
            description: 'న్యాయ నిపుణులను అడగండి, కోర్టుకు సిద్ధం అవ్వండి మరియు మీ హక్కులను తెలుసుకోండి',
            icon: Icons.gavel,
            features: [
              'న్యాయ ప్రశ్నల వ్యవస్థ',
              'సాక్షి తయారీ సాధనాలు',
              'కోర్టు విధాన మార్గదర్శకాలు',
              'మీ హక్కులను తెలుసుకోండి',
            ],
            color: accentOrange,
          ),

          // Screen 5: Emergency Helpline (Telugu)
          OnboardingContent(
            title: 'మీకు అవసరమైనప్పుడు సహాయం',
            description: 'పోలీస్, మహిళా హెల్ప్‌లైన్, న్యాయ సహాయం మరియు అత్యవసర సేవలకు ఒక్క ట్యాప్‌తో యాక్సెస్',
            icon: Icons.emergency,
            features: [
              'పోలీస్: 100',
              'మహిళా హెల్ప్‌లైన్: 1091',
              'చైల్డ్ హెల్ప్‌లైన్: 1098',
              '24/7 అందుబాటులో ఉంది',
            ],
            color: warmOrange,
          ),

          // Screen 6: You're All Set (Telugu)
          OnboardingContent(
            title: 'మీరు సిద్ధంగా ఉన్నారు!',
            description: 'మీ న్యాయ హక్కులు మరియు రక్షణలను అన్వేషించడం ప్రారంభించండి',
            icon: Icons.check_circle,
            features: [
              'అన్ని ఫీచర్లు అన్‌లాక్ చేయబడ్డాయి',
              'AI సహాయకుడు సిద్ధంగా ఉన్నారు',
              'అత్యవసర హెల్ప్‌లైన్‌లు యాక్టివ్‌గా ఉన్నాయి',
              'మీ న్యాయ సహచరుడు వేచి ఉన్నారు',
            ],
            color: softOrange,
          ),
        ];
      }
    } catch (e) {
      // debugPrint('Error getting locale: $e');
      // Fallback to English
    }
    
    // English (Default)
    return [
      // Screen 1: Welcome
      OnboardingContent(
        title: 'Welcome to Dharma',
        description: 'Your AI-powered legal companion for accessing justice, simplified.',
        icon: Icons.balance,
        features: [
          'File complaints 24/7',
          'Get instant legal guidance',
          'Track your cases',
          'Access emergency helplines',
        ],
        color: primaryOrange,
      ),

      // Screen 2: AI Virtual Police Officer
      OnboardingContent(
        title: 'Your 24/7 Virtual Police Officer',
        description: 'File complaints, upload evidence, and get instant legal help - all powered by AI',
        icon: Icons.smart_toy,
        features: [
          '🎤 Voice Input (ASR): Speak in any Indian language',
          '📸 Geo-Camera: Capture evidence with location proof',
          '📄 Document Upload: Analyze legal documents instantly',
          '📝 Auto Petition: AI generates FIR/petitions for you',
          '👮‍♂️ Virtual Officer: AI guides you like a real police officer',
        ],
        exampleText: 'मुझे चोरी की शिकायत दर्ज करनी है\n(I want to file a theft complaint)',
        color: darkOrange,
      ),

      // Screen 3: File Petitions
      OnboardingContent(
        title: 'File Petitions in Minutes',
        description: 'Submit FIR requests, bail applications, and complaints without complex paperwork',
        icon: Icons.description,
        features: [
          'Easy petition creation',
          'Pre-built templates',
          'Track status in real-time',
          'Direct submission to authorities',
        ],
        color: lightOrange,
      ),

      // Screen 4: Expert Legal Help
      OnboardingContent(
        title: 'Expert Legal Support',
        description: 'Ask legal experts, prepare for court, and understand your rights',
        icon: Icons.gavel,
        features: [
          'Legal query system',
          'Witness preparation tools',
          'Court procedure guides',
          'Know your rights',
        ],
        color: accentOrange,
      ),

      // Screen 5: Emergency Helpline
      OnboardingContent(
        title: 'Help When You Need It',
        description: 'One-tap access to police, women helpline, legal aid, and emergency services',
        icon: Icons.emergency,
        features: [
          'Police: 100',
          'Women Helpline: 1091',
          'Child Helpline: 1098',
          'Available 24/7',
        ],
        color: warmOrange,
      ),

      // Screen 6: You're All Set
      OnboardingContent(
        title: 'You\'re Ready to Go!',
        description: 'Start exploring your legal rights and protections',
        icon: Icons.check_circle,
        features: [
          'All features unlocked',
          'AI assistant ready',
          'Emergency helplines active',
          'Your legal companion awaits',
        ],
        color: softOrange,
      ),
    ];
  }
}
