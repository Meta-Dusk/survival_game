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
  final Item itemData;

  DroppedItem({required this.itemData, required super.position})
    : super(size: Vector2(11, 11), anchor: Anchor.center);

  double getRandomAmount(int scale) {
    final randomSign = Random().nextBool() ? 1 : -1;
    return (Random().nextDouble() - 0.5) * scale * randomSign;
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(Assets.elements.crops.wood);
    add(RectangleHitbox(collisionType: CollisionType.passive));

    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.3, curve: Curves.easeOutBack),
      ),
    );

    add(
      MoveEffect.by(
        Vector2(getRandomAmount(32), getRandomAmount(16)),
        EffectController(duration: 0.2, curve: Curves.easeOut),
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
      debugPrint("Picked up ${itemData.name}!");
      removeFromParent();
    }
  }
}
