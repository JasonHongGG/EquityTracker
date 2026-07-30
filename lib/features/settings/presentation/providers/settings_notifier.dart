import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:equity_tracker/features/settings/presentation/states/settings_state.dart';

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

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
