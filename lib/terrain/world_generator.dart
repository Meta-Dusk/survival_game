import 'package:fast_noise/fast_noise.dart' as fn;
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:survival_game/obstacles/tree.dart';
import 'package:survival_game/terrain/chunk.dart';
import 'package:survival_game/terrain/terrain_tile.dart';
import 'package:survival_game/terrain/world_component.dart';

enum RampRole { empty, left, center, right, single }

class WorldGenerator extends WorldComponent {
  final int chunkSize = 16;
  final double tileSize = 16.0;
  final Map<String, Chunk> _activeChunks = {};
  final double sandLevel = -0.2;
  final double grassLevel = 0.2;

  /// 1 means the chunk you are in, plus the 8 surrounding it
  final int viewDistance = 1;

  int _lastPlayerChunkX = -999;
  int _lastPlayerChunkY = -999;

  double getElevation(int worldX, int worldY) {
    return fn.PerlinNoise().singlePerlin2(
      worldSeed,
      worldX.toDouble() * 0.05,
      worldY.toDouble() * 0.05,
    );
  }

  int getZLevel(int worldX, int worldY) {
    double rawHeight = getElevation(worldX, worldY);

    if (rawHeight < sandLevel) return 0; // Water
    if (rawHeight < grassLevel) return 1; // Sand

    // rawHeight: 0.2 = Level 2 (Base Grass)
    // rawHeight: 0.4 = Level 3 (High Grass)
    // rawHeight: 0.6 = Level 4 (Mountain)
    return 2 + ((rawHeight - grassLevel) / 0.2).floor();
  }

  int getVisualZ(int worldX, int worldY) {
    int myZ = getZLevel(worldX, worldY);
    int n = getZLevel(worldX, worldY - 1);
    int e = getZLevel(worldX + 1, worldY);
    int s = getZLevel(worldX, worldY + 1);
    int w = getZLevel(worldX - 1, worldY);

    // --- UNIVERSAL HOLE FILLER ---
    int tallerNeighbors = 0;
    if (n > myZ) tallerNeighbors++;
    if (e > myZ) tallerNeighbors++;
    if (s > myZ) tallerNeighbors++;
    if (w > myZ) tallerNeighbors++;

    if (tallerNeighbors >= 3) {
      myZ++; // Instantly fill any 1x1 pothole to match its surroundings!
    }

    // --- UNIVERSAL SPIKE EROSION ---
    if (myZ >= 2) {
      int mask = 0;
      if (n >= myZ) mask += 1;
      if (e >= myZ) mask += 2;
      if (s >= myZ) mask += 4;
      if (w >= myZ) mask += 8;

      const validMasks = [3, 6, 7, 9, 11, 12, 13, 14, 15];
      if (!validMasks.contains(mask)) {
        myZ -= 1; // Gently erode 1 level down!
      }
    }

    // --- SAND EROSION ---
    if (myZ == 1) {
      int mask = 0;
      if (n >= 1) mask += 1;
      if (e >= 1) mask += 2;
      if (s >= 1) mask += 4;
      if (w >= 1) mask += 8;
      const validMasks = [3, 6, 7, 9, 11, 12, 13, 14, 15];
      if (!validMasks.contains(mask)) myZ = 0;
    }

    return myZ;
  }

  bool isHigh(int worldX, int worldY) {
    return getZLevel(worldX, worldY) >= 2;
  }

  bool _isWater(int worldX, int worldY) {
    return getVisualZ(worldX, worldY) == 0;
  }

  /// Uses a double modulo to get the correct sprite in a `SpriteArray2D`.
  Sprite getWaterSprite(int worldX, int worldY) {
    int patternX = (worldX % 4 + 4) % 4;
    int patternY = (worldY % 4 + 4) % 4;

    return waterSprites[patternY][patternX];
  }

  int _getSandMask(int worldX, int worldY) {
    int mask = 0;

    bool n = !_isWater(worldX, worldY - 1);
    bool e = !_isWater(worldX + 1, worldY);
    bool s = !_isWater(worldX, worldY + 1);
    bool w = !_isWater(worldX - 1, worldY);

    if (n) mask += 1; // North
    if (e) mask += 2; // East
    if (s) mask += 4; // South
    if (w) mask += 8; // West

    // If NOT fully surrounded by sand, return normal Edge/Outer Corner
    if (mask != 15) return mask;

    // If IS fully surrounded, check Diagonals for missing chunks
    bool nw = !_isWater(worldX - 1, worldY - 1);
    bool ne = !_isWater(worldX + 1, worldY - 1);
    bool se = !_isWater(worldX + 1, worldY + 1);
    bool sw = !_isWater(worldX - 1, worldY + 1);

    // If a diagonal is water, we return a custom ID
    if (!nw) return 16; // Missing Top-Left
    if (!ne) return 17; // Missing Top-Right
    if (!se) return 18; // Missing Bottom-Right
    if (!sw) return 19; // Missing Bottom-Left

    return 15; // Solid Center
  }

