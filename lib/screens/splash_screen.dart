import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// WZH-style minimal splash: just the gold AX logo + name, clean fade,
/// one subtle loading row — no glow, no tagline. Hands off to Login
/// (~1500ms). Lightweight: scale/alpha GPU transforms only, no gateway
/// work here (the login screen handles the gateway).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _dotsCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _logoFade;
  late final Animation<double> _nameFade;
  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    // Name fades in ~150ms after the logo starts.
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _ctrl.forward();
    _handoff = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _handoff?.cancel();
    _ctrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: Opacity(opacity: _logoFade.value, child: child),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/ayx-logo.png',
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _nameFade,
              child: const Text(
                'WhatsAyX',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _dotsCtrl,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) _Dot(
                      progress: _dotProgress(i),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Each dot pulses over 600ms, staggered 150ms after the previous.
  double _dotProgress(int i) {
    final start = i * 0.15;
    final t = (_dotsCtrl.value - start) / 0.6;
    if (t <= 0 || t >= 1) return 0;
    return Curves.easeInOut.transform(t);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = 0.25 + 0.75 * progress;
    final size = 7 + 3 * progress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
