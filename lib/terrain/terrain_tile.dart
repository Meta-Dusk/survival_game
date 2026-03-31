import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/obstacles/obstacle.dart';

enum TileType { grass, cliff, water }

const Set obstacleTiles = {TileType.cliff, TileType.water};

class TerrainTile extends PositionComponent with ObstacleType {
  final Sprite sprite;
  final TileType type;
  final List<RectangleHitbox>? customHitboxes;
  final Vector2? visualOffset;

  TerrainTile({
    required this.sprite,
    required this.type,
    this.customHitboxes,
    this.visualOffset,
    required super.position,
    required super.size,
  });

  @override
  Future<void> onLoad() async {
    if (obstacleTiles.contains(type)) {
      if (customHitboxes != null) {
        for (var hitbox in customHitboxes!) {
          hitbox.position += Vector2.all(0.05);
          hitbox.size -= Vector2.all(0.1);
          hitbox.collisionType = CollisionType.passive;
          add(hitbox);
        }
      } else {
        add(
          RectangleHitbox(
            position: Vector2.all(0.05),
            size: size - Vector2.all(0.1),
            collisionType: CollisionType.passive,
          ),
        );
      }
    }
    priority = 0;
  }

  @override
  void render(Canvas canvas) {
    sprite.render(
      canvas,
      size: size,
      position: visualOffset ?? Vector2.zero(),
      // bleed: 1,
      overridePaint: Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none,
    );
    // canvas.drawRect(
    //   size.toRect(),
    //   Paint()
    //     ..color = Colors.red.withValues(alpha: 0.25)
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 1.0,
    // );
  }
}
