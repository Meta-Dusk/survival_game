import 'package:survival_game/hitboxes.dart';
import 'package:survival_game/player.dart';

Set swingable = {ItemCategory.tool, ItemCategory.weapon};

enum ItemCategory {
  resource,
  tool,
  weapon,
  consumable;

  bool get isSwingable => swingable.contains(this);
}

class Item {
  final String id;
  final String name;
  final ItemCategory category;
  final int maxStack;
  int count;
  final DamageType? damageType;
  final PlayerState? animationState;
  final bool autoSwing;

  Item({
    required this.id,
    required this.name,
    this.category = ItemCategory.resource,
    this.maxStack = 99,
    this.count = 1,
    this.damageType,
    this.animationState,
    this.autoSwing = false,
  });
}
