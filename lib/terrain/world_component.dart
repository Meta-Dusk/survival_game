import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:survival_game/core/game_assets.dart';
import 'package:survival_game/game.dart';

typedef SpriteArray2D = List<List<Sprite>>;

class WorldComponent extends Component with HasGameReference<SurvivalGame> {
  late List<Sprite> grassSprites;
  late SpriteArray2D waterSprites;
  late List<Sprite> sandSprites;
  late SpriteSheet spriteSheet;
  final int worldSeed = Random().nextInt(9999);

  @override
  Future<void> onLoad() async {
    final tilesetImage = await game.images.load(Assets.tilesets.main);
    spriteSheet = SpriteSheet(image: tilesetImage, srcSize: Vector2.all(16));

    grassSprites = [
      spriteSheet.getSprite(1, 1),
      spriteSheet.getSprite(1, 2),
      spriteSheet.getSprite(2, 1),
      spriteSheet.getSprite(2, 2),
      spriteSheet.getSprite(2, 3),
      spriteSheet.getSprite(2, 4),
      spriteSheet.getSprite(2, 5),
      spriteSheet.getSprite(2, 6),
      spriteSheet.getSprite(3, 0),
      spriteSheet.getSprite(3, 1),
      spriteSheet.getSprite(3, 2),
      spriteSheet.getSprite(3, 3),
      spriteSheet.getSprite(3, 5),
      spriteSheet.getSprite(3, 7),
      spriteSheet.getSprite(4, 1),
      spriteSheet.getSprite(4, 2),
    ];

    final int startX = 11;
    final int startY = 18;

    waterSprites = List.generate(4, (y) {
      return List.generate(4, (x) {
        return spriteSheet.getSprite(startY + y, startX + x);
      });
    });

    sandSprites = [
      spriteSheet.getSprite(1, 5),
      spriteSheet.getSprite(1, 7),
      spriteSheet.getSprite(1, 8),
      spriteSheet.getSprite(1, 9),
    ];
  }

  Sprite getGrassSprite(int worldX, int worldY) {
    int tileHash = Object.hash(worldSeed, worldX, worldY);
    final random = Random(tileHash);
    if (random.nextDouble() > 0.50) {
      return grassSprites.first;
    } else {
      int variationIndex = 1 + random.nextInt(grassSprites.length - 1);
      return grassSprites[variationIndex];
    }
  }

  Sprite getSandSprite(int worldX, int worldY) {
    int tileHash = Object.hash(worldSeed, worldX, worldY);
    final random = Random(tileHash);
    if (random.nextDouble() > 0.50) {
      return sandSprites.first;
    } else {
      int variationIndex = 1 + random.nextInt(sandSprites.length - 1);
      return sandSprites[variationIndex];
    }
  }

  /// Masks for auto-tiling sand sprites.
  Sprite getSandSpriteForMask(
    SpriteSheet spriteSheet,
    int mask,
    int worldX,
    int worldY,
  ) {
    switch (mask) {
      // EDGES
      case 14:
        return spriteSheet.getSprite(28, 6); // Top Edge
      case 13:
        return spriteSheet.getSprite(30, 8); // Right Edge
      case 11:
        return spriteSheet.getSprite(32, 6); // Bottom Edge
      case 7:
        return spriteSheet.getSprite(30, 4); // Left Edge

      // CORNERS
      case 6:
        return spriteSheet.getSprite(28, 5); // Top-Left
      case 12:
        return spriteSheet.getSprite(28, 7); // Top-Right
      case 9:
        return spriteSheet.getSprite(32, 7); // Bottom-Right
      case 3:
        return spriteSheet.getSprite(32, 5); // Bottom-Left

      // INNER CORNERS
      case 16:
        return spriteSheet.getSprite(29, 5); // Inner Top-Left
      case 17:
        return spriteSheet.getSprite(29, 7); // Inner Top-Right
      case 18:
        return spriteSheet.getSprite(31, 7); // Inner Bottom-Right
      case 19:
        return spriteSheet.getSprite(31, 5); // Inner Bottom-Left

      case 15:
        return spriteSheet.getSprite(30, 6); // Solid Center

      default:
        return getSandSprite(worldX, worldY); // Fallback
    }
  }

  /// These are the masks for the flat-tops of cliffs.
  Sprite getCliffSpriteForMask(
    SpriteSheet spriteSheet,
    int mask,
    int worldX,
    int worldY, {
    bool dropsToSand = false,
    bool hasRampBelow = false,
  }) {
    if (mask == 11 && hasRampBelow) return getGrassSprite(worldX, worldY);

    switch (mask) {
      // OUTER CORNERS
      case 6:
        return dropsToSand
            ? spriteSheet.getSprite(5, 7)
            : spriteSheet.getSprite(5, 9); // Top-Left Corner
      case 12:
        return dropsToSand
            ? spriteSheet.getSprite(5, 6)
            : spriteSheet.getSprite(5, 8); // Top-Right Corner
      case 3:
        return spriteSheet.getSprite(4, 6); // Bottom-Left Corner
      case 9:
        return spriteSheet.getSprite(4, 7); // Bottom-Right Corner

      // FLAT EDGES
      case 14:
        return spriteSheet.getSprite(3, 4); // Top Edge
      case 7:
        return spriteSheet.getSprite(3, 6); // Left Edge
      case 13:
        return spriteSheet.getSprite(4, 3); // Right Edge
      case 11:
        return spriteSheet.getSprite(4, 5); // Bottom Edge
      default:
        return spriteSheet.getSprite(4, 11); // Center
    }
  }

  /// These are the masks for the tiles above the current cliff tile.
  Sprite getCliffBaseSprite(SpriteSheet sheet, int northMask, bool sitsOnSand) {
    switch (northMask) {
      case 3:
        // The tile above is a Bottom-Left Corner
        return sitsOnSand
            ? sheet.getSprite(5, 10)
            : sheet.getSprite(6, 10); // Replace with bottom-left wall face
      case 9:
        // The tile above is a Bottom-Right Corner
        return sitsOnSand
            ? sheet.getSprite(5, 12)
            : sheet.getSprite(6, 12); // Replace with bottom-right wall face
      case 11 || 15:
        // The tile above is a Flat Bottom Edge
        return sheet.getSprite(3, 11); // Replace with flat center wall face
      default:
        // Fallback for 1-tile wide pillars
        return sitsOnSand ? sheet.getSprite(3, 11) : sheet.getSprite(6, 11);
    }
  }
}
