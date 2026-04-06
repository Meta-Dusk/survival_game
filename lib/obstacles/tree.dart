import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/tree_component.dart';
import 'package:survival_game/components/tree_effects.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/core/damageable.dart';
import 'package:survival_game/inventory/dropped_item.dart';
import 'package:survival_game/core/damage_types.dart';
import 'package:survival_game/inventory/item.dart';
import 'package:survival_game/obstacles/obstacle.dart';

class Tree extends TreeComponent with TreeEffects, ObstacleType, Damageable {
  double health;
  int dropAmount;

  Tree({
    required super.initialPosition,
    this.health = 5.0,
    this.dropAmount = 3,
  });

  @override
  void takeDamage({double amount = 1, DamageType type = DamageType.unarmed}) {
    if (type != DamageType.chopping) return;

    health -= amount;
    debugPrint("Tree health is now: $health");

    if (Random().nextBool()) leaves.flipHorizontally();
    leaves.animationTicker?.reset();
    game.world.add(leaves);

    final damageFlashEffect = ColorEffect(
      Colors.white,
      EffectController(duration: 0.1, reverseDuration: 0.1),
      opacityTo: 0.8,
    );
    visual.add(damageFlashEffect);

    spawnWoodChips();

    if (health > 0) {
      final shrinkEffect = SequenceEffect([
        ScaleEffect.by(Vector2(0.9, 0.9), EffectController(duration: 0.05)),
        ScaleEffect.by(Vector2(1.0, 1.1), EffectController(duration: 0.1)),
        ScaleEffect.to(Vector2(1.0, 1.0), EffectController(duration: 0.05)),
      ]);
      visual.add(shrinkEffect);
      return;
    }
    debugPrint("Ded");

    final deathEffect = ScaleEffect.to(
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
          for (int i = 0; i <= dropAmount; i++)
            DroppedItem(item: wood, initialPosition: initialPosition),
        ]);
        removeFromParent();
      },
    );
    visual.add(deathEffect);
  }
}
