/// Centralised asset paths. Every image in the app is referenced through this
/// class — never inline a raw 'assets/...' string inside a widget.
class AppAssets {
  const AppAssets._();

  static const String icon = 'assets/icon_1024.png';
  static const String bgLoader = 'assets/bg_loader.png';
  static const String bgMenu = 'assets/bg_menu.png';
  static const String bgGame = 'assets/bg_game.png';
  static const String spriteMosaicHero = 'assets/sprite_mosaic_hero.png';
  static const String spriteNodeGlow = 'assets/sprite_node_glow.png';
  static const String spriteShardTriangle = 'assets/sprite_shard_triangle.png';
  static const String buttonCta = 'assets/button_cta.png';
}
