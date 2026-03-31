import 'dart:async';
import 'dart:math';

import 'package:fast_noise/fast_noise.dart' as fn;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';
import 'package:survival_game/terrain/chunk.dart';
import 'package:survival_game/terrain/terrain_tile.dart';

class WorldGenerator extends Component with HasGameReference<SurvivalGame> {
  WorldGenerator() : super(priority: -9999);

  final int chunkSize = 16;
  final double tileSize = 16.0;
  final Map<String, Chunk> _activeChunks = {};

  late Sprite grassSprite;
  late Sprite waterSprite;
  late SpriteSheet spriteSheet;

  final int worldSeed = Random().nextInt(9999);
  int _lastPlayerChunkX = -999;
  int _lastPlayerChunkY = -999;

  @override
  Future<void> onLoad() async {
    final tilesetImage = await game.images.load(Assets.tilesets.main);
    spriteSheet = SpriteSheet(image: tilesetImage, srcSize: Vector2.all(16));
    grassSprite = spriteSheet.getSprite(3, 0);
    waterSprite = spriteSheet.getSprite(1, 4);
  }

  double getElevation(int worldX, int worldY) {
    // fast_noise has a single2D function to check exact coordinates!
    return fn.PerlinNoise().singlePerlin2(
      worldSeed,
      worldX.toDouble() * 0.05,
      worldY.toDouble() * 0.05,
    );
  }

  bool isHigh(int worldX, int worldY) {
    return getElevation(worldX, worldY) > 0.4;
  }

  bool _isValidCliffFormation(int worldX, int worldY) {
    if (!isHigh(worldX, worldY)) return false;

    int mask = 0;
    if (isHigh(worldX, worldY - 1)) mask += 1;
    if (isHigh(worldX + 1, worldY)) mask += 2;
    if (isHigh(worldX, worldY + 1)) mask += 4;
    if (isHigh(worldX - 1, worldY)) mask += 8;

    // These are the ONLY masks that make up a proper, thick 9-slice shape.
    // (Corners, Edges, and the Interior 15).
    const validMasks = [3, 6, 7, 9, 11, 12, 13, 14, 15];
    return validMasks.contains(mask);
  }

