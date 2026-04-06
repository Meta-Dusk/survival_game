import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/shadows.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/inventory/inventory.dart';

enum PlayerState {
  attacking,
  carrying,
  casting,
  catching,
  chopping,
  death,
  digging,
  hammering,
  hurt,
  idle,
  interacting,
  jumping,
  mining,
  reeling,
  rolling,
  running,
  swimming,
  waiting,
  walking,
  watering,
}

const Set loopingStates = {
  PlayerState.idle,
  PlayerState.running,
  PlayerState.walking,
  PlayerState.swimming,
  PlayerState.waiting,
};

class PlayerSpriteLayer extends SpriteAnimationGroupComponent<PlayerState> {
  PlayerSpriteLayer({super.size, super.current, super.animations})
    : super(paint: Paint()..isAntiAlias = false);
}

class PlayerComponent extends BodyComponent<SurvivalGame> with KeyboardHandler {
  final Vector2 initialPosition;
  final spriteSize = Vector2(96, 64);
  bool isFlippedHorizontally = false;

  @protected
  final List<PlayerSpriteLayer> layers = [];

  PlayerState current = PlayerState.idle;
  final Inventory inventory = Inventory();

  PlayerComponent({required this.initialPosition});

  void flipHorizontally() {
    isFlippedHorizontally = !isFlippedHorizontally;
    for (var layer in layers) {
      layer.flipHorizontally();
    }
  }

  Future<SpriteAnimation> _createAnimation(
    String path, {
    int? amount,
    bool loop = true,
  }) async {
    final image = await game.images.load(path);
    final spriteSheet = SpriteSheet(image: image, srcSize: spriteSize);

    return spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.1,
      to: amount ?? _getFrames(path),
      loop: loop,
    );
  }

  int _getFrames(String path) {
    final split = path.split("_");
    final suffix = split.last.split(".");
    final strip = suffix.first.split("strip");
    return int.parse(strip.last);
  }

  Future<void> _addLayer(PlayerAnimationSet assetSet) async {
    final Map<PlayerState, SpriteAnimation> loadedAnimations = {};

    for (var entry in assetSet.asMap.entries) {
      final state = entry.key;
      final path = entry.value;

      loadedAnimations[state] = await _createAnimation(
        path,
        loop: loopingStates.contains(state),
      );
    }

    final layer = PlayerSpriteLayer(
      size: spriteSize,
      current: PlayerState.idle,
      animations: loadedAnimations,
    )..anchor = Anchor.center;

    layers.add(layer);
    add(layer);
  }

  @mustCallSuper
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    add(PixelShadow(position: Vector2(0, 10)));
    await _addLayer(Assets.entities.player.base);
    await _addLayer(Assets.entities.player.hair.bowlHair);
    await _addLayer(Assets.entities.player.tools);
  }

  void setTint(Color color) {
    for (var layer in layers) {
      layer.paint.colorFilter = ColorFilter.mode(color, BlendMode.srcATop);
    }
  }

  void removeTint() {
    for (var layer in layers) {
      layer.paint.colorFilter = null;
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      fixedRotation: true,
    );
    final body = world.createBody(bodyDef);
    body.userData = this;
    final shape = CircleShape()..radius = 6.0;
    final fixtureDef = FixtureDef(shape, friction: 0.0, density: 1.0);
    body.createFixture(fixtureDef);
    return body;
  }
}
