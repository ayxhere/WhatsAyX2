import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WhatsAyxApp());
}

class WhatsAyxApp extends StatelessWidget {
  const WhatsAyxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsAyX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
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
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, animation, _, child) {
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
