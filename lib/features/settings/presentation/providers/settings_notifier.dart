import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/core/providers/repository_providers.dart';










class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final getTheme = ref.read(getThemeUseCaseProvider);
    final getPrivacy = ref.read(getPrivacyModeUseCaseProvider);

    final themeMode = await getTheme.execute();
    final isPrivacyModeEnabled = await getPrivacy.execute();

    return SettingsState(
      themeMode: themeMode,
      isPrivacyModeEnabled: isPrivacyModeEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(setThemeUseCaseProvider).execute(mode);
    state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
  }

  Future<void> setPrivacyMode(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setPrivacyMode(enabled);
    state = AsyncValue.data(
      state.value!.copyWith(isPrivacyModeEnabled: enabled),
    );
  }
}

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

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
