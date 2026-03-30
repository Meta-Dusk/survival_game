import 'package:flutter/material.dart';
import 'package:survival_game/core/game_overlays.dart';
import 'package:survival_game/game.dart';

class MainMenu extends StatelessWidget {
  final SurvivalGame game;

  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    Widget playButton = ElevatedButton(
      onPressed: () {
        game.overlays.remove(GameOverlays.mainMenu);
        game.resumeEngine();
        game.overlays.add(GameOverlays.hotbar);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orangeAccent.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
      child: const Text(
        "PLAY",
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    Widget titleText = const Text(
      "SURVIVAL GAME",
      style: TextStyle(
        color: Colors.white,
        fontSize: 64,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 0, color: Colors.grey, offset: Offset(4, 4)),
        ],
      ),
    );

    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [titleText, const SizedBox(height: 80), playButton],
        ),
      ),
    );
  }
}
