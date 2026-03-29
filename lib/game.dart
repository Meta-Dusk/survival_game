import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:survival_game/player.dart';
import 'package:survival_game/tree.dart';

class SurvivalGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  final Player player = Player();

  @override
  Future<void> onLoad() async {
    // debugMode = true;
    world.add(player);
    camera.viewfinder.zoom = 5.0;

    final dummyTree = Tree(position: player.position + Vector2(32, 0));
    world.add(dummyTree);
  }

  @override
  void update(double dt) {
    super.update(dt);
    camera.viewfinder.position = player.position;
  }
}
