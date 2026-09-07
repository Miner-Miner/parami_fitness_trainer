import 'dart:async';

import 'package:flutter/material.dart';

import 'core/session_store.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class AppPalette {
  static const ink = Color(0xFF03080F);
  static const navy = Color(0xFF071A33);
  static const navyBright = Color(0xFF123C69);
  static const steel = Color(0xFF9AB2CD);
  static const mist = Color(0xFFF4F7FB);
  static const line = Color(0xFFD7E0EA);
  static const success = Color(0xFF2EAE7A);
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parami Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.mist,
        colorScheme: const ColorScheme.light(
          primary: AppPalette.navy,
          onPrimary: Colors.white,
          secondary: AppPalette.navyBright,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: AppPalette.ink,
          outline: AppPalette.line,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: AppPalette.navy,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineSmall: TextStyle(
            color: AppPalette.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
          titleLarge: TextStyle(
            color: AppPalette.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            color: AppPalette.navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF52657A),
            fontSize: 14,
            height: 1.45,
          ),
          labelLarge: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.navy, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppPalette.navy,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: AppEntry(sessionStore: sessionStore),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  var _showSplash = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionStore,
      builder: (context, _) {
        final child = _showSplash
            ? const SplashScreen()
            : widget.sessionStore.session == null
            ? LoginScreen(sessionStore: widget.sessionStore)
            : HomeShell(sessionStore: widget.sessionStore);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: child,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.ink, AppPalette.navy, AppPalette.navyBright],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -92,
              top: 72,
              child: _Glow(
                size: 244,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: -100,
              bottom: -72,
              child: _Glow(
                size: 280,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 43,
                      color: AppPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'PARAMI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 29,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TRAINER CONSOLE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 54,
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
