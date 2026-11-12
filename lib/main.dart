import 'package:flutter/material.dart';

import 'models/settings.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WhatsAyxApp());
}

/// App root — rebuilds MaterialApp whenever settings change, so the
/// theme mode (system/light/amoled) and accent color apply instantly
/// across the whole app instead of being hardcoded dark/teal.
class WhatsAyxApp extends StatefulWidget {
  const WhatsAyxApp({super.key});

  @override
  State<WhatsAyxApp> createState() => _WhatsAyxAppState();
}

class _WhatsAyxAppState extends State<WhatsAyxApp> {
  final SettingsStore _store = SettingsStore.shared;
  AyxSettings _settings = const AyxSettings();

  @override
  void initState() {
    super.initState();
    _store.addListener((s) {
      if (mounted) setState(() => _settings = s);
    });
    _store.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  int _accentValue(String key) {
    for (final a in AyxOptions.accents) {
      if (a.key == key) return a.value;
    }
    return 0xFF4DD0C4; // teal default
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.dark(
      accent: _accentValue(_settings.accent),
      mode: _settings.themeMode,
    );
    return MaterialApp(
      title: 'WhatsAyX',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: _settings.themeMode == 'light'
          ? ThemeMode.light
          : ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Smooth page transitions everywhere.
        Widget page;
        switch (settings.name) {
          case '/login':
            page = LoginScreen(api: ApiService());
            break;
          case '/home':
            page = const HomeScreen();
            break;
          case '/':
          default:
            page = const SplashScreen();
        }
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, _, __) => page,
          transitionsBuilder: (context, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    );
  }
}
