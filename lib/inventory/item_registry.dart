enum ItemType { wood }

class ItemData {
  final String name;
  final String description;
  final int sheetX;
  final int sheetY;
  final int maxStack;
  final bool isTool;

  const ItemData({
    required this.name,
    required this.description,
    required this.sheetX,
    required this.sheetY,
    this.maxStack = 64,
    this.isTool = false,
  });
}

class ItemRegistry {
  static const Map<ItemType, ItemData> _items = {
    ItemType.wood: ItemData(
      name: "Log",
      description: "Sturdy wood for crafting.",
      sheetX: 49,
      sheetY: 11,
    ),
  };

  static ItemData get(ItemType type) {
    if (!_items.containsKey(type)) {
      throw Exception("Item $type is missing from the registry!");
    }
    return _items[type]!;
  }
}
