import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/hitboxes.dart';
import 'package:survival_game/inventory.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/tree.dart';

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

class Player extends PositionComponent
    with KeyboardHandler, HasGameReference<SurvivalGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double moveSpeed = 75.0;
  final List<PlayerSpriteLayer> _layers = [];
  PlayerState current = PlayerState.idle;
  final Inventory inventory = Inventory();
  final int hotbarSize = 5;
  static const List<LogicalKeyboardKey> _hotbarKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  bool _isActionKeyPressed = false;
  bool _canAct = true;
  bool _isActing = false;
  bool _isRunning = false;

  late WeaponHitbox _weaponHitbox;
  Vector2 _lastPosition = Vector2.zero();

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

    _layers.add(layer);
    add(layer);
  }

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

    _weaponHitbox = WeaponHitbox()
      ..size = Vector2(27, 25)
      ..position = Vector2(size.x / 2 - 2, 15);

    add(_weaponHitbox);

    inventory.slots.first = Equipment(
      id: "iron_sword",
      name: "Iron Sword",
      category: ItemCategory.weapon,
      damageType: DamageType.slashing,
      animationState: PlayerState.attacking,
    );

    inventory.slots[1] = Equipment.tool(
      id: "iron_axe",
      name: "Iron Axe",
      damageType: DamageType.chopping,
      animationState: PlayerState.chopping,
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    velocity = Vector2.zero();
    final double step = 1.0;

    _isActionKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyF);
    if (!_isActionKeyPressed) _canAct = true;

    for (int i = 0; i < hotbarSize && i < _hotbarKeys.length; i++) {
      if (keysPressed.contains(_hotbarKeys[i])) {
        inventory.setSlot(i);
        break;
      }
    }

    if (!_isActing) {
      _isRunning = keysPressed.contains(LogicalKeyboardKey.shiftLeft)
          ? true
          : false;
      if (keysPressed.contains(LogicalKeyboardKey.keyW)) velocity.y = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) velocity.y = step;
      if (keysPressed.contains(LogicalKeyboardKey.keyA)) velocity.x = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) velocity.x = step;

      if (velocity.x != 0 || velocity.y != 0) {
        velocity.normalize();
        if (_isRunning) velocity.scale(1.5);
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  void _setState(PlayerState newState) {
    if (current == newState) return;
    final movementStates = {PlayerState.running, PlayerState.walking};
    int? currentFrame;
    if (movementStates.containsAll([current, newState])) {
      currentFrame = _layers.first.animationTicker?.currentIndex;
    }
    current = newState;
    for (var layer in _layers) {
      layer.current = newState;
      if (currentFrame != null) {
        layer.animationTicker?.currentIndex = currentFrame;
      }
    }
  }

  @override
  void update(double dt) {
    _lastPosition = position.clone();
    _weaponHitbox.isDamageActive = false;

    final holding = inventory.activeItem;
    bool canSwing = false;
    if (holding == null) {
      canSwing = false;
    } else if (holding.category.isSwingable) {
      canSwing = true;
    }

    if (_isActionKeyPressed && !_isActing && _canAct && canSwing) {
      _isActing = true;
      _weaponHitbox.resetSwing();
      if (holding?.autoSwing == false) _canAct = false;
      final targetState = holding?.animationState ?? PlayerState.attacking;
      for (var layer in _layers) {
        layer.animationTickers?[targetState]?.reset();
      }
    }

    if (_isActing) {
      final targetState = holding?.animationState ?? PlayerState.attacking;
      _weaponHitbox.currentDamageType =
          holding?.damageType ?? DamageType.unarmed;
      _setState(targetState);

      SpriteAnimationTicker? ticker;
      if (_layers.isNotEmpty) ticker = _layers.first.animationTickers?[current];

      if (ticker != null) {
        if (ticker.currentIndex >= 5 && ticker.currentIndex <= 6) {
          _weaponHitbox.isDamageActive = true;
        } else {
          _weaponHitbox.isDamageActive = false;
        }
      }
      if (ticker?.done() == true) {
        _isActing = false;
        _weaponHitbox.isDamageActive = false;
        _setState(PlayerState.idle);
      }
    } else {
      position += velocity * moveSpeed * dt;

      if (velocity.isZero()) {
        _setState(PlayerState.idle);
      } else {
        _setState(_isRunning ? PlayerState.running : PlayerState.walking);
        if ((velocity.x < 0 && !isFlippedHorizontally) ||
            (velocity.x > 0 && isFlippedHorizontally)) {
          flipHorizontally();
        }
      }
    }

    final feetY = position.y + (size.y / 2);
    priority = feetY.toInt();

    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Tree) {
      // Get the current absolute screen boundaries
      final playerBox = children
          .whereType<RectangleHitbox>()
          .first
          .toAbsoluteRect();
      final treeBox = other.children
          .whereType<RectangleHitbox>()
          .first
          .toAbsoluteRect();

      // Calculate exactly how far the player moved this specific frame
      final deltaX = position.x - _lastPosition.x;
      final deltaY = position.y - _lastPosition.y;

      // Reconstruct the player's bounding box from the PREVIOUS frame
      final lastPlayerBox = playerBox.shift(Offset(-deltaX, -deltaY));

      // Check which axes were completely completely clear a fraction of a second ago
      bool wasClearX =
          lastPlayerBox.right <= treeBox.left ||
          lastPlayerBox.left >= treeBox.right;
      bool wasClearY =
          lastPlayerBox.bottom <= treeBox.top ||
          lastPlayerBox.top >= treeBox.bottom;

      // The Sliding Logic: Only revert the axis that caused the crash
      if (wasClearX && !wasClearY) {
        position.x = _lastPosition.x; // Came from the side, cancel X
      } else if (wasClearY && !wasClearX) {
        position.y = _lastPosition.y; // Came from top/bottom, cancel Y
      } else if (wasClearX && wasClearY) {
        // Perfect diagonal corner strike: Stop dead at the exact tip of the corner
        position.x = _lastPosition.x;
        position.y = _lastPosition.y;
      } else {
        // Absolute Fallback: (Triggered only if the player somehow spawns inside the tree)
        final penX =
            (playerBox.width / 2 + treeBox.width / 2) -
            (playerBox.center.dx - treeBox.center.dx).abs();
        final penY =
            (playerBox.height / 2 + treeBox.height / 2) -
            (playerBox.center.dy - treeBox.center.dy).abs();
        if (penX < penY) {
          position.x = _lastPosition.x;
        } else {
          position.y = _lastPosition.y;
        }
      }
    }
  }
}
