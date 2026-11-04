import 'dart:async';

import 'package:flutter/material.dart';

import 'core/session_store.dart';
import 'widgets/brand_header.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionStore,
      builder: (context, _) => MaterialApp(
        title: 'Parami Trainer',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(sessionStore.theme),
        darkTheme: buildAppTheme(sessionStore.theme, dark: true),
        themeMode: sessionStore.isDark ? ThemeMode.dark : ThemeMode.light,
        home: AppEntry(sessionStore: sessionStore),
      ),
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
    _timer = Timer(Duration(milliseconds: 1500), () {
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
            ? SplashScreen()
            : widget.sessionStore.session == null
            ? LoginScreen(sessionStore: widget.sessionStore)
            : HomeShell(sessionStore: widget.sessionStore);
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 350),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.of(context).ink,
              AppPalette.of(context).navy,
              AppPalette.of(context).navyBright,
            ],
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
                  const BrandHeader(logoWidth: 240),
                  SizedBox(height: 8),
                  // Text(
                  //   'TRAINER CONSOLE',
                  //   style: TextStyle(
                  //     color: Colors.white.withValues(alpha: 0.72),
                  //     fontWeight: FontWeight.w700,
                  //     fontSize: 12,
                  //     letterSpacing: 2.4,
                  //   ),
                  // ),
                ],
              ),
            ),
            Positioned(
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
