import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:survival_game/entities/player.dart';
import 'package:survival_game/obstacles/tree.dart';
import 'package:survival_game/terrain/world_generator.dart';

class SurvivalGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  final Player player = Player();

  @override
  Future<void> onLoad() async {
    await world.add(WorldGenerator());
    // debugMode = true;
    world.add(player);
    camera.viewfinder.zoom = 3.0;

    final dummyTree = Tree(position: player.position + Vector2(32, 0));
    world.add(dummyTree);
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    camera.viewfinder.position = player.position;
  }
}
