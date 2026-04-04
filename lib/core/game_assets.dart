import 'package:survival_game/components/player_component.dart';

/// Dataclass for asset paths `String` literals.
class Assets {
  static const entities = _Entities();
  static const elements = _Elements();
  static const ui = _Ui();
  static const tilesets = _Tilesets();
}

extension FlutterAssetPath on String {
  String get flutterPath => "assets/images/$this";
}

/// A base class that generates standard paths based on a given prefix.
abstract class PlayerAnimationSet {
  /// An example of [path] would be: "spritesheets/entities/human/"
  final String path;

  /// The [prefix] must be a single word.
  final String prefix;

  const PlayerAnimationSet({required this.path, required this.prefix});

  String get attacking => "${path}attack/${prefix}_attack_strip10.png";
  String get carrying => "${path}carry/${prefix}_carry_strip8.png";
  String get casting => "${path}cast/${prefix}_casting_strip15.png";
  String get catching => "${path}catch/${prefix}_caught_strip10.png";
  String get chopping => "${path}chop/${prefix}_axe_strip10.png";
  String get death => "${path}death/${prefix}_death_strip13.png";
  String get digging => "${path}dig/${prefix}_dig_strip13.png";
  String get hammering => "${path}hammer/${prefix}_hamering_strip23.png";
  String get hurt => "${path}hurt/${prefix}_hurt_strip8.png";
  String get idle => "${path}idle/${prefix}_idle_strip9.png";
  String get interacting => "${path}interact/${prefix}_doing_strip8.png";
  String get jumping => "${path}jump/${prefix}_jump_strip9.png";
  String get mining => "${path}mine/${prefix}_mining_strip10.png";
  String get reeling => "${path}reel/${prefix}_reeling_strip13.png";
  String get rolling => "${path}roll/${prefix}_roll_strip10.png";
  String get running => "${path}run/${prefix}_run_strip8.png";
  String get swimming => "${path}swim/${prefix}_swimming_strip12.png";
  String get waiting => "${path}wait/${prefix}_waiting_strip9.png";
  String get walking => "${path}walk/${prefix}_walk_strip8.png";
  String get watering => "${path}water/${prefix}_watering_strip5.png";

  Map<PlayerState, String> get asMap => {
    PlayerState.attacking: attacking,
    PlayerState.carrying: carrying,
    PlayerState.casting: casting,
    PlayerState.catching: catching,
    PlayerState.chopping: chopping,
    PlayerState.death: death,
    PlayerState.digging: digging,
    PlayerState.hammering: hammering,
    PlayerState.hurt: hurt,
    PlayerState.idle: idle,
    PlayerState.interacting: interacting,
    PlayerState.jumping: jumping,
    PlayerState.mining: mining,
    PlayerState.reeling: reeling,
    PlayerState.rolling: rolling,
    PlayerState.running: running,
    PlayerState.swimming: swimming,
    PlayerState.waiting: waiting,
    PlayerState.walking: walking,
    PlayerState.watering: watering,
  };
}

/// Helper for const base path directories.
class AssetBasePaths {
  static const String human = "spritesheets/entities/human/";
  static const String goblin = "spritesheets/entities/goblin/";
  static const String skeleton = "spritesheets/entities/skeleton/";
}

// * --- Nested Categories ---

class _Entities {
  const _Entities();
  final player = const _PlayerAssets();
}

class _PlayerAssets {
  const _PlayerAssets();
  final base = const _PlayerBaseAssets();
  final hair = const _PlayerHairAssets();
  final tools = const _PlayerToolAssets();
}

class _PlayerHairAssets {
  const _PlayerHairAssets();
  final bowlHair = const _BowlHair();
}

class _Elements {
  const _Elements();
  final plants = const _Plants();
  final animals = const _Animals();
  final other = const _Other();
  final vfx = const _Vfx();
  final crops = const _Crops();
  // final items = const
}

class _Vfx {
  const _Vfx();
  final chimneySmoke = const _ChimneySmoke();
  final fire = const _Fire();
  final glint = const _Glint();
  final organic = const _Organic();
}

class _Ui {
  const _Ui();
  final nineSlice = const _NineSlice();
  final elements = const _UiElements();
  final titles = const _Titles();
}

// * --- Asset Definitions ---

// * Player Related
class _PlayerBaseAssets extends PlayerAnimationSet {
  const _PlayerBaseAssets() : super(path: AssetBasePaths.human, prefix: "base");
}

// * Player Hairstyles
class _BowlHair extends PlayerAnimationSet {
  const _BowlHair() : super(path: AssetBasePaths.human, prefix: "bowlhair");
}