  bool _isValidCliffFormation(int worldX, int worldY) {
    int myZ = getZLevel(worldX, worldY);
    if (myZ < 2) return false;

    int mask = 0;
    if (getZLevel(worldX, worldY - 1) >= myZ) mask += 1;
    if (getZLevel(worldX + 1, worldY) >= myZ) mask += 2;
    if (getZLevel(worldX, worldY + 1) >= myZ) mask += 4;
    if (getZLevel(worldX - 1, worldY) >= myZ) mask += 8;

    // These are the ONLY masks that make up a proper, thick 9-slice shape.
    // (Corners, Edges, and the Interior 15).
    const validMasks = [3, 6, 7, 9, 11, 12, 13, 14, 15];
    return validMasks.contains(mask);
  }

  /// Checks if a single specific tile is a perfectly flat wall
  bool _isFlatWallAt(int x, int y) {
    int myVisualZ = getVisualZ(x, y);
    int northVisualZ = getVisualZ(x, y - 1);

    if (northVisualZ <= myVisualZ || northVisualZ < 2) return false;

    int northMask = 0;
    if (getVisualZ(x, (y - 1) - 1) >= northVisualZ) northMask += 1;
    if (getVisualZ(x + 1, y - 1) >= northVisualZ) northMask += 2;
    if (getVisualZ(x, (y - 1) + 1) >= northVisualZ) northMask += 4;
    if (getVisualZ(x - 1, y - 1) >= northVisualZ) northMask += 8;

    return northMask == 11;
  }

  /// Checks if a tile is the CENTER of a 3-wide flat wall!
  bool _isRampCenter(int x, int y) {
    // Must have flat walls at Left, Center, and Right
    if (!_isFlatWallAt(x - 1, y)) return false;
    if (!_isFlatWallAt(x, y)) return false;
    if (!_isFlatWallAt(x + 1, y)) return false;

    // The floor must be completely flat across all 3 tiles
    int centerZ = getVisualZ(x, y);
    if (getVisualZ(x - 1, y) != centerZ || getVisualZ(x + 1, y) != centerZ) {
      return false;
    }

    // The plateau above must be completely flat across all 3 tiles
    int centerNorthZ = getVisualZ(x, y - 1);
    if (getVisualZ(x - 1, y - 1) != centerNorthZ ||
        getVisualZ(x + 1, y - 1) != centerNorthZ) {
      return false;
    }

    // 10% chance to become a ramp
    return Object.hash(worldSeed, x, y) % 100 < 10;
  }

  bool _isRampAt(int x, int y) {
    int myVisualZ = getVisualZ(x, y);
    int northVisualZ = getVisualZ(x, y - 1);

    // Ramps only exist on walls!
    if (northVisualZ > myVisualZ && northVisualZ >= 2) {
      if (_isRampCenter(x, y)) return true; // Center of 3-wide
      if (_isRampCenter(x + 1, y)) return true; // Left of 3-wide
      if (_isRampCenter(x - 1, y)) return true; // Right of 3-wide

      // Single ramp fallback check
      if (_isFlatWallAt(x, y) && (Object.hash(worldSeed, x, y + 1) % 100 < 5)) {
        return true;
      }
    }
    return false;
  }

