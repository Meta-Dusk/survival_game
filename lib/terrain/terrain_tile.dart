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
  final int? customPriority;

  TerrainTile({
    required this.sprite,
    required this.type,
    this.customHitboxes,
    this.visualOffset,
    this.customPriority,
    required super.position,
    required super.size,
  });

  @override
  Future<void> onLoad() async {
    if (customPriority != null) {
      priority = customPriority!;
    } else if (type != TileType.cliff) {
      priority = -999999;
    } else {
      priority = (position.y + size.y).toInt();
    }

    if (customHitboxes == null) {
      add(
        RectangleHitbox(
            position: Vector2.zero(),
            size: size,
            collisionType: CollisionType.passive,
          )
          ..debugMode = true
          ..debugCoordinatesPrecision = null,
      );
      return;
    }

    if (customHitboxes!.isEmpty) return;

    for (var hitbox in customHitboxes!) {
      add(
        hitbox
          ..collisionType = CollisionType.passive
          ..debugMode = true
          ..debugCoordinatesPrecision = null,
      );
    }
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
