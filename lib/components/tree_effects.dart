import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/tree_component.dart';

mixin TreeEffects on TreeComponent {
  void spawnWoodChips() {
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
