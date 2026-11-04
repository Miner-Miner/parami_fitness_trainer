import 'dart:async';

import 'package:flutter/material.dart';

class BrandHeader extends StatefulWidget {
  const BrandHeader({super.key, this.logoWidth = 160});

  final double logoWidth;

  @override
  State<BrandHeader> createState() => _BrandHeaderState();
}

class _BrandHeaderState extends State<BrandHeader> {
  DateTime _now = DateTime.now();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (now.year != _now.year ||
          now.month != _now.month ||
          now.day != _now.day ||
          now.hour != _now.hour ||
          now.minute != _now.minute) {
        setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String pad(int value) => value.toString().padLeft(2, '0');
    final timestamp =
        '${pad(_now.hour)}:${pad(_now.minute)} '
        '${days[_now.weekday - 1]} ${pad(_now.day)} ${pad(_now.month)}';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timestamp,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 4),
          // Hide the source image's transparent vertical margins.
          ClipRect(
            child: Align(
              heightFactor: 0.4,
              child: Image.asset(
                'assets/branding/parami_fitness_logo-removebg.png',
                width: widget.logoWidth,
                height: widget.logoWidth,
                fit: BoxFit.contain,
                semanticLabel: 'Parami Fitness',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
