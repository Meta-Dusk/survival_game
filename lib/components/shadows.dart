import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PixelShadow extends PositionComponent {
  PixelShadow({super.position}) {
    size = Vector2(12, 6);
    anchor = Anchor.bottomCenter;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.1);

    canvas.drawRect(const Rect.fromLTWH(2, 0, 8, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(1, 1, 10, 3), paint);
    canvas.drawRect(const Rect.fromLTWH(0, 2, 12, 1), paint);
  }
}