  List<RectangleHitbox>? _getHitboxesForMask(int mask) {
    double t = 6.0; // Wall thickness
    const double stepHeight = 4.0;

    switch (mask) {
      case 14: // Top Edge (Wall is at the Top)
        return [RectangleHitbox(position: Vector2(0, 0), size: Vector2(16, t))];
      case 11: // Bottom Edge (Wall is at the Bottom)
        return [
          RectangleHitbox(position: Vector2(0, 16 - t), size: Vector2(16, t)),
        ];
      case 7: // Left Edge (Wall is on the Left)
        return [RectangleHitbox(position: Vector2(0, 0), size: Vector2(t, 16))];
      case 13: // Right Edge (Wall is on the Right)
        return [
          RectangleHitbox(position: Vector2(16 - t, 0), size: Vector2(t, 16)),
        ];
      case 9:
        // Bottom-Right Corner (Solid part is Top-Left)
        // Steps get narrower as they go down
        return [
          RectangleHitbox(position: Vector2(8, 0), size: Vector2(t, 8)),
          RectangleHitbox(
            position: Vector2(0, 8),
            size: Vector2(10, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(0, 12),
            size: Vector2(5, stepHeight),
          ),
        ];
      case 3:
        // Bottom-Left Corner (Solid part is Top-Right)
        // Steps get narrower and shift to the right as they go down
        return [
          RectangleHitbox(position: Vector2(8, 0), size: Vector2(t, 8)),
          RectangleHitbox(
            position: Vector2(6, 8),
            size: Vector2(10, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(11, 12),
            size: Vector2(5, stepHeight),
          ),
        ];
      case 12:
        // Top-Right Corner (Solid part is Bottom-Left)
        // Steps get wider as they go down
        return [
          RectangleHitbox(
            position: Vector2(0, 0),
            size: Vector2(4, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(0, 4),
            size: Vector2(8, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(0, 8),
            size: Vector2(12, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(0, 12),
            size: Vector2(16, stepHeight),
          ),
        ];
      case 6:
        // Top-Left Corner (Solid part is Bottom-Right)
        // Steps get wider and start further left as they go down
        return [
          RectangleHitbox(
            position: Vector2(12, 0),
            size: Vector2(4, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(8, 4),
            size: Vector2(8, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(4, 8),
            size: Vector2(12, stepHeight),
          ),
          RectangleHitbox(
            position: Vector2(0, 12),
            size: Vector2(16, stepHeight),
          ),
        ];
      default:
        return null;
    }
  }

  Sprite _getCliffSpriteForMask(SpriteSheet sheet, int mask) {
    switch (mask) {
      // OUTER CORNERS
      case 6:
        // Top-Left Corner (East & South are high)
        return sheet.getSprite(5, 9);
      case 12:
        // Top-Right Corner (South & West are high)
        return sheet.getSprite(5, 8);
      case 3:
        // Bottom-Left Corner (North & East are high)
        return sheet.getSprite(4, 6);
      case 9:
        // Bottom-Right Corner (North & West are high)
        return sheet.getSprite(4, 7);

      // FLAT EDGES
      case 14:
        // Top Edge (East, South, West are high)
        return sheet.getSprite(3, 4);
      case 7:
        // Left Edge (North, East, South are high)
        return sheet.getSprite(3, 6);
      case 13:
        // Right Edge (North, South, West are high)
        return sheet.getSprite(4, 3);
      case 11:
        // Bottom Edge (North, East, West are high)
        return sheet.getSprite(4, 5);
      default:
        // Default to a center cliff or basic rock
        return sheet.getSprite(4, 11);
    }
  }

  /// These are the masks for the tiles above the current tile.
  Sprite _getCliffBaseSprite(SpriteSheet sheet, int northMask) {
    switch (northMask) {
      case 3:
        // The tile above is a Bottom-Left Corner
        return sheet.getSprite(6, 10); // Replace with bottom-left wall face
      case 9:
        // The tile above is a Bottom-Right Corner
        return sheet.getSprite(6, 12); // Replace with bottom-right wall face
      case 11 || 15:
        // The tile above is a Flat Bottom Edge
        return sheet.getSprite(3, 11); // Replace with flat center wall face
      default:
        // Fallback for 1-tile wide pillars
        return sheet.getSprite(0, 0);
    }
  }

  // --- THE CHUNK BUILDER ---
  void _generateChunk(int chunkX, int chunkY) {
    final chunkKey = '$chunkX,$chunkY';
    if (_activeChunks.containsKey(chunkKey)) return; // Already loaded!

    // Calculate the absolute world coordinates for this chunk's top-left corner
    final startWorldX = chunkX * chunkSize;
    final startWorldY = chunkY * chunkSize;

    final chunk = Chunk(chunkX, chunkY)
      ..position = Vector2(startWorldX * tileSize, startWorldY * tileSize)
      ..size = Vector2(chunkSize * tileSize, chunkSize * tileSize);

    for (int x = 0; x < chunkSize; x++) {
      for (int y = 0; y < chunkSize; y++) {
        final worldX = startWorldX + x;
        final worldY = startWorldY + y;
        final localPos = Vector2(x * tileSize, y * tileSize);
        double height = getElevation(worldX, worldY);
        Sprite baseSprite = (height < -0.2) ? waterSprite : grassSprite;
        TileType baseType = (height < -0.2) ? TileType.water : TileType.grass;
        Vector2 terrainSize = Vector2.all(tileSize);

        chunk.add(
          TerrainTile(
            sprite: baseSprite..rasterize(),
            type: baseType,
            position: localPos,
            size: terrainSize,
          ),
        );

        if (_isValidCliffFormation(worldX, worldY)) {
          int mask = 0;
          if (_isValidCliffFormation(worldX, worldY - 1)) mask += 1;
          if (_isValidCliffFormation(worldX + 1, worldY)) mask += 2;
          if (_isValidCliffFormation(worldX, worldY + 1)) mask += 4;
          if (_isValidCliffFormation(worldX - 1, worldY)) mask += 8;

          if (mask != 15) {
            chunk.add(
              TerrainTile(
                sprite: _getCliffSpriteForMask(spriteSheet, mask)..rasterize(),
                type: TileType.cliff,
                customHitboxes: _getHitboxesForMask(mask),
                position: localPos,
                size: terrainSize,
              )..debugMode = true,
            );
          }
        } else if (_isValidCliffFormation(worldX, worldY - 1)) {
          int northMask = 0;
          if (_isValidCliffFormation(worldX, worldY - 2)) northMask += 1;
          if (_isValidCliffFormation(worldX + 1, worldY - 1)) northMask += 2;
          if (_isValidCliffFormation(worldX - 1, worldY - 1)) northMask += 8;

          chunk.add(
            TerrainTile(
              sprite: _getCliffBaseSprite(spriteSheet, northMask)..rasterize(),
              type: TileType.cliff,
              customHitboxes: _getHitboxesForMask(northMask),
              position: localPos,
              size: terrainSize,
            ),
          );
        }
      }
    }

    _activeChunks[chunkKey] = chunk;
    add(chunk);
  }

  // --- THE MANAGER LOOP ---
  @override
  void update(double dt) {
    super.update(dt);

    // Find out which chunk the player is currently standing in
    final player = game.player;
    final playerChunkX = (player.position.x / (chunkSize * tileSize)).floor();
    final playerChunkY = (player.position.y / (chunkSize * tileSize)).floor();

    // Only run the heavy chunk-loading math if the player crosses a chunk border!
    if (playerChunkX != _lastPlayerChunkX ||
        playerChunkY != _lastPlayerChunkY) {
      _lastPlayerChunkX = playerChunkX;
      _lastPlayerChunkY = playerChunkY;

      // Define the "View Distance" (1 means the chunk you are in, plus the 8 surrounding it)
      const viewDistance = 1;
      final Set<String> chunksToKeep = {};

      // Load nearby chunks
      for (int x = -viewDistance; x <= viewDistance; x++) {
        for (int y = -viewDistance; y <= viewDistance; y++) {
          final targetX = playerChunkX + x;
          final targetY = playerChunkY + y;
          chunksToKeep.add('$targetX,$targetY');
          _generateChunk(targetX, targetY);
        }
      }

      // Unload chunks that are too far away
      _activeChunks.removeWhere((key, chunk) {
        if (!chunksToKeep.contains(key)) {
          chunk.removeFromParent(); // Deletes the chunk and all its tiles!
          return true;
        }
        return false;
      });
    }
  }
}
