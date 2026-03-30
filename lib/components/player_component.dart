import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/hitboxes.dart';
import 'package:survival_game/inventory.dart';

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

Set loopingStates = {
  PlayerState.idle,
  PlayerState.running,
  PlayerState.walking,
};

class PlayerSpriteLayer extends SpriteAnimationGroupComponent<PlayerState> {
  PlayerSpriteLayer({super.size, super.current, super.animations})
    : super(paint: Paint()..isAntiAlias = false);

  // @override
  // void render(Canvas canvas) {
  //   animationTickers?[current]?.getSprite().render(
  //     canvas,
  //     size: size,
  //     overridePaint: paint,
  //   );
  //   super.render(canvas);
  // }
}

class PlayerComponent extends PositionComponent
    with KeyboardHandler, HasGameReference<SurvivalGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double moveSpeed = 75.0;

  @protected
  final List<PlayerSpriteLayer> layers = [];

  @protected
  late WeaponHitbox weaponHitbox;

  PlayerState current = PlayerState.idle;
  final Inventory inventory = Inventory();
  final int hotbarSize = 5;

  Future<SpriteAnimation> _createAnimation(
    String path, {
    int? amount,
    bool loop = true,
  }) async {
    final image = await game.images.load(path);
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    return spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.1,
      to: amount ?? getFrames(path),
      loop: loop,
    );
  }

  int getFrames(String path) {
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
      size: size,
      current: PlayerState.idle,
      animations: loadedAnimations,
    );

    layers.add(layer);
    add(layer);
  }

  @mustCallSuper
  @override
  Future<void> onLoad() async {
    size = Vector2(96, 64);
    anchor = Anchor.center;

    await _addLayer(Assets.entities.player.base);
    await _addLayer(Assets.entities.player.hair.bowlHair);
    await _addLayer(Assets.entities.player.tools);

    add(
      RectangleHitbox(
        size: Vector2(8, 8),
        position: Vector2(size.x / 2 - 4, size.y / 2),
      ),
    );

    weaponHitbox = WeaponHitbox()
      ..size = Vector2(27, 25)
      ..position = Vector2(size.x / 2 - 2, 15);
    add(weaponHitbox);
  }
}
