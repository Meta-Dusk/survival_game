import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/dropped_item.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/hitboxes.dart';
import 'package:survival_game/item.dart';

class Tree extends PositionComponent
    with CollisionCallbacks, HasGameReference<SurvivalGame> {
  int health = 5;
  late PositionComponent _visual;

  Tree({super.position});

  @override
  Future<void> onLoad() async {
    size = Vector2(32, 34);
    anchor = Anchor.center;
    // debugMode = true;

    _visual =
        SpriteAnimationComponent.fromFrameData(
            await game.images.load(Assets.elements.plants.decoTree01),
            SpriteAnimationData.sequenced(
              amount: 4,
              stepTime: 0.2 + (Random().nextDouble() * 0.3),
              textureSize: size,
            ),
          )
          ..anchor = Anchor.bottomCenter
          ..position = Vector2(size.x / 2, size.y);
    add(_visual);

    add(
      RectangleHitbox(
        size: Vector2(size.x / 2, size.y / 2 - 4),
        position: Vector2(size.x / 4, size.y / 2 - 4),
      ),
    );

    final baseOfTrunkY = position.y + size.y;
    priority = baseOfTrunkY.toInt();
  }

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
    _visual.add(leaves);

    // Damage flash
    _visual.add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, reverseDuration: 0.1),
        opacityTo: 0.8,
      ),
    );

    _spawnWoodChips();

    // Sway
    _visual.add(
      SequenceEffect([
        ScaleEffect.by(Vector2(0.9, 0.9), EffectController(duration: 0.05)),
        ScaleEffect.by(Vector2(1.0, 1.1), EffectController(duration: 0.1)),
        ScaleEffect.to(Vector2(1.0, 1.0), EffectController(duration: 0.05)),
      ]),
    );

    if (health <= 0) {
      debugPrint("Ded");

      // Death shrink
      _visual.add(
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

  void _spawnWoodChips() {
    Particle generator = Particle.generate(
      count: Random().nextInt(8),
      lifespan: 0.4,
      generator: (i) {
        final randomVelocity = Vector2(
          (Random().nextDouble() - 0.5) * 150,
          Random().nextDouble() * -150,
        );

        ComputedParticle computedParticle = ComputedParticle(
          renderer: (canvas, particle) {
            final paint = Paint()
              ..color = Colors.brown.shade600.withValues(
                alpha: 1.0 - particle.progress,
              );
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: 4, height: 4),
              paint,
            );
          },
        );

        return AcceleratedParticle(
          speed: randomVelocity,
          acceleration: Vector2(0, 400),
          child: computedParticle,
        );
      },
    );

    game.world.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: generator,
        priority: priority + 1,
      ),
    );
  }
}
