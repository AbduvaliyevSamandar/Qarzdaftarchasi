import 'package:flutter/material.dart';

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required Widget page})
      : super(
          pageBuilder: (_, animation, __) => page,
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
