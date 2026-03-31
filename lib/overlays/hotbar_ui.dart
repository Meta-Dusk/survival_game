import 'package:flutter/material.dart';
import 'package:survival_game/item.dart';
import 'package:survival_game/entities/player.dart';

class HotbarUi extends StatelessWidget {
  final Player player;

  const HotbarUi({super.key, required this.player});

  Widget getIcon(Item? item) {
    if (item == null || item.iconPath == null) {
      return Text(
        item?.name ?? "",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        textAlign: TextAlign.center,
      );
    }
    return Image.asset("assets/images/${item.iconPath}");
  }

  @override
  Widget build(BuildContext context) {
    Widget valueListenableBuilder = ValueListenableBuilder<int>(
      valueListenable: player.inventory.activeSlotNotifier,
      builder: (context, activeIndex, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(player.inventory.capacity, (index) {
            final item = player.inventory.slots[index];
            final isActive = index == activeIndex;

            Border border = Border.all(
              color: isActive ? Colors.yellowAccent : Colors.grey.shade800,
              width: isActive ? 2 : 1,
            );

            return GestureDetector(
              onTap: () {
                player.inventory.setSlot(index);
              },
              child: Container(
                width: 54,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  border: border,
                ),
                child: Center(child: getIcon(item)),
              ),
            );
          }),
        );
      },
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: valueListenableBuilder,
      ),
    );
  }
}
