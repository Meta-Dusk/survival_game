import 'package:flame/components.dart';

class Chunk extends PositionComponent {
  final int chunkX;
  final int chunkY;
  final List<Component> tiles = [];

  Chunk(this.chunkX, this.chunkY);

  void unload() {
    for (var tile in tiles) {
      if (!tile.isMounted) continue;
      tile.removeFromParent();
    }
    tiles.clear();
    removeFromParent();
  }
}