  // --- THE 2x2 PROP VALIDATOR ---
  bool _isValidTreeSpot(int startX, int startY) {
    if (startX % 2 != 0 || startY % 2 != 0) return false;

    int baseZ = getVisualZ(startX, startY);
    if (baseZ < 2) return false; // Must be grass

    // CHECK THE ENTIRE 2x2 FOOTPRINT
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        int checkX = startX + i;
        int checkY = startY + j;

        int myZ = getVisualZ(checkX, checkY);
        int northZ = getVisualZ(checkX, checkY - 1);

        // All 4 tiles must be perfectly flat (same elevation)
        if (myZ != baseZ) return false;

        // None of the 4 tiles can be hiding under a cliff
        if (northZ > myZ) return false;

        // None of the 4 tiles can be a ramp
        if (_isRampAt(checkX, checkY)) return false;
      }
    }

    return true;
  }

  /// Returns a list of Rects for cliff plateaus (the outlines).
  List<Rect>? _getHitboxesForMask(int mask) {
    const double step = 4.0;

    switch (mask) {
      // EDGES
      case 14: // Top Edge (Wall is at the Top)
        return [Rect.fromLTWH(0, 0, 16, step)];
      case 11: // Bottom Edge (Wall is at the Bottom)
        return [];
      case 7: // Left Edge (Wall is on the Left)
        return [Rect.fromLTWH(0, 0, step, 16)];
      case 13: // Right Edge (Wall is on the Right)
        return [Rect.fromLTWH(16 - step, 0, step, 16)];

      // OUTER CORNERS (Box2D staircases)
      case 9: // Bottom-Right Corner (Solid is Top-Left)
        return [
          Rect.fromLTWH(12, 0, step, 16),
          Rect.fromLTWH(8, 4, step, step),
          Rect.fromLTWH(4, 8, 8, step),
          Rect.fromLTWH(0, 12, 12, step),
        ];
      case 3: // Bottom-Left Corner (Solid is Top-Right)
        return [
          Rect.fromLTWH(0, 0, step, 16),
          Rect.fromLTWH(4, 4, 4, step),
          Rect.fromLTWH(4, 8, 8, step),
          Rect.fromLTWH(4, 12, 12, step),
        ];
      case 12: // Top-Right Corner (Solid is Bottom-Left)
        return [
          Rect.fromLTWH(0, 0, step, step),
          Rect.fromLTWH(4, 4, step, step),
          Rect.fromLTWH(8, 8, step, step),
          Rect.fromLTWH(12, 12, step, step),
        ];
      case 6: // Top-Left Corner (Solid is Bottom-Right)
        return [
          Rect.fromLTWH(12, 0, step, step),
          Rect.fromLTWH(8, 4, step, step),
          Rect.fromLTWH(4, 8, step, step),
          Rect.fromLTWH(0, 12, step, step),
        ];
      default: // Default hitbox
        return null;
    }
  }

  /// Returns a list of Rects for the cliff wall bases.
  List<Rect>? _getBaseHitboxesForMask(int northMask) {
    const double step = 4.0;

    switch (northMask) {
      case 11 || 15: // Flat wall base (Center Bottom)
        return [Rect.fromLTWH(0, 0, 16, 16)];

      case 9: // Bottom-Right Wall Base
        return [
          Rect.fromLTWH(0, 0, 16, step),
          Rect.fromLTWH(0, 4, 12, step),
          Rect.fromLTWH(0, 8, 8, step),
          Rect.fromLTWH(0, 12, 4, step),
        ];

      case 3: // Bottom-Left Wall Base
        return [
          Rect.fromLTWH(0, 0, 16, step),
          Rect.fromLTWH(4, 4, 12, step),
          Rect.fromLTWH(8, 8, 8, step),
          Rect.fromLTWH(12, 12, 4, step),
        ];

      default:
        return [Rect.fromLTWH(0, 0, 16, 16)];
    }
  }

  // --- THE CHUNK BUILDER ---
  void _generateChunk(int chunkX, int chunkY) {
    final chunkKey = '$chunkX,$chunkY';
    if (_activeChunks.containsKey(chunkKey)) return;

    // Chunk's top-left corner absolute world coordinates
    final startWorldX = chunkX * chunkSize;
    final startWorldY = chunkY * chunkSize;

    final chunk = Chunk(chunkX, chunkY);

    for (int x = 0; x < chunkSize; x++) {
      for (int y = 0; y < chunkSize; y++) {
        final worldX = startWorldX + x;
        final worldY = startWorldY + y;
        final absolutePos = Vector2(worldX * tileSize, worldY * tileSize);
        double height = getElevation(worldX, worldY);

        final Sprite baseSprite;
        Sprite? bgSprite;
        final TileType baseType;
        Vector2 terrainSize = Vector2.all(tileSize);
        int myVisualZ = getVisualZ(worldX, worldY);
        int northVisualZ = getVisualZ(worldX, worldY - 1);

        if (myVisualZ == 0) {
          // Water
          baseType = TileType.water;
          baseSprite = getWaterSprite(worldX, worldY);
        } else if (myVisualZ == 1) {
          // Sand
          baseType = TileType.sand;
          int mask = _getSandMask(worldX, worldY);
          baseSprite = getSandSpriteForMask(spriteSheet, mask, worldX, worldY);
          if (mask != 15) bgSprite = getWaterSprite(worldX, worldY);
        } else {
          // Grass Plateaus
          baseType = TileType.grass;
          baseSprite = getGrassSprite(worldX, worldY);
        }

        void spawnTile(TerrainTile tile) {
          chunk.tiles.add(tile);
          game.world.add(tile);
        }

        spawnTile(
          TerrainTile(
            sprite: baseSprite..rasterize(),
            bgSprite: bgSprite?..rasterize(),
            type: baseType,
            elevation: height,
            customHitboxes: baseType == TileType.water ? null : const [],
            initialPosition: absolutePos,
            tileDimension: terrainSize,
          ),
        );

        // Cliff Outline
        if (_isValidCliffFormation(worldX, worldY)) {
          int myZ = getVisualZ(worldX, worldY);
          int mask = 0;

          if (getVisualZ(worldX, worldY - 1) >= myZ) mask += 1;
          if (getVisualZ(worldX + 1, worldY) >= myZ) mask += 2;
          if (getVisualZ(worldX, worldY + 1) >= myZ) mask += 4;
          if (getVisualZ(worldX - 1, worldY) >= myZ) mask += 8;

          if (mask != 15) {
            int minNeighborZ = myZ;
            if (getZLevel(worldX, worldY - 1) < minNeighborZ) {
              minNeighborZ = getVisualZ(worldX, worldY - 1);
            }
            if (getVisualZ(worldX + 1, worldY) < minNeighborZ) {
              minNeighborZ = getVisualZ(worldX + 1, worldY);
            }
            if (getVisualZ(worldX, worldY + 1) < minNeighborZ) {
              minNeighborZ = getVisualZ(worldX, worldY + 1);
            }
            if (getVisualZ(worldX - 1, worldY) < minNeighborZ) {
              minNeighborZ = getVisualZ(worldX - 1, worldY);
            }
            bool dropsToSand = minNeighborZ <= 1;
            bool hasRampBelow = _isRampAt(worldX, worldY + 1);
            spawnTile(
              TerrainTile(
                sprite: getCliffSpriteForMask(
                  spriteSheet,
                  mask,
                  worldX,
                  worldY,
                  dropsToSand: dropsToSand,
                  hasRampBelow: hasRampBelow,
                )..rasterize(),
                type: TileType.cliff,
                elevation: height,
                customHitboxes: _getHitboxesForMask(mask),
                customPriority: absolutePos.y.toInt(),
                initialPosition: absolutePos,
                tileDimension: terrainSize,
              ),
            );
          }
        }

        // Cliff Walls and Ramps
        if (northVisualZ > myVisualZ && northVisualZ >= 2) {
          int heightDifference = northVisualZ - myVisualZ;
          RampRole rampRole = RampRole.empty;

          if (_isRampCenter(worldX, worldY)) {
            rampRole = RampRole.center;
          } else if (_isRampCenter(worldX + 1, worldY)) {
            rampRole = RampRole.left;
          } else if (_isRampCenter(worldX - 1, worldY)) {
            rampRole = RampRole.right;
          } else if (_isFlatWallAt(worldX, worldY)) {
            if (Object.hash(worldSeed, worldX, worldY + 1) % 100 < 5) {
              rampRole = RampRole.single;
            }
          }

          if (rampRole != RampRole.empty) {
            Sprite rampSprite;

            switch (rampRole) {
              case RampRole.left:
                rampSprite = spriteSheet.getSprite(4, 15);
              case RampRole.center:
                rampSprite = spriteSheet.getSprite(4, 16);
              case RampRole.right:
                rampSprite = spriteSheet.getSprite(4, 17);
              default:
                rampSprite = spriteSheet.getSprite(4, 14);
            }

            spawnTile(
              TerrainTile(
                sprite: rampSprite..rasterize(),
                type: TileType.grass,
                customHitboxes: const [],
                customPriority: (absolutePos.y + tileSize).toInt(),
                initialPosition: absolutePos,
                tileDimension: terrainSize,
                elevation: height,
              ),
            );

            // SPAWN STANDARD WALL
          } else {
            int northMask = 0;
            if (getVisualZ(worldX, (worldY - 1) - 1) >= northVisualZ) {
              northMask += 1;
            }
            if (getVisualZ(worldX + 1, worldY - 1) >= northVisualZ) {
              northMask += 2;
            }
            if (getVisualZ(worldX, (worldY - 1) + 1) >= northVisualZ) {
              northMask += 4;
            }
            if (getVisualZ(worldX - 1, worldY - 1) >= northVisualZ) {
              northMask += 8;
            }

            bool sitsOnSand = myVisualZ <= 1;

            spawnTile(
              TerrainTile(
                sprite: getCliffBaseSprite(spriteSheet, northMask, sitsOnSand)
                  ..rasterize(),
                type: TileType.cliff,
                customHitboxes: _getBaseHitboxesForMask(northMask),
                customPriority: (absolutePos.y + tileSize).toInt(),
                initialPosition: absolutePos,
                tileDimension: terrainSize,
                elevation: height,
                stackCount: heightDifference,
              ),
            );
          }
        }

        // PROPS
        if (_isValidTreeSpot(worldX, worldY)) {
          bool spawnTree =
              Object.hash(worldSeed, worldX, worldY, 'tree') % 100 < 15;

          if (spawnTree) {
            final centerPos = Vector2(
              (worldX * tileSize) + tileSize,
              (worldY * tileSize) + tileSize,
            );

            final tree = Tree(initialPosition: centerPos);

            game.world.add(tree);
            chunk.tiles.add(tree);
          }
        }
      }
    }

    _activeChunks[chunkKey] = chunk;
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
          chunk.unload();
          return true;
        }
        return false;
      });
    }
  }
}
