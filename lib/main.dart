import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:survival_game/core/game_fonts.dart';
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
        backgroundColor: Colors.black,
        body: GameWidget<SurvivalGame>(
          game: game,
          overlayBuilderMap: {
            GameOverlays.mainMenu: (context, game) => MainMenu(game: game),
            GameOverlays.hotbar: (context, game) =>
                HotbarUi(player: game.player),
          },
          initialActiveOverlays: const [GameOverlays.mainMenu],
          loadingBuilder: (context) => LoadingWidget(),
        ),
      ),
    ),
  );
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 24),
          const Text(
            "Setting up Game...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: FontFamilies.pixelifySans,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
