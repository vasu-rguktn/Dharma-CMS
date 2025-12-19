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

  static const Map<String, String> _policeStationTranslations = {
    // Common suffixes
    'Town': 'టౌన్',
    'Rural': 'రూరల్',
    'Traffic': 'ట్రాఫిక్',
    'I Town': 'I టౌన్',
    'II Town': 'II టౌన్',
    'III Town': 'III టౌన్',
    'IV Town': 'IV టౌన్',
    'Traffic PS': 'ట్రాఫిక్ PS',
    
    // Common police station names
    'Mahila UPS': 'మహిళా UPS',
    'Taluk': 'తాలూకా',
    
    // Specific translations for common names
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
    if (locale.languageCode == 'te') {
      // Try exact match first
      if (_policeStationTranslations.containsKey(englishName)) {
        return _policeStationTranslations[englishName]!;
      }
      
      // Try to translate common suffixes
      String translated = englishName;
      translated = translated.replaceAll(' Town', ' టౌన్');
      translated = translated.replaceAll(' Rural', ' రూరల్');
      translated = translated.replaceAll(' Traffic', ' ట్రాఫిక్');
      translated = translated.replaceAll('I Town', 'I టౌన్');
      translated = translated.replaceAll('II Town', 'II టౌన్');
      translated = translated.replaceAll('III Town', 'III టౌన్');
      translated = translated.replaceAll('IV Town', 'IV టౌన్');
      translated = translated.replaceAll(' Traffic PS', ' ట్రాఫిక్ PS');
      translated = translated.replaceAll('Mahila UPS', 'మహిళా UPS');
      translated = translated.replaceAll(' Taluk', ' తాలూకా');
      
      // Translate common place names
      for (var entry in _policeStationTranslations.entries) {
        if (englishName.contains(entry.key) && entry.key.length > 3) {
          translated = translated.replaceAll(entry.key, entry.value);
        }
      }
      
      return translated;
    }
    return englishName;
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
      final String jsonString = await rootBundle.loadString('assets/Data/district_police_stations.json');
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
      final String jsonString = await rootBundle.loadString('assets/Data/district_police_stations.json');
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
    // This is a simplified approach - for production, maintain a reverse map
    String english = localizedName;
    english = english.replaceAll(' టౌన్', ' Town');
    english = english.replaceAll(' రూరల్', ' Rural');
    english = english.replaceAll(' ట్రాఫిక్', ' Traffic');
    english = english.replaceAll('I టౌన్', 'I Town');
    english = english.replaceAll('II టౌన్', 'II Town');
    english = english.replaceAll('III టౌన్', 'III Town');
    english = english.replaceAll('IV టౌన్', 'IV Town');
    english = english.replaceAll(' ట్రాఫిక్ PS', ' Traffic PS');
    english = english.replaceAll('మహిళా UPS', 'Mahila UPS');
    english = english.replaceAll(' తాలూకా', ' Taluk');
    
    // Reverse translate common place names
    for (var entry in _policeStationTranslations.entries) {
      if (localizedName.contains(entry.value) && entry.key.length > 3) {
        english = english.replaceAll(entry.value, entry.key);
      }
    }
    
    return english;
  }
}

