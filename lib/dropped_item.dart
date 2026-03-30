import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/player.dart';

class DroppedItem extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SurvivalGame> {
  final Item item;

  DroppedItem({required this.item, required super.position})
    : super(size: Vector2(11, 11), anchor: Anchor.center);

  double getRandomAmount(int scale) {
    final randomSign = Random().nextBool() ? 1 : -1;
    return (Random().nextDouble()) * scale * randomSign;
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(item.iconPath ?? Assets.elements.crops.egg);
    add(RectangleHitbox(collisionType: CollisionType.passive));

    scale = Vector2.zero();
    add(
      SequenceEffect(
        [
          ScaleEffect.to(
            Vector2.all(1.0),
            EffectController(duration: 0.3, curve: Curves.easeOutBack),
          ),
          MoveEffect.by(
            Vector2(getRandomAmount(32), getRandomAmount(16)),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        ],
        onComplete: () {
          add(
            MoveByEffect(
              Vector2(0, -4),
              EffectController(
                duration: 1.0,
                alternate: true,
                infinite: true,
                curve: Curves.easeInOut,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      debugPrint("Picked up ${item.name}!");
      removeFromParent();
    }
  }
}
