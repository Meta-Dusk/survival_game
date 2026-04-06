import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/components/player_component.dart';
import 'package:survival_game/components/player_effects.dart';
import 'package:survival_game/core/damage_types.dart';
import 'package:survival_game/damageable.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/terrain/terrain_tile.dart';

class Player extends PlayerComponent with PlayerEffects, ContactCallbacks {
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
  bool _isJumping = false;
  bool _hasDealtDamage = false;

  Vector2 _rollDirection = Vector2.zero();
  final double moveSpeed = 80.0;
  final double rollSpeedMultiplier = 2.5;
  final double sprintSpeedMultiplier = 1.5;
  final double swimSpeedMultiplier = 0.5;
  Vector2 velocity = Vector2.zero();
  int _waterContacts = 0;
  bool get _isSwimming => _waterContacts > 0;

  Player() : super(initialPosition: Vector2.zero());

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
    viewFinder.zoom = (viewFinder.zoom + value).clamp(1.0, 6.0);
    debugPrint("Setting camera viewfinder zoom to: ${viewFinder.zoom}");
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    velocity = Vector2.zero();
    double step = 1.0;

    _isActionKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyF) && !_isSwimming;
    if (!_isActionKeyPressed) _canAct = true;

    for (int i = 0; i < inventory.capacity && i < _hotbarKeys.length; i++) {
      if (!keysPressed.contains(_hotbarKeys[i])) continue;
      inventory.setSlot(i);
      break;
    }

    if (!_isActing && !_isRolling) {
      _isRunning = keysPressed.contains(LogicalKeyboardKey.shiftLeft);

      if (keysPressed.contains(LogicalKeyboardKey.keyW)) velocity.y = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) velocity.y = step;
      if (keysPressed.contains(LogicalKeyboardKey.keyA)) velocity.x = -step;
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) velocity.x = step;

      if (keysPressed.contains(LogicalKeyboardKey.keyV) &&
          !_isJumping &&
          !_isSwimming) {
        _isRolling = true;

        if (velocity.isZero()) {
          _rollDirection = Vector2(isFlippedHorizontally ? -1.0 : 1.0, 0.0);
        } else {
          _rollDirection = velocity.normalized();
        }

        for (var layer in layers) {
          layer.animationTickers?[PlayerState.rolling]?.reset();
        }
      }

      if (keysPressed.contains(LogicalKeyboardKey.space) &&
          !_isJumping &&
          !_isSwimming) {
        _isJumping = true;

        for (var layer in layers) {
          layer.animationTickers?[PlayerState.jumping]?.reset();
        }
      }

      if (velocity.x != 0 || velocity.y != 0) {
        velocity.normalize();
        if (_isRunning) velocity.scale(sprintSpeedMultiplier);
      }
    }

    if (keysPressed.contains(LogicalKeyboardKey.equal)) addCameraZoom(1.0);
    if (keysPressed.contains(LogicalKeyboardKey.minus)) addCameraZoom(-1.0);

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
      if (currentFrame == null) continue;
      layer.animationTicker?.currentIndex = currentFrame;
    }
  }

  @override
  void update(double dt) {
    final holding = inventory.activeItem;
    bool canSwing = false;
    if (holding == null) {
      canSwing = false;
    } else if (holding.category.isSwingable) {
      canSwing = true;
    }

    if (_isActionKeyPressed && !_isActing && _canAct && canSwing) {
      _isActing = true;
      if (holding?.autoSwing == false) _canAct = false;
      final targetState = holding?.animationState ?? PlayerState.attacking;
      for (var layer in layers) {
        layer.animationTickers?[targetState]?.reset();
      }
    }

    // Rolling or Dodging
    if (_isRolling) {
      _setState(PlayerState.rolling);
      SpriteAnimationTicker? ticker;
      double currentSpeed = moveSpeed;

      if (layers.isNotEmpty) ticker = layers.first.animationTickers?[current];

      if (ticker != null) {
        if (ticker.currentIndex >= 2 && ticker.currentIndex <= 5) {
          currentSpeed = moveSpeed * rollSpeedMultiplier;
          _setDamageImmune(true);
        } else {
          _setDamageImmune(false);
        }
      }

      if (ticker?.done() == true) {
        _isRolling = false;
        _setState(PlayerState.idle);
        _setDamageImmune(false);
      }
      body.linearVelocity = _rollDirection * currentSpeed;

      // Jumping
    } else if (_isJumping) {
      _setState(PlayerState.jumping);
      SpriteAnimationTicker? ticker;
      if (layers.isNotEmpty) ticker = layers.first.animationTickers?[current];

      body.linearVelocity = velocity * moveSpeed;

      if ((velocity.x < 0 && !isFlippedHorizontally) ||
          (velocity.x > 0 && isFlippedHorizontally)) {
        flipHorizontally();
      }

      if (ticker?.done() == true) {
        _isJumping = false;
        _setState(PlayerState.idle);
      }

      // Using Equipment
    } else if (_isActing) {
      final targetState = holding?.animationState ?? PlayerState.attacking;
      _setState(targetState);
      body.linearVelocity = Vector2.zero();

      SpriteAnimationTicker? ticker;
      if (layers.isNotEmpty) ticker = layers.first.animationTickers?[current];

      if (ticker != null &&
          {5, 6}.contains(ticker.currentIndex) &&
          !_hasDealtDamage) {
        _hasDealtDamage = true;

        final directionMultiplier = isFlippedHorizontally ? -1.0 : 1.0;
        final strikeOffset = Vector2(16.0 * directionMultiplier, 0);
        final strikeCenter = body.position + strikeOffset;
        final strikeSize = Vector2.all(8.0);
        final aabb = AABB()
          ..lowerBound.setFrom(strikeCenter - strikeSize)
          ..upperBound.setFrom(strikeCenter + strikeSize);
        world.queryAABB(AttackQueryCallback(holding, body), aabb);

        if (debugMode) {
          final debugSquare = RectangleComponent(
            position: strikeCenter,
            size: strikeSize * 2,
            anchor: Anchor.center,
            paint: Paint()..color = Colors.red.withValues(alpha: 0.5),
            priority: 9999,
          );
          game.world.add(debugSquare);
          Future.delayed(const Duration(milliseconds: 200), () {
            if (debugSquare.isMounted) {
              debugSquare.removeFromParent();
            }
          });
        }
      }
      if (ticker?.done() == true) {
        _isActing = false;
        _hasDealtDamage = false;
        _setState(PlayerState.idle);
      }

      // Walking, Running, Swimming
    } else {
      double currentSpeed = moveSpeed;
      if (_isSwimming) currentSpeed *= swimSpeedMultiplier;
      body.linearVelocity = velocity * currentSpeed;

      if (velocity.isZero()) {
        _setState(_isSwimming ? PlayerState.swimming : PlayerState.idle);
      } else {
        if (_isSwimming) {
          _setState(PlayerState.swimming);
        } else {
          _setState(_isRunning ? PlayerState.running : PlayerState.walking);
        }

        if ((velocity.x < 0 && !isFlippedHorizontally) ||
            (velocity.x > 0 && isFlippedHorizontally)) {
          flipHorizontally();
        }
      }
    }

    final feetY = body.position.y + (spriteSize.y / 2);
    priority = feetY.toInt();
    animationParticles();
  }

  void _setDamageImmune(bool immune) {
    if (_isDamageImmune == immune) return;
    _isDamageImmune = immune;

    if (immune) {
      setTint(Colors.grey.shade400.withValues(alpha: 0.35));
    } else {
      removeTint();
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is TerrainTile && other.type == TileType.water) {
      _waterContacts++;
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is TerrainTile && other.type == TileType.water) {
      _waterContacts--;
    }
  }
}

class AttackQueryCallback extends QueryCallback {
  final Item? weapon;
  final Body attackerBody;
  final bool debugMode;

  AttackQueryCallback(this.weapon, this.attackerBody, {this.debugMode = false});

  @override
  bool reportFixture(Fixture fixture) {
    if (fixture.body == attackerBody) return true;

    final userData = fixture.body.userData;
    if (debugMode) debugPrint("Weapon AABB physically touched: $userData");

    if (userData is Damageable) {
      double damageAmount = 1.0;

      if (weapon is Equipment) {
        damageAmount = (weapon as Equipment).damage;
      }

      userData.takeDamage(
        damageAmount,
        weapon?.damageType ?? DamageType.unarmed,
      );
      return false;
    }
    return true;
  }
}
