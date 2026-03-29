import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survival_game/tree.dart';

enum DamageType {
  unarmed,
  slashing, // Swords
  chopping, // Axes
  mining, // Pickaxes
}

class WeaponHitbox extends PositionComponent with CollisionCallbacks {
  final List<PositionComponent> _hitObjects = [];
  bool isDamageActive = false;
  DamageType currentDamageType = DamageType.unarmed;

  WeaponHitbox() {
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!isDamageActive) return;

    if (other is Tree) {
      if (!_hitObjects.contains(other)) {
        other.chop(currentDamageType);
        _hitObjects.add(other);
      }
    }
  }

  void resetSwing() {
    _hitObjects.clear();
  }
}
