import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Smooth splash (original-app style): gold AX logo springs in over a
/// soft pulsing radial glow, the name fades in staggered behind it,
/// three dots pulse below — then hands off to Login (~1900ms).
/// Lightweight: scale/alpha GPU transforms only, no gateway work here
/// (the login screen handles the gateway).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _dotsCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _logoFade;
  late final Animation<double> _nameFade;
  late final Animation<double> _tagFade;
  late final Animation<double> _glow;
  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.64, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    // Name fades in ~180ms after the logo starts.
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.16, 0.62, curve: Curves.easeOut),
      ),
    );
    _tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.30, end: 0.85).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _ctrl.forward();
    _handoff = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _handoff?.cancel();
    _ctrl.dispose();
    _glowCtrl.dispose();
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
              animation: Listenable.merge([_ctrl, _glowCtrl]),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _glow.value,
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.35),
                              const Color(0xFFFFC24D).withOpacity(0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _scale.value,
                      child: Opacity(opacity: _logoFade.value, child: child),
                    ),
                  ],
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/ayx-logo.png',
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _nameFade,
              child: const Text(
                'WhatsAyX',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _tagFade,
              child: const Text(
                'WhatsApp, clean and simple.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ),
            const SizedBox(height: 48),
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
