import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _themeKey = 'theme_mode';
  static const String _privacyKey = 'privacy_mode';
  static const String _currencyKey = 'currency_symbol';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex == null) return ThemeMode.system;
    return ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<bool> getPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyKey) ?? false;
  }

  Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, enabled);
  }

  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? '\$';
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }
}
