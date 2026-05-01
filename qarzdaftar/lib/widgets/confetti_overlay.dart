import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConfettiOverlay {
  ConfettiOverlay._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, {Duration duration = const Duration(seconds: 2)}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _entry?.remove();
    final controller = ConfettiController(duration: duration);

    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: SizedBox.expand(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: controller,
                  blastDirection: math.pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  emissionFrequency: 0.05,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: const [
                    AppTheme.success,
                    AppTheme.warning,
                    AppTheme.primary,
                    Color(0xFFEC4899),
                    Color(0xFF14B8A6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    controller.play();

    Future.delayed(duration + const Duration(milliseconds: 1000), () {
      controller.dispose();
      entry.remove();
      if (_entry == entry) _entry = null;
    });
  }
}
