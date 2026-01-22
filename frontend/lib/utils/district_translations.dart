import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class DistrictTranslations {
  static const Map<String, String> _districtTranslations = {
    'Alluri Sitharama Raju': 'అల్లూరి సీతారామ రాజు',
    'Anakapalli': 'అనకాపల్లి',
    'Anantapur': 'అనంతపురం',
    'Annamayya': 'అన్నమయ్య',
    'Bapatla': 'భాపట్ల',
    'Chittoor': 'చిత్తూరు',
    'East Godavari': 'తూర్పు గోదావరి',
    'Eluru': 'ఏలూరు',
    'Guntur': 'గుంటూరు',
    'Kadapa': 'కడప',
    'Kakinada': 'కాకినాడ',
    'Konaseema': 'కోనసీమ',
    'Krishna': 'కృష్ణ',
    'Kurnool': 'కర్నూలు',
    'Manyam': 'మన్యం',
    'Nandyal': 'నంద్యాల',
    'NTR': 'ఎన్.టి.ఆర్',
    'Palnadu': 'పాల్నాడు',
    'Prakasam': 'ప్రకాశం',
    'Sri Sathya Sai': 'శ్రీ సత్య సాయి',
    'Srikakulam': 'శ్రీకాకుళం',
    'Tirupati': 'తిరుపతి',
    'Visakhapatnam': 'విశాఖపట్నం',
    'Vizianagaram': 'విజయనగరం',
    'West Godavari': 'పశ్చిమ గోదావరి',
  };

  // Common suffixes and patterns for translation
  static const Map<String, String> _commonSuffixes = {
    ' Town': ' టౌన్',
    ' Rural': ' రూరల్',
    ' Traffic': ' ట్రాఫిక్',
    ' Traffic PS': ' ట్రాఫిక్ PS',
    ' Taluk': ' తాలూకా',
    ' Taluk PS': ' తాలూకా PS',
    ' UPS': ' UPS',
    ' CCS': ' CCS',
    'I Town': 'I టౌన్',
    'II Town': 'II టౌన్',
    'III Town': 'III టౌన్',
    'IV Town': 'IV టౌన్',
  };

  // Place name translations - comprehensive map for common place names
  static const Map<String, String> _placeNameTranslations = {
    // Major cities/towns
    'Nuzvid': 'నూజివీడు',
    'Gudivada': 'గుడివాడ',
    'Machilipatnam': 'మచిలీపట్నం',
    'Vijayawada': 'విజయవాడ',
    'Eluru': 'ఏలూరు',
    'Kurnool': 'కర్నూలు',
    'Adoni': 'ఆదోని',
    'Bhimavaram': 'భీమవరం',
    'Narasapuram': 'నరసాపురం',
    'Palakollu': 'పాలకొల్లు',
    'Tadepalligudem': 'తాడేపల్లిగూడెం',
    'Tanuku': 'తణుకు',
    'Madanapalle': 'మదనపల్లె',
    'Rajahmundry': 'రాజమండ్రి',
    'Tirupati': 'తిరుపతి',
    'Tirumala': 'తిరుమల',
    'Tirupathi': 'తిరుపతి',
    'Gudur': 'గూడూరు',
    'Ongole': 'ఒంగోలు',
    'Nellore': 'నెల్లూరు',
    'Srikakulam': 'శ్రీకాకుళం',
    'Vizianagaram': 'విజయనగరం',
    'Kadapa': 'కడప',
    'Anantapur': 'అనంతపురం',
    'Chittoor': 'చిత్తూరు',
    'Guntur': 'గుంటూరు',
    'Kakinada': 'కాకినాడ',
    'Visakhapatnam': 'విశాఖపట్నం',
    'Nandyal': 'నంద్యాల',
    'Proddatur': 'ప్రొద్దుటూరు',
    'Pulivendula': 'పులివెందుల',
    'Rayachoty': 'రాయచోటి',
    'Kalyandurg': 'కల్యాణదుర్గ',
    'Rayadurg': 'రాయదుర్గ',
    'Tadipathri': 'తాడిపత్రి',
    'Guntakal': 'గుంటకల్',
    'Gooty': 'గూటి',
    'Uravakonda': 'ఉరవకొండ',
    'Piler': 'పైలేరు',
    'Rajampet': 'రాజంపేట',
    'Kodur': 'కోడూరు',
    'Chinnamandem': 'చిన్నమందెం',
    'Kalikiri': 'కలికిరి',
    'Galiveedu': 'గలివీడు',
    'Lakkireddipalli': 'లక్కిరెడ్డిపల్లి',
    'Ramapuram': 'రామాపురం',
    'Sambepalli': 'సంబేపల్లి',
    'Veeraballi': 'వీరబల్లి',
    'Gurramkonda': 'గుర్రంకొండ',
    'Voyalpadu': 'వోయల్పాడు',
    'Kaikaluru': 'కైకలూరు',
    'Bhimadole': 'భీమడోలు',
    'Dwaraka Tirumala': 'ద్వారక తిరుమల',
    'Kalidindi': 'కలిదిండి',
    'Mandavalli': 'మండవల్లి',
    'Mudinepalli': 'ముదినేపల్లి',
    'Chebrole': 'చెబ్రోలు',
    'Ganapavaram': 'గణపవరం',
    'Nidamarru': 'నిడమర్రు',
    'Chintalapudi': 'చింతలపూడి',
    'Dharmajigudem': 'ధర్మజిగూడెం',
    'Jangareddygudem': 'జంగారెడ్డిగూడెం',
    'Lakkavaram': 'లక్కవరం',
    'Tadikalapudi': 'తాడికలపూడి',
    'Agiripalli': 'అగిరిపల్లి',
    'Chatrai': 'చత్రై',
    'Musunuru': 'ముసునూరు',
    'Denduluru': 'డెండులూరు',
    'Pedapadu': 'పెదపాడు',
    'Pedavegi': 'పెదవేగి',
    'Buttaigudem': 'బుట్టైగూడెం',
    'Jeelugumilli': 'జీలుగుమిల్లి',
    'T. Narasapuram': 'టి. నరసాపురం',
    'Kukunoor': 'కుకునూరు',
    'Velerupadu': 'వేలేరుపాడు',
    'Koyyalagudem': 'కొయ్యలగూడెం',
    'Polavaram': 'పోలవరం',
    'Yemmiganur': 'యెమ్మిగనూరు',
    'Gurazala': 'గురజాల',
    'Macherla': 'మాచెర్ల',
    'Piduguralla': 'పిడుగురల్ల',
    'Chilakaluripet': 'చిలకలూరిపేట',
    'Narsaraopet': 'నరసరావుపేట',
    'Narasaraopet': 'నరసరావుపేట',
    'Sattenapalli': 'సత్తెనపల్లి',
    'Bobbili': 'బొబ్బిలి',
    'Rajam': 'రాజం',
    'Srikalahasthi': 'శ్రీకాళహస్తి',
    'Srikalahasti': 'శ్రీకాళహస్తి',
    'Renigunta': 'రేణిగుంట',
    'Yerpedu': 'యెర్పేడు',
    'Pakala': 'పాకల',
    'Tirchanur': 'తిర్చనూరు',
    'Chandragiri': 'చంద్రగిరి',
    'Venkatagiri': 'వేంకటగిరి',
    'Puttur': 'పుత్తూరు',
    'Narayanavanam': 'నారాయణవనం',
    'Nagalapuram': 'నాగలాపురం',
    'Satyavedu': 'సత్యవేదు',
    'Amalapuram': 'అమలాపురం',
    'Mandapeta': 'మండపేట',
    'Ramachandrapuram': 'రామచంద్రపురం',
    'Kovvur': 'కొవ్వూరు',
    'Nidadavole': 'నిడదవోలు',
    'Dowaleswaram': 'దోవలేశ్వరం',
    'Kadiam': 'కాడియం',
    'Avanigadda': 'అవనిగడ్డ',
    'Pedana': 'పెదన',
    'Bandar': 'బందర్',
    'Gannavaram': 'గన్నవరం',
    'Vuyyuru': 'వుయ్యూరు',
    'Kankipadu': 'కంకిపాడు',
    'Gudlavalleru': 'గుడ్లవల్లేరు',
    'Nandivada': 'నందివాడ',
    'Kuchipudi': 'కూచిపూడి',
    'Pamarru': 'పమర్రు',
    'Thotlavalluru': 'తొత్లవల్లూరు',
    'Darsi': 'దర్శి',
    'Podili': 'పోడిలి',
    'Kanigiri': 'కానిగిరి',
    'Markapur': 'మార్కాపురం',
    'Chimakurthy': 'చిమకూర్తి',
    'Kothapatnam': 'కోతపత్నం',
    'Maddipadu': 'మద్దిపాడు',
    'Singarayakonda': 'సింగరాయకొండ',
    'Tangutur': 'తంగుటూరు',
    'Kandukur': 'కందుకూరు',
    'Kavali': 'కావలి',
    'Udayagiri': 'ఉదయగిరి',
    'Buchireddypalem': 'బుచ్చిరెడ్డిపాలెం',
    'Kovur': 'కోవూరు',
    'Krishnapatnam': 'కృష్ణపత్నం',
    'Muttukur': 'ముత్తుకూరు',
    'Podalakur': 'పోడలకూరు',
    'Itchapuram': 'ఇచ్చాపురం',
    'Kaviti': 'కావితి',
    'Mandasa': 'మండస',
    'Sompeta': 'సోంపేట',
    'Amadalavalasa': 'అమదాలవలస',
    'Ponduru': 'పొందూరు',
    'Etcherla': 'ఎట్చెర్ల',
    'Laveru': 'లవేరు',
    'Gara': 'గార',
    'Tekkali': 'తెక్కలి',
    'Hiramandalam': 'హిరమండలం',
    'Narasannapeta': 'నరసన్నపేట',
    'Meliaputti': 'మెలియపుత్తి',
    'Pathapatnam': 'పాతపత్నం',
    'Kotabommali': 'కోతబొమ్మలి',
    'Naupada': 'నౌపాడ',
    'Jammalamadugu': 'జమ్మలమడుగు',
    'Yerraguntla': 'యెర్రగుంట్ల',
    'Mylavaram': 'మైలవరం',
    'Talamanchipatnam': 'తలమంచిపత్నం',
    'Tallaproddatur': 'తల్లప్రొద్దుటూరు',
    'Pendlimarri': 'పెండ్లిమర్రి',
    'Kamalapuram': 'కమలాపురం',
    'Vallur': 'వల్లూరు',
    'Sidhout': 'సిధౌత్',
    'Vontimitta': 'వొంటిమిట్ట',
    'Badvel': 'బద్వేల్',
    'Mydukur': 'మైడుకూరు',
    'Atlur': 'అట్లూరు',
    'Duvvur': 'దువ్వూరు',
    'Khajipet': 'ఖాజిపేట',
    'Kalasapadu': 'కలసపాడు',
    'Porumamilla': 'పోరుమమిల్ల',
    'Lingala': 'లింగాల',
    'Simhadripuram': 'సింహద్రిపురం',
    'Thondur': 'తొందూరు',
    'Chekrayapet': 'చెక్రయపేట',
    'Vemula': 'వేముల',
    'Chodavaram': 'చోడవరం',
    'Kasimkota': 'కాసింకోట',
    'Narsipatnam': 'నర్సీపత్నం',
    'Payakaraopeta': 'పాయకరావుపేట',
    'Golugonda': 'గోలుగొండ',
    'Makavarapalem': 'మకవరపాలెం',
    'Nathavaram': 'నాథవరం',
    'Atchutapuram': 'అచ్యుతాపురం',
    'Parawada': 'పరవాడ',
    'Rambilli': 'రంబిల్లి',
    'Sabbavaram': 'సబ్బవరం',
    'Munagapaka': 'మునగపాక',
    'Yelamanchili': 'యెలమంచిలి',
    'Martur': 'మర్తూరు',
    'Karlapalem': 'కర్లపాలెం',
    'Parchur': 'పర్చూరు',
    'Ballikurava': 'బల్లికూరవ',
    'Santhamagulur': 'సంతమగులూరు',
    'Addanki': 'అద్దంకి',
    'Chirala': 'చీరాల',
    'Inkollu': 'ఇంకొల్లు',
    'Karamchedu': 'కరంచేడు',
    'Repalle': 'రేపల్లె',
    'Nizampatnam': 'నిజాంపత్నం',
    'Amruthalur': 'అమృతలూరు',
    'Bhattiprole': 'భట్టిప్రోలు',
    'Kolluru': 'కొల్లూరు',
    'Vemuru': 'వేమూరు',
    'Penumur': 'పెనుమూరు',
    'Gudipala': 'గుడిపాల',
    'Kanipakam': 'కానిపాకం',
    'Thavanampalle': 'తవనంపల్లె',
    'Yadamari': 'యదమరి',
    'Irala': 'ఇరాల',
    'Kallur': 'కల్లూరు',
    'Rompicherla': 'రొంపిచెర్ల',
    'Gudipalli': 'గుడిపల్లి',
    'Rallabudugur': 'రల్లబుడుగూరు',
    'Ramakuppam': 'రామకుప్పం',
    'Kuppam': 'కుప్పం',
    'Palasamudram': 'పాలసముద్రం',
    'Vedurukuppam': 'వేదురుకుప్పం',
    'Nindra': 'నింద్ర',
    'Vijayapuram': 'విజయాపురం',
    'Nagari': 'నాగరి',
    'Bangarupalem': 'బంగారుపాలెం',
    'Gangavaram': 'గంగావరం',
    'Baireddypalle': 'బైరెడ్డిపల్లె',
    'Panjani': 'పంజని',
    'Palamaner': 'పాలమనేరు',
    'Chowdepalli': 'చౌదేపల్లి',
    'Sodam': 'సోదం',
    'Somala': 'సోమాల',
    'Punganur': 'పుంగనూరు',
    'Mangalagiri': 'మంగళగిరి',
    'Pedakakani': 'పెదకాకాని',
    'Tadepalli': 'తాడేపల్లి',
    'Duggirala': 'దుగ్గిరాల',
    'Nallapadu': 'నల్లపాడు',
    'Vatticherukuru': 'వట్టిచెరుకూరు',
    'Kakumanu': 'కాకుమను',
    'Pedanandipadu': 'పెదనందిపాడు',
    'Prathipadu': 'ప్రతిపాడు',
    'Ponnur': 'పొన్నూరు',
    'Tenali': 'తెనాలి',
    'Chebrolu': 'చెబ్రోలు',
    'Kollipara': 'కొల్లిపర',
    'Medikonduru': 'మెడికొండూరు',
    'Phirangipuram': 'ఫిరంగిపురం',
    'Tadikonda': 'తాడికొండ',
    'Thulluru': 'తుల్లూరు',
    'Arundalpet': 'అరుండల్పేట',
    'Nagarampalem': 'నాగరంపాలెం',
    'Pattabhipuram': 'పట్టభిపురం',
    'Allagadda': 'అల్లగడ్డ',
    'Chagalamarri': 'చాగలమర్రి',
    'Dornipadu': 'దోర్నిపాడు',
    'Uyyalawada': 'ఉయ్యాలవాడ',
    'Koilakuntla': 'కోయిలకుంట్ల',
    'Kolimigundla': 'కోలిమిగుండ్ల',
    'Revanur': 'రేవనూరు',
    'Sanjamala': 'సంజమాల',
    'Rudravaram': 'రుద్రవరం',
    'Sirivella': 'సిరివెల్ల',
    'Nandikotkur': 'నందికోత్కూరు',
    'Atmakur': 'అత్మకూరు',
    'Kothapalli': 'కోతపల్లి',
    'Pamulapadu': 'పములపాడు',
    'Velugodu': 'వేలుగోడు',
    'Brahmanakotkur': 'బ్రహ్మనకోత్కూరు',
    'Jupadu Bangalow': 'జూపాడు బంగళో',
    'Midthur': 'మిద్దురు',
    'Muchumarri': 'ముచ్చుమర్రి',
    'Srisailam': 'శ్రీశైలం',
    'Bethamcherla': 'బేతంచెర్ల',
    'Dhone': 'ధోనే',
    'Banaganapalli': 'బనగనపల్లి',
    'Nandivargam': 'నందివర్గం',
    'Owk': 'ఓక్',
    'Jaladurgam': 'జలదుర్గం',
    'N. Racherla': 'ఎన్. రచెర్ల',
    'Peapully': 'పీపుల్లి',
    'Gospadu': 'గోస్పాడు',
    'Mahanandi': 'మహానంది',
    'Gadivemula': 'గడివేముల',
    'Panyam': 'పన్యం',
    'Chinamerangi': 'చినమేరంగి',
    'Garugubilli': 'గరుగుబిల్లి',
    'Jiyyammavalasa': 'జియ్యమ్మవలస',
    'Elwinpeta': 'ఎల్విన్పేట',
    'Kurupam': 'కురుపం',
    'Neelakantapuram': 'నీలకంతాపురం',
    'Bathili': 'బతిలి',
    'Donubhai': 'దోనుభై',
    'Palakonda': 'పాలకొండ',
    'Seethampeta': 'సీతంపేట',
    'Veeraghattam': 'వీరఘట్టం',
    'Kotiya': 'కోతియ',
    'Parvathipuram': 'పర్వతిపురం',
    'Salur': 'సాలూరు',
    'Balijipeta': 'బలిజిపేట',
    'Komarada': 'కోమరాడ',
    'Seethanagaram': 'సీతనగరం',
    'Makkuva': 'మక్కువ',
    'Pachipenta': 'పచ్చిపెంట',
  };

  // Special patterns that need special handling
  static const Map<String, String> _specialPatterns = {
    'Mahila UPS, ': 'మహిళా UPS, ',
    'CCS, ': 'CCS, ',
    'CCS UPS, ': 'CCS UPS, ',
  };

  /// Get localized district name based on current locale
  static String getDistrictName(BuildContext context, String englishName) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'te') {
      return _districtTranslations[englishName] ?? englishName;
    }
    return englishName;
  }

  /// Get localized police station name based on current locale
  static String getPoliceStationName(BuildContext context, String englishName) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode != 'te') {
      return englishName;
    }

    // Handle empty or null names
    if (englishName.isEmpty) {
      return englishName;
    }

    String translated = englishName;

    // Step 1: Handle special patterns first (e.g., "Mahila UPS, Eluru")
    for (var pattern in _specialPatterns.entries) {
      if (translated.startsWith(pattern.key)) {
        translated = translated.replaceFirst(pattern.key, pattern.value);
        // Translate the place name after the comma
        final parts = translated.split(', ');
        if (parts.length > 1) {
          parts[1] = _translatePlaceName(parts[1]);
          translated = parts.join(', ');
        }
        // Continue with suffix translation
        break;
      }
    }

    // Step 2: Translate place names (before suffixes)
    translated = _translatePlaceName(translated);

    // Step 3: Translate common suffixes (order matters - specific to general)
    // Handle numbered towns first (I Town, II Town, etc.)
    translated = translated.replaceAll('IV Town', _commonSuffixes['IV Town']!);
    translated = translated.replaceAll('III Town', _commonSuffixes['III Town']!);
    translated = translated.replaceAll('II Town', _commonSuffixes['II Town']!);
    translated = translated.replaceAll('I Town', _commonSuffixes['I Town']!);
    
    // Handle other suffixes
    for (var suffix in _commonSuffixes.entries) {
      if (suffix.key != 'I Town' && 
          suffix.key != 'II Town' && 
          suffix.key != 'III Town' && 
          suffix.key != 'IV Town') {
        translated = translated.replaceAll(suffix.key, suffix.value);
      }
    }

    return translated;
  }

  /// Helper method to translate place names
  static String _translatePlaceName(String text) {
    String result = text;
    
    // Sort place names by length (longest first) to avoid partial matches
    final sortedPlaceNames = _placeNameTranslations.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    
    for (var entry in sortedPlaceNames) {
      // Use word boundaries to avoid partial matches
      // Replace only if it's a complete word or at the start/end
      final pattern = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(result)) {
        result = result.replaceAllMapped(pattern, (match) => entry.value);
      }
    }
    
    return result;
  }

  /// Get all districts with localized names
  static List<String> getDistricts(BuildContext context) {
    final districts = _districtTranslations.keys.toList()..sort();
    return districts.map((district) => getDistrictName(context, district)).toList();
  }

  /// Get English district name from localized name
  static String? getEnglishDistrictName(String localizedName, BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'te') {
      for (var entry in _districtTranslations.entries) {
        if (entry.value == localizedName) {
          return entry.key;
        }
      }
    }
    return localizedName;
  }

  /// Load police stations for a district and return localized names
  static Future<Map<String, List<String>>> loadPoliceStations(BuildContext context) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final Map<String, List<String>> localizedData = {};
      
      for (var entry in jsonData.entries) {
        final districtName = entry.key;
        final policeStations = (entry.value as List).cast<String>();
        
        final localizedDistrict = getDistrictName(context, districtName);
        final localizedStations = policeStations.map((station) => 
          getPoliceStationName(context, station)
        ).toList();
        
        localizedData[localizedDistrict] = localizedStations;
      }
      
      return localizedData;
    } catch (e) {
      debugPrint('Error loading police stations: $e');
      return {};
    }
  }

  /// Get police stations for a specific district (returns English names for storage)
  static Future<List<String>> getPoliceStationsForDistrict(
    BuildContext context,
    String districtName,
  ) async {
    // Convert localized district name back to English if needed
    final englishDistrictName = getEnglishDistrictName(districtName, context) ?? districtName;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      if (jsonData.containsKey(englishDistrictName)) {
        final policeStations = (jsonData[englishDistrictName] as List).cast<String>();
        // Return English names for storage
        return policeStations;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error loading police stations for district: $e');
      return [];
    }
  }

  /// Get localized police station name for display
  static String getLocalizedPoliceStationName(BuildContext context, String englishName) {
    return getPoliceStationName(context, englishName);
  }

  /// Get English police station name from localized name (reverse lookup)
  static String? getEnglishPoliceStationName(String localizedName, BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode != 'te') {
      return localizedName; // Already English
    }
    
    // Try to reverse translate common patterns
    String english = localizedName;
    
    // Reverse translate special patterns first
    for (var pattern in _specialPatterns.entries) {
      if (english.contains(pattern.value)) {
        english = english.replaceAll(pattern.value, pattern.key);
      }
    }
    
    // Reverse translate place names (sort by length, longest first)
    final sortedPlaceNames = _placeNameTranslations.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    for (var entry in sortedPlaceNames) {
      if (english.contains(entry.value)) {
        english = english.replaceAll(entry.value, entry.key);
      }
    }
    
    // Reverse translate suffixes (order matters)
    english = english.replaceAll('IV టౌన్', 'IV Town');
    english = english.replaceAll('III టౌన్', 'III Town');
    english = english.replaceAll('II టౌన్', 'II Town');
    english = english.replaceAll('I టౌన్', 'I Town');
    
    // Reverse translate other suffixes
    for (var suffix in _commonSuffixes.entries) {
      if (suffix.key != 'I Town' && 
          suffix.key != 'II Town' && 
          suffix.key != 'III Town' && 
          suffix.key != 'IV Town') {
        english = english.replaceAll(suffix.value, suffix.key);
      }
    }
    
    return english;
  }

  /// Get localized sub-division name
  static String getSubDivisionName(BuildContext context, String englishName) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'te') {
      // Translate place names in sub-division using the comprehensive map
      String translated = _translatePlaceName(englishName);
      // SDPO suffix stays as is (already in English acronym form)
      return translated;
    }
    return englishName;
  }

  /// Get localized circle name
  static String getCircleName(BuildContext context, String englishName) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'te') {
      if (englishName == '-') return '-';
      // Translate "Circle 1", "Circle 2", etc.
      String translated = englishName;
      translated = translated.replaceAll('Circle', 'సర్కిల్');
      return translated;
    }
    return englishName;
  }
}

