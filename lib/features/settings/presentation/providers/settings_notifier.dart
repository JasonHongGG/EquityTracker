import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/presentation/states/settings_state.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/settings/domain/usecases/settings_usecases.dart';

final getThemeUseCaseProvider = Provider<GetThemeUseCase>((ref) {
  return GetThemeUseCase(ref.read(settingsRepositoryProvider));
});

final setThemeUseCaseProvider = Provider<SetThemeUseCase>((ref) {
  return SetThemeUseCase(ref.read(settingsRepositoryProvider));
});

final getPrivacyModeUseCaseProvider = Provider<GetPrivacyModeUseCase>((ref) {
  return GetPrivacyModeUseCase(ref.read(settingsRepositoryProvider));
});

final setPrivacyModeUseCaseProvider = Provider<SetPrivacyModeUseCase>((ref) {
  return SetPrivacyModeUseCase(ref.read(settingsRepositoryProvider));
});

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
    await ref.read(setPrivacyModeUseCaseProvider).execute(enabled);
    state = AsyncValue.data(
      state.value!.copyWith(isPrivacyModeEnabled: enabled),
    );
  }
}

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
