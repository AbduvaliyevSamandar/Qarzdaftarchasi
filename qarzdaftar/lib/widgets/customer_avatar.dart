import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.size = 44,
  });

  final String name;
  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: FileImage(file),
        );
      }
    }
    final color = AppTheme.avatarColorFor(name);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
