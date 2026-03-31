import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/tree_component.dart';
import 'package:survival_game/components/tree_effects.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/dropped_item.dart';
import 'package:survival_game/components/hitboxes.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/obstacles/obstacle.dart';

class Tree extends TreeComponent with TreeEffects, ObstacleType {
  int health = 5;

  Tree({super.position});

  Future<void> chop(DamageType incomingDamage) async {
    if (incomingDamage != DamageType.chopping) return;

    health--;
    debugPrint("Tree health is now: $health");

    SpriteAnimationComponent leaves =
        SpriteAnimationComponent.fromFrameData(
            await game.images.load(Assets.elements.vfx.organic.leavesHit),
            SpriteAnimationData.sequenced(
              amount: 10,
              stepTime: 0.1,
              textureSize: Vector2(64, 32),
              loop: false,
            ),
          )
          ..removeOnFinish = true
          ..anchor = Anchor.bottomCenter
          ..position = position.clone() - Vector2(size.x / 2, -size.y / 2)
          ..priority = priority + 1;

    if (Random().nextBool()) leaves.flipHorizontally();
    visual.add(leaves);

    // Damage flash
    visual.add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, reverseDuration: 0.1),
        opacityTo: 0.8,
      ),
    );

    spawnWoodChips();

    // Sway
    visual.add(
      SequenceEffect([
        ScaleEffect.by(Vector2(0.9, 0.9), EffectController(duration: 0.05)),
        ScaleEffect.by(Vector2(1.0, 1.1), EffectController(duration: 0.1)),
        ScaleEffect.to(Vector2(1.0, 1.0), EffectController(duration: 0.05)),
      ]),
    );

    if (health <= 0) {
      debugPrint("Ded");

      // Death shrink
      visual.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.2),
          onComplete: () {
            final wood = Item(
              id: "wood",
              name: "Wood",
              category: ItemCategory.resource,
              iconPath: Assets.elements.crops.wood,
            );
            game.world.addAll([
              for (int i = 0; i <= 3; i++)
                DroppedItem(item: wood, position: position.clone()),
            ]);
            removeFromParent();
          },
        ),
      );
    }
  }
}
