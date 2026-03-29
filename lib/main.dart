import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/hotbar_ui.dart';

void main() {
  final game = SurvivalGame();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            "HotbarOverlay": (BuildContext context, SurvivalGame game) {
              return HotbarUi(player: game.player);
            },
          },
          initialActiveOverlays: const ["HotbarOverlay"],
        ),
      ),
    ),
  );
}
