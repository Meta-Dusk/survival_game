import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/player_component.dart';

mixin PlayerEffects on PlayerComponent {
  int _lastAnimationFrame = -1;

  void animationParticles() {
    SpriteAnimationTicker? currentTicker;
    if (layers.isNotEmpty) {
      currentTicker = layers.first.animationTickers?[current];
    }
    if (currentTicker == null) return;

    int currentFrame = currentTicker.currentIndex;
    if (currentFrame == _lastAnimationFrame) return;

    if (current == PlayerState.running) {
      final Set<int> stepFrames = {0, 2, 4, 6};
      if (stepFrames.contains(currentFrame)) {
        // Loud footstep SFX here
        spawnDust();
      }
    } else if (current == PlayerState.jumping) {
      final Set<int> stepFrames = {2, 8};
      if (stepFrames.contains(currentFrame)) {
        // Jump SFX here
        spawnDust(count: 5);
      }
    } else if (current == PlayerState.rolling) {
      final Set<int> stepFrames = {2, 5};
      if (stepFrames.contains(currentFrame)) {
        // Rolling SFX here
        spawnDust(count: 10, range: 6.0);
      }
    }

    _lastAnimationFrame = currentFrame;
  }

  void spawnDust({int count = 3, double range = 3.0}) {
    Particle generator = Particle.generate(
      count: count,
      lifespan: 0.3,
      generator: (i) {
        // Slight random spread, floating slightly upwards
        final randomVelocity = Vector2(
          (Random().nextDouble() - 0.5) * 50,
          -Random().nextDouble() * 30,
        );

        return AcceleratedParticle(
          position: Vector2(Random().nextDoubleBetween(-range, range), 0),
          speed: randomVelocity,
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final paint = Paint()
                // Start at 50% opacity and fade to 0
                ..color = Colors.white.withValues(
                  alpha: (1.0 - particle.progress) * 0.5,
                );
              canvas.drawRect(
                Rect.fromCenter(center: Offset.zero, width: 2, height: 2),
                paint,
              );
            },
          ),
        );
      },
    );

    game.world.add(
      ParticleSystemComponent(
        position: position.clone() + Vector2(0, size.y / 4 - 8),
        particle: generator,
        anchor: Anchor.bottomCenter,
        priority: priority + 1,
      ),
    );
  }
}
