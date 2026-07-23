import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('en');
  
  static const String _prefKey = 'app_language';
  static Map<String, dynamic> _localizedStrings = {};
  static Map<String, dynamic> _fallbackStrings = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefKey) ?? 'en';
    localeNotifier.value = savedLang;
    
    // Load english as fallback
    try {
      String jsonString = await rootBundle.loadString('assets/i18n/en.json');
      _fallbackStrings = json.decode(jsonString);
    } catch (e) {
      debugPrint("Could not load fallback en.json");
    }

    await _loadLang(savedLang);
  }

  static Future<void> _loadLang(String langCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/i18n/$langCode.json');
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      debugPrint("Could not load $langCode.json");
      _localizedStrings = {};
    }
  }

  static Future<void> changeLanguage(String langCode) async {
    await _loadLang(langCode);
    localeNotifier.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
  }

  static String tr(String key) {
    if (_localizedStrings.containsKey(key)) {
      return _localizedStrings[key].toString();
    }
    if (_fallbackStrings.containsKey(key)) {
      return _fallbackStrings[key].toString();
    }
    return key;
  }

  static Map<String, String> get languageNames {
    return {
      'en': 'English',
      'hi': 'Hindi (हिन्दी)',
      'te': 'Telugu (తెలుగు)',
      'ta': 'Tamil (தமிழ்)',
      'kn': 'Kannada (ಕನ್ನಡ)',
      'ml': 'Malayalam (മലയാളം)',
      'bn': 'Bengali (বাংলা)',
      'mr': 'Marathi (मराठी)',
      'gu': 'Gujarati (ગુજરાતી)',
      'pa': 'Punjabi (ਪੰਜਾਬੀ)',
      'or': 'Odia (ଓଡ଼ିଆ)',
    };
  }
}
