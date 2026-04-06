import 'package:survival_game/core/damage_types.dart';

abstract mixin class Damageable {
  void takeDamage({double amount, DamageType type});
}
