import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AvatarStatus { none, clean, debt, overdue }

class CustomerAvatar extends StatefulWidget {
  const CustomerAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.size = 44,
    this.status = AvatarStatus.none,
    this.heroTag,
  });

  final String name;
  final String? photoPath;
  final double size;
  final AvatarStatus status;
  final Object? heroTag;

  @override
  State<CustomerAvatar> createState() => _CustomerAvatarState();
}

class _CustomerAvatarState extends State<CustomerAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.status == AvatarStatus.overdue) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CustomerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == AvatarStatus.overdue && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (widget.status != AvatarStatus.overdue && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color? _ringColor() {
    switch (widget.status) {
      case AvatarStatus.clean:
        return AppTheme.success;
      case AvatarStatus.debt:
        return AppTheme.warning;
      case AvatarStatus.overdue:
        return AppTheme.danger;
      case AvatarStatus.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _ringColor();
    final size = widget.size;
    final inner = _avatarInner(size);
    final widget1 = widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: inner)
        : inner;

    if (ringColor == null) {
      return widget1;
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final pulse = widget.status == AvatarStatus.overdue
            ? 1.0 + (_ctrl.value * 0.06)
            : 1.0;
        final glowOpacity = widget.status == AvatarStatus.overdue
            ? 0.3 + (_ctrl.value * 0.4)
            : 0.0;
        return SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.status == AvatarStatus.overdue)
                Container(
                  width: (size + 8) * pulse,
                  height: (size + 8) * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withValues(alpha: glowOpacity * 0.25),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2.5),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: widget1,
    );
  }

  Widget _avatarInner(double size) {
    if (widget.photoPath != null) {
      final file = File(widget.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: FileImage(file),
        );
      }
    }
    final color = AppTheme.avatarColorFor(widget.name);
    final initial =
        widget.name.isEmpty ? '?' : widget.name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

extension AvatarStatusFromBalance on AvatarStatus {
  static AvatarStatus from({
    required double remaining,
    required double totalDebt,
    required bool hasOverdue,
  }) {
    if (hasOverdue) return AvatarStatus.overdue;
    if (remaining > 0) return AvatarStatus.debt;
    if (totalDebt > 0 && remaining <= 0) return AvatarStatus.clean;
    return AvatarStatus.none;
  }
}
