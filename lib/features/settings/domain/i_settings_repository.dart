import 'package:flutter/material.dart';

abstract class ISettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  
  Future<bool> getPrivacyMode();
  Future<void> setPrivacyMode(bool enabled);
}
