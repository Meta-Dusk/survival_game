import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_overlays.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/overlays/hotbar_ui.dart';
import 'package:survival_game/overlays/main_menu.dart';

void main() {
  final game = SurvivalGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            GameOverlays.mainMenu: (BuildContext context, SurvivalGame game) {
              return MainMenu(game: game);
            },
            GameOverlays.hotbar: (BuildContext context, SurvivalGame game) {
              return HotbarUi(player: game.player);
            },
          },
          initialActiveOverlays: const [GameOverlays.mainMenu],
        ),
      ),
    ),
  );
}
