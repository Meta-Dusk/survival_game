import 'package:flame/components.dart';
import 'package:survival_game/terrain/terrain_tile.dart';

class Chunk extends PositionComponent {
  final int chunkX;
  final int chunkY;
  final List<TerrainTile> tiles = [];

  Chunk(this.chunkX, this.chunkY);

  void unload() {
    for (var tile in tiles) {
      tile.removeFromParent();
    }
  }
}
