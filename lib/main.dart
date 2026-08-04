import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/theme/app_theme.dart';
import 'package:equity_tracker/core/router/app_router.dart';
import 'package:equity_tracker/core/widgets/global_notification_overlay.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final themeMode = settingsAsync.value?.themeMode ?? ThemeMode.system;
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'EquityTracker',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlobalNotificationOverlay(
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
