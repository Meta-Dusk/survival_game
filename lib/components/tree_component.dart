import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/widgets.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';

class TreeComponent extends BodyComponent<SurvivalGame> {
  final Vector2 initialPosition;
  final spriteSize = Vector2(32, 34);
  late PositionComponent visual;
  late SpriteAnimationComponent leaves;

  TreeComponent({required this.initialPosition});

  @mustCallSuper
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    leaves =
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
          ..position = position.clone()
          ..priority = priority + 1;

    visual = SpriteAnimationComponent.fromFrameData(
      await game.images.load(Assets.elements.plants.decoTree01),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2 + (Random().nextDouble() * 0.3),
        textureSize: spriteSize,
      ),
    )..anchor = const Anchor(0.5, 0.6);
    add(visual);

    final baseOfTrunkY = initialPosition.y + spriteSize.y - 2;
    priority = baseOfTrunkY.toInt();
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: initialPosition, type: BodyType.static);
    final body = world.createBody(bodyDef);
    body.userData = this;

    final shape = PolygonShape();
    final double w = 6.0;
    final double h = 2.5;
    final vertices = [
      Vector2(-w, 0), // Far Left
      Vector2(-w / 2, h), // Bottom Left
      Vector2(w / 2, h), // Bottom Right
      Vector2(w, 0), // Far Right
      Vector2(w / 2, -h), // Top Right
      Vector2(-w / 2, -h), // Top Left
    ];
    shape.set(vertices);

    final fixtureDef = FixtureDef(shape);
    body.createFixture(fixtureDef);

    return body;
  }
}
