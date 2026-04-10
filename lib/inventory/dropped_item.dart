import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/inventory/item_registry.dart';

class DroppedItem extends BodyComponent<SurvivalGame> {
  final ItemType itemType;
  final int count;
  final Vector2 initialPosition;
  late ItemData data;
  late SpriteComponent visual;
  final bool scatterOnSpawn;

  DroppedItem({
    required this.itemType,
    this.count = 1,
    required this.initialPosition,
    this.scatterOnSpawn = false,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    data = ItemRegistry.get(itemType);
    final itemSprite = game.spriteSheet.getSprite(data.sheetY, data.sheetX);

    visual = SpriteComponent(
      sprite: itemSprite,
      size: .all(16),
      anchor: .center,
    );
    add(visual);

    final itemEffect = ScaleEffect.to(
      .all(1.0),
      EffectController(duration: 0.3, curve: Curves.easeOutBack),
      onComplete: () {
        final bobbingEffect = MoveByEffect(
          Vector2(0, -2),
          EffectController(
            duration: 1.0,
            alternate: true,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        );
        visual.add(bobbingEffect);
      },
    );
    visual.scale = .zero();
    visual.add(itemEffect);
  }

  void applyRandomVelocity(Body body) {
    final randomAngle = Random().nextDouble() * 2 * pi;
    final randomSpeed = Random().nextDouble() * 40.0 + 20.0;
    body.linearVelocity = Vector2(
      cos(randomAngle) * randomSpeed,
      sin(randomAngle) * randomSpeed,
    );
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: initialPosition,
      type: .dynamic,
      linearDamping: 5.0,
    );
    final body = world.createBody(bodyDef);
    body.userData = this;

    final shape = CircleShape()..radius = 4.0;
    final fixtureDef = FixtureDef(shape, friction: 0.0, density: 1.0);
    body.createFixture(fixtureDef);

    if (scatterOnSpawn) applyRandomVelocity(body);
    return body;
  }

  @override
  void update(double dt) {
    priority = (body.position.y + visual.size.y + 16).toInt();
  }
}
