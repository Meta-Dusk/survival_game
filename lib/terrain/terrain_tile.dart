import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/obstacles/obstacle.dart';

enum TileType { grass, sand, cliff, water }

const Set obstacleTiles = {TileType.cliff, TileType.water};

class TerrainTile extends BodyComponent<SurvivalGame> with ObstacleType {
  final Sprite sprite;
  final Sprite? bgSprite;
  final TileType type;
  final List<Rect>? customHitboxes;
  final Vector2 initialPosition;
  final Vector2 tileDimension;
  final int? customPriority;
  late SpriteComponent visual;
  final double elevation;
  final int stackCount;

  TerrainTile({
    required this.sprite,
    this.bgSprite,
    required this.type,
    this.customHitboxes,
    this.customPriority,
    this.stackCount = 1,
    required this.initialPosition,
    required this.tileDimension,
    required this.elevation,
  });

  void setPriority() {
    if (customPriority != null) {
      priority = customPriority!;
      return;
    }
    switch (type) {
      case TileType.water:
        priority = -3000000;
      case TileType.sand:
        priority = -2000000;
      case TileType.grass:
        priority = -1000000;
      default:
        priority = (initialPosition.y + tileDimension.y).toInt();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    setPriority();

    if (bgSprite != null) {
      final bgVisual = SpriteComponent(
        sprite: bgSprite,
        size: tileDimension,
        paint: Paint()..isAntiAlias = false,
      );
      add(bgVisual);
    }

    for (int i = 0; i < stackCount; i++) {
      final layerVisual = SpriteComponent(
        sprite: sprite,
        size: tileDimension,
        position: Vector2(0, -i * tileDimension.y),
        paint: Paint()
          ..isAntiAlias = false
          ..color = Colors.white.withValues(alpha: renderBody ? 0.5 : 1.0),
      );
      add(layerVisual);
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: initialPosition, type: BodyType.static);
    final body = world.createBody(bodyDef);
    body.userData = this;

    final boxesToCreate = <Rect>[];
    if (customHitboxes == null) {
      boxesToCreate.add(Rect.fromLTWH(0, 0, tileDimension.x, tileDimension.y));
    } else {
      boxesToCreate.addAll(customHitboxes!);
    }

    for (var rect in boxesToCreate) {
      final shape = PolygonShape();
      final hx = rect.width / 2;
      final hy = rect.height / 2;
      final center = Vector2(rect.left + hx, rect.top + hy);
      shape.setAsBox(hx, hy, center, 0);

      final fixtureDef = FixtureDef(shape, friction: 0.0);
      if (type == TileType.water) fixtureDef.isSensor = true;
      body.createFixture(fixtureDef);
    }

    return body;
  }
}
