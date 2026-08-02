import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/core/providers/repository_providers.dart';










class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final repo = ref.read(settingsRepositoryProvider);

    final themeMode = await repo.getThemeMode();
    final isPrivacyModeEnabled = await repo.getPrivacyMode();
    final currencySymbol = await repo.getCurrencySymbol();

    return SettingsState(
      themeMode: themeMode,
      isPrivacyModeEnabled: isPrivacyModeEnabled,
      currencySymbol: currencySymbol,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
    state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
  }

  Future<void> setPrivacyMode(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setPrivacyMode(enabled);
    state = AsyncValue.data(
      state.value!.copyWith(isPrivacyModeEnabled: enabled),
    );
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await ref.read(settingsRepositoryProvider).setCurrencySymbol(symbol);
    state = AsyncValue.data(
      state.value!.copyWith(currencySymbol: symbol),
    );
  }
}

class SettingsState {
  final ThemeMode themeMode;
  final bool isPrivacyModeEnabled;
  final String currencySymbol;

  const SettingsState({
    required this.themeMode,
    required this.isPrivacyModeEnabled,
    required this.currencySymbol,
  });

  SettingsState copyWith({
    ThemeMode? themeMode, 
    bool? isPrivacyModeEnabled,
    String? currencySymbol,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isPrivacyModeEnabled: isPrivacyModeEnabled ?? this.isPrivacyModeEnabled,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
