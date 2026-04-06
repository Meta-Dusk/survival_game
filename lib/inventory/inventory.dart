import 'package:survival_game/inventory/item.dart';
import 'package:flutter/material.dart';

class Inventory {
  final int capacity;
  final List<Item?> slots;
  int activeSlotIndex = 0;
  final ValueNotifier<int> activeSlotNotifier = ValueNotifier<int>(0);

  Inventory({this.capacity = 10}) : slots = List.filled(capacity, null);

  Item? get activeItem => slots[activeSlotIndex];

  void setSlot(int index) {
    if (index < 0 || index > capacity) return;
    activeSlotIndex = index;
    activeSlotNotifier.value = index;
  }
}
