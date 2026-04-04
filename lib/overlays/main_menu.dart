import 'package:flutter/material.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/core/game_fonts.dart';
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
          fontSize: 32,
          fontFamily: FontFamilies.lief,
        ),
      ),
    );

    Widget title = Image.asset(Assets.ui.titles.mainMenuTitle.flutterPath);

    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [title, const SizedBox(height: 80), playButton],
        ),
      ),
    );
  }
}
