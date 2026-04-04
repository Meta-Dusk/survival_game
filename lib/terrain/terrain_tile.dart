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
  final TileType type;
  final List<Rect>? customHitboxes;
  final Vector2 initialPosition;
  final Vector2 tileDimension;
  final int? customPriority;
  late SpriteComponent visual;

  TerrainTile({
    required this.sprite,
    required this.type,
    this.customHitboxes,
    this.customPriority,
    required this.initialPosition,
    required this.tileDimension,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    if (customPriority != null) {
      priority = customPriority!;
    } else if (type != TileType.cliff) {
      priority = -99999;
    } else {
      priority = (initialPosition.y + tileDimension.y).toInt();
    }

    visual = SpriteComponent(
      sprite: sprite,
      size: tileDimension,
      paint: Paint()..isAntiAlias = false,
    );
    add(visual);
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
