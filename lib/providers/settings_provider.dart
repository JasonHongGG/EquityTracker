import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeIndex = prefs.getInt('themeMode');
    final themeMode = themeIndex == null
        ? ThemeMode.system
        : ThemeMode.values[themeIndex];

    // Load Privacy Mode
    final isPrivacyModeEnabled = prefs.getBool('isPrivacyModeEnabled') ?? false;

    return SettingsState(
      themeMode: themeMode,
      isPrivacyModeEnabled: isPrivacyModeEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    // Update state
    state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
  }

  Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPrivacyModeEnabled', enabled);
    // Update state
    state = AsyncValue.data(
      state.value!.copyWith(isPrivacyModeEnabled: enabled),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
