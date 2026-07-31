import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/features/settings/domain/repositories/i_settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  static const String _keyThemeMode = 'themeMode';
  static const String _keyPrivacyMode = 'isPrivacyModeEnabled';

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    return themeIndex == null ? ThemeMode.system : ThemeMode.values[themeIndex];
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  @override
  Future<bool> getPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPrivacyMode) ?? false;
  }

  @override
  Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacyMode, enabled);
  }
}
