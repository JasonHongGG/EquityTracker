import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool isPrivacyModeEnabled;

  const SettingsState({
    required this.themeMode,
    required this.isPrivacyModeEnabled,
  });

  SettingsState copyWith({ThemeMode? themeMode, bool? isPrivacyModeEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isPrivacyModeEnabled: isPrivacyModeEnabled ?? this.isPrivacyModeEnabled,
    );
  }
}
