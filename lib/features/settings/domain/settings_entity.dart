import 'package:flutter/material.dart';

class SettingsEntity {
  final ThemeMode themeMode;
  final bool useBiometrics;

  const SettingsEntity({
    this.themeMode = ThemeMode.system,
    this.useBiometrics = false,
  });

  SettingsEntity copyWith({
    ThemeMode? themeMode,
    bool? useBiometrics,
  }) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      useBiometrics: useBiometrics ?? this.useBiometrics,
    );
  }
}
