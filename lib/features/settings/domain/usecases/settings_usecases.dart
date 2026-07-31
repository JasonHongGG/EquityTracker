import 'package:flutter/material.dart';
import 'package:equity_tracker/features/settings/domain/repositories/i_settings_repository.dart';

class GetThemeUseCase {
  final ISettingsRepository repository;
  GetThemeUseCase(this.repository);

  Future<ThemeMode> execute() => repository.getThemeMode();
}

class SetThemeUseCase {
  final ISettingsRepository repository;
  SetThemeUseCase(this.repository);

  Future<void> execute(ThemeMode mode) => repository.setThemeMode(mode);
}

class GetPrivacyModeUseCase {
  final ISettingsRepository repository;
  GetPrivacyModeUseCase(this.repository);

  Future<bool> execute() => repository.getPrivacyMode();
}

class SetPrivacyModeUseCase {
  final ISettingsRepository repository;
  SetPrivacyModeUseCase(this.repository);

  Future<void> execute(bool enabled) => repository.setPrivacyMode(enabled);
}
