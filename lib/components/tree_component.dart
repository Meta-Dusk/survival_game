import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';

class TreeComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<SurvivalGame> {
  late PositionComponent visual;

  TreeComponent({super.position});

  @override
  Future<void> onLoad() async {
    size = Vector2(32, 34);
    anchor = Anchor.center;
    // debugMode = true;

    visual =
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
    add(visual);

    add(
      RectangleHitbox(
        size: Vector2(size.x / 2, size.y / 2 - 4),
        position: Vector2(size.x / 4, size.y / 2 - 4),
      ),
    );

    final baseOfTrunkY = position.y + size.y;
    priority = baseOfTrunkY.toInt();
  }
}