class _PlayerToolAssets extends PlayerAnimationSet {
  const _PlayerToolAssets()
    : super(path: AssetBasePaths.human, prefix: "tools");
}

// * Single Animation Sprites
class _Plants {
  const _Plants();

  final String decoTree01 =
      "spritesheets/elements/plants/spr_deco_tree_01_strip4.png";
  final String decoTree02 =
      "spritesheets/elements/plants/spr_deco_tree_02_strip4.png";
  final String decoMushroomBlue01 =
      "spritesheets/elements/plants/spr_deco_mushroom_blue_01_strip4.png";
  final String decoMushroomBlue02 =
      "spritesheets/elements/plants/spr_deco_mushroom_blue_02_strip4.png";
  final String decoMushroomBlue03 =
      "spritesheets/elements/plants/spr_deco_mushroom_blue_03_strip4.png";
  final String decoMushroomRed01 =
      "spritesheets/elements/plants/spr_deco_mushroom_red_01_strip4.png";
}

class _Animals {
  const _Animals();

  final String decoBird01 =
      "spritesheets/elements/animals/spr_deco_bird_01_strip4.png";
  final String decoBlinking =
      "spritesheets/elements/animals/spr_deco_blinking_strip12.png";
  final String decoChicken01 =
      "spritesheets/elements/animals/spr_deco_chicken_01_strip4.png";
  final String decoCow =
      "spritesheets/elements/animals/spr_deco_cow_strip4.png";
  final String decoDuck01 =
      "spritesheets/elements/animals/spr_deco_duck_01_strip4.png";
  final String decoPig01 =
      "spritesheets/elements/animals/spr_deco_pig_01_strip4.png";
  final String decoSheep01 =
      "spritesheets/elements/animals/spr_deco_sheep_01_strip4.png";
}

class _Other {
  const _Other();

  final String decoOracleLand = "elements/other/spr_deco_coracle_land.png";
  final String decoCoracle =
      "spritesheets/elements/other/spr_deco_coracle_strip4.png";
  final String decoWindmill =
      "spritesheets/elements/other/spr_deco_windmill_strip9.png";
  final String decoWindmillWithShadow =
      "spritesheets/elements/other/spr_deco_windmill_withshadow_strip9.png";
  final String decoWindmillShadow =
      "spritesheets/elements/other/spr_deco_windmillshadow_strip9.png";
}

// * VFX
class _ChimneySmoke {
  const _ChimneySmoke();

  final String spr01 =
      "spritesheets/elements/vfx/chimney_smoke/chimneysmoke_01_strip30.png";
  final String spr02 =
      "spritesheets/elements/vfx/chimney_smoke/chimneysmoke_02_strip30.png";
  final String spr03 =
      "spritesheets/elements/vfx/chimney_smoke/chimneysmoke_03_strip30.png";
  final String spr04 =
      "spritesheets/elements/vfx/chimney_smoke/chimneysmoke_04_strip30.png";
  final String spr05 =
      "spritesheets/elements/vfx/chimney_smoke/chimneysmoke_05_strip30.png";
}

class _Fire {
  const _Fire();

  final String spr01 =
      "spritesheets/elements/vfx/fire/spr_deco_fire_01_strip4.png";
  final String spr02 =
      "spritesheets/elements/vfx/fire/spr_deco_fire_02_strip4.png";
}

class _Glint {
  const _Glint();

  final String spr01 =
      "spritesheets/elements/vfx/glint/spr_deco_glint_01_strip6.png";
  final String spr02 =
      "spritesheets/elements/vfx/glint/spr_deco_glint_02_strip4.png";
}

class _Organic {
  const _Organic();

  final String leavesHit =
      "spritesheets/elements/vfx/organic/leaves_hit_strip10.png";
}

class _Crops {
  const _Crops();
  final String wood = "elements/crops/wood.png";
  final String egg = "elements/crops/egg.png";
}

//* UI Elements
class _NineSlice {
  const _NineSlice();
  final String dtBox = "ui/nine_slice/dt_box_9slice.png";
  final String ltBox = "ui/nine_slice/lt_box_9slice.png";
  final String wBox = "ui/nine_slice/w_box_9slice.png";
}

class _UiElements {
  const _UiElements();
  final String arrowLeft = "ui/elements/arrow_left.png";
}

class _Titles {
  const _Titles();
  final String mainMenuTitle = "ui/titles/jasg_title_render2.png";
}

//* Tilesets
class _Tilesets {
  const _Tilesets();
  final String main = "tilesets/spr_tileset_sunnysideworld_16px.png";
}
