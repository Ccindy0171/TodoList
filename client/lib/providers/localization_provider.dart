import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider with ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  
  // Supported locales
  static const Locale enLocale = Locale('en', '');
  static const Locale zhLocale = Locale('zh', 'CN');
  
  Locale _locale = enLocale;
  
  LocalizationProvider() {
    _loadLocale();
  }
  
  Locale get locale => _locale;
  
  bool get isEnglish => _locale.languageCode == 'en';
  
  List<Locale> get supportedLocales => [enLocale, zhLocale];
  
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'en';
    final countryCode = languageCode == 'zh' ? 'CN' : '';
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }
  
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
  
  Future<void> toggleLocale() async {
    if (isEnglish) {
      await setLocale(zhLocale);
    } else {
      await setLocale(enLocale);
    }
  }
} 