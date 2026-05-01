import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum AppSnackKind { info, success, warning, error }

class AppSnack {
  static void show(
    BuildContext context,
    String message, {
    AppSnackKind kind = AppSnackKind.info,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();

    final (bg, fg, icon) = switch (kind) {
      AppSnackKind.success => (
          AppTheme.success,
          Colors.white,
          Icons.check_circle_outline,
        ),
      AppSnackKind.warning => (
          AppTheme.warning,
          Colors.white,
          Icons.warning_amber_outlined,
        ),
      AppSnackKind.error => (
          AppTheme.danger,
          Colors.white,
          Icons.error_outline,
        ),
      AppSnackKind.info => (
          AppTheme.textPrimary,
          Colors.white,
          Icons.info_outline,
        ),
    };

    if (kind == AppSnackKind.success) {
      HapticFeedback.lightImpact();
    } else if (kind == AppSnackKind.error) {
      HapticFeedback.heavyImpact();
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        action: action,
        content: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message, kind: AppSnackKind.success, action: action);

  static void error(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message, kind: AppSnackKind.error, action: action);

  static void warning(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message, kind: AppSnackKind.warning, action: action);

  static void info(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message, kind: AppSnackKind.info, action: action);
}
