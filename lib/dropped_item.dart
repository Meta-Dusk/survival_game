import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/item.dart';

class DroppedItem extends BodyComponent<SurvivalGame> {
  final Item item;
  final Vector2 initialPosition;
  late SpriteComponent visual;

  DroppedItem({required this.item, required this.initialPosition});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    final sprite = await game.loadSprite(
      item.iconPath ?? Assets.elements.crops.egg,
    );
    visual = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(12),
      anchor: Anchor.center,
    );
    add(visual);

    final itemEffect = ScaleEffect.to(
      Vector2.all(1.0),
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
    visual.scale = Vector2.zero();
    visual.add(itemEffect);
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      linearDamping: 5.0,
    );
    final body = world.createBody(bodyDef);
    body.userData = this;

    final shape = CircleShape()..radius = 4.0;
    final fixtureDef = FixtureDef(shape, friction: 0.0, density: 1.0);
    body.createFixture(fixtureDef);

    final randomAngle = Random().nextDouble() * 2 * pi;
    final randomSpeed = Random().nextDouble() * 40.0 + 20.0;
    final velocity = Vector2(
      cos(randomAngle) * randomSpeed,
      sin(randomAngle) * randomSpeed,
    );

    body.linearVelocity = velocity;
    return body;
  }

  @override
  void update(double dt) {
    priority = (body.position.y + 28).toInt();
  }
}
