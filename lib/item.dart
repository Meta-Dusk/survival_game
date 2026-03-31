import 'package:survival_game/components/player_component.dart';
import 'package:survival_game/components/hitboxes.dart';

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
  final String? iconPath;

  Item({
    required this.id,
    required this.name,
    this.category = ItemCategory.resource,
    this.maxStack = 99,
    this.count = 1,
    this.damageType,
    this.animationState,
    this.autoSwing = false,
    this.iconPath,
  });
}

class Equipment extends Item {
  int currentDurability;
  final int maxDurability;
  final int defense;

  Equipment({
    required super.id,
    required super.name,
    required super.category,
    super.maxStack = 1,
    super.autoSwing = false,
    super.damageType,
    super.animationState,
    this.maxDurability = 100,
    this.defense = 0,
  }) : currentDurability = maxDurability;

  Equipment.tool({
    required super.id,
    required super.name,
    super.category = ItemCategory.tool,
    super.maxStack = 1,
    super.autoSwing = true,
    super.damageType,
    super.animationState,
    this.maxDurability = 100,
    this.defense = 0,
  }) : currentDurability = maxDurability;
}
