import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:survival_game/entities/player.dart';
import 'package:survival_game/obstacles/tree.dart';
import 'package:survival_game/terrain/world_generator.dart';

class SurvivalGame extends Forge2DGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  final Player player = Player();

  SurvivalGame() : super(gravity: Vector2.zero());

  @override
  Future<void> onLoad() async {
    maxTranslation = 8.0;
    await world.add(WorldGenerator());
    world.add(player);
    camera.viewfinder.zoom = 3.0;

    world.add(Tree(initialPosition: Vector2(32, 0)));
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    camera.viewfinder.position = player.position;
  }
}
