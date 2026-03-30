import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/player_component.dart';
import 'package:survival_game/hitboxes.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/tree.dart';

class Player extends PlayerComponent {
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
    LogicalKeyboardKey.digit0,
  ];

  bool _isActionKeyPressed = false;
  bool _canAct = true;
  bool _isActing = false;
  bool _isRunning = false;
  bool _isRolling = false;
  bool _isDamageImmune = false;
  // bool _isJumping = false;

  Vector2 _lastPosition = Vector2.zero();
  Vector2 _rollDirection = Vector2.zero();
  final double rollSpeedMultiplier = 2.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    inventory.slots[0] = Equipment(
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

    inventory.slots[2] = Equipment.tool(
      id: "iron_pickaxe",
      name: "Iron Pickaxe",
      damageType: DamageType.mining,
      animationState: PlayerState.mining,
    );
  }

  void addCameraZoom(double value) {
    Viewfinder viewFinder = game.camera.viewfinder;
    viewFinder.zoom = (viewFinder.zoom + value).clamp(3.0, 6.0);
    debugPrint("Setting camera viewfinder zoom to: ${viewFinder.zoom}");
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    velocity = Vector2.zero();
    double step = 1.0;

    _isActionKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyF);
    if (!_isActionKeyPressed) _canAct = true;

    for (int i = 0; i < hotbarSize && i < _hotbarKeys.length; i++) {
      if (keysPressed.contains(_hotbarKeys[i])) {
        inventory.setSlot(i);
        break;
      }
    }

    if (!_isActing && !_isRolling) {
      _isRunning = keysPressed.contains(LogicalKeyboardKey.shiftLeft);

      if (keysPressed.contains(LogicalKeyboardKey.keyW)) velocity.y = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) velocity.y = step;
      if (keysPressed.contains(LogicalKeyboardKey.keyA)) velocity.x = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) velocity.x = step;

      if (velocity.x != 0 || velocity.y != 0) {
        velocity.normalize();
        if (_isRunning) {
          velocity.scale(1.5);
        }
        if (keysPressed.contains(LogicalKeyboardKey.keyV)) {
          _isRolling = true;
          _rollDirection = velocity.clone();
        }
      }
    }

    if (keysPressed.contains(LogicalKeyboardKey.equal)) addCameraZoom(0.5);
    if (keysPressed.contains(LogicalKeyboardKey.minus)) addCameraZoom(-0.5);

    return super.onKeyEvent(event, keysPressed);
  }

  void _setState(PlayerState newState) {
    if (current == newState) return;
    final movementStates = {PlayerState.running, PlayerState.walking};
    int? currentFrame;
    if (movementStates.containsAll([current, newState])) {
      currentFrame = layers.first.animationTicker?.currentIndex;
    }
    current = newState;
    for (var layer in layers) {
      layer.current = newState;
      if (currentFrame != null) {
        layer.animationTicker?.currentIndex = currentFrame;
      }
    }
  }

  @override
  void update(double dt) {
    _lastPosition = position.clone();
    weaponHitbox.isDamageActive = false;

    final holding = inventory.activeItem;
    bool canSwing = false;
    if (holding == null) {
      canSwing = false;
    } else if (holding.category.isSwingable) {
      canSwing = true;
    }

    if (_isActionKeyPressed && !_isActing && _canAct && canSwing) {
      _isActing = true;
      weaponHitbox.resetSwing();
      if (holding?.autoSwing == false) _canAct = false;
      final targetState = holding?.animationState ?? PlayerState.attacking;
      for (var layer in layers) {
        layer.animationTickers?[targetState]?.reset();
      }
    }

    if (_isRolling) {
      _setState(PlayerState.rolling);
      SpriteAnimationTicker? ticker;
      double currentSpeed = moveSpeed;

      if (layers.isNotEmpty) ticker = layers.first.animationTickers?[current];

      if (ticker != null) {
        if (ticker.currentIndex >= 2 && ticker.currentIndex <= 5) {
          currentSpeed = moveSpeed * rollSpeedMultiplier;
          _isDamageImmune = true;
          debugPrint("Player damage immunity: $_isDamageImmune");
        } else {
          _isDamageImmune = false;
          debugPrint("Player damage immunity: $_isDamageImmune");
        }
      }

      if (ticker?.done() == true) {
        _isRolling = false;
        _setState(PlayerState.idle);
      }
      position += _rollDirection * currentSpeed * dt;
    } else if (_isActing) {
      final targetState = holding?.animationState ?? PlayerState.attacking;
      weaponHitbox.currentDamageType =
          holding?.damageType ?? DamageType.unarmed;
      _setState(targetState);

      SpriteAnimationTicker? ticker;
      if (layers.isNotEmpty) ticker = layers.first.animationTickers?[current];

      if (ticker != null) {
        if (ticker.currentIndex >= 5 && ticker.currentIndex <= 6) {
          weaponHitbox.isDamageActive = true;
        } else {
          weaponHitbox.isDamageActive = false;
        }
      }
      if (ticker?.done() == true) {
        _isActing = false;
        weaponHitbox.isDamageActive = false;
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
