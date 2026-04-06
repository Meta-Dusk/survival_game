import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_fonts.dart';
import 'package:survival_game/entities/player.dart';
import 'package:survival_game/terrain/world_generator.dart';

class SurvivalGame extends Forge2DGame with HasKeyboardHandlerComponents {
  final Player player = Player();

  SurvivalGame() : super(gravity: Vector2.zero());

  @override
  Future<void> onLoad() async {
    maxTranslation = 8.0;
    await world.add(WorldGenerator());
    world.add(player);
    camera.viewfinder.zoom = 3.0;

    final fpsCounter = FpsTextComponent(
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: FontFamilies.pixelifySans,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
          fontFeatures: [FontFeature.proportionalFigures()],
        ),
      ),
    );
    camera.viewport.add(fpsCounter);

    pauseEngine();
    // await Future.delayed(const Duration(seconds: 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    camera.viewfinder.position = player.position..round();
  }
}
