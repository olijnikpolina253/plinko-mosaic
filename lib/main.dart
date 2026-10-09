import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/game_config.dart';
import 'game/mosaic_engine.dart';
import 'game/progress_store.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/menu_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: PMColors.bgBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PlinkoMosaicApp());
}

/// Screen state machine. `gameOver` is mandatory — without a separate result
/// surface the capture agent records identical frames.
enum Screen { loader, menu, game, gameOver }

class PlinkoMosaicApp extends StatelessWidget {
  const PlinkoMosaicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plinko Mosaic',
      debugShowCheckedModeBanner: false,
      theme: buildPMTheme(),
      home: const PlinkoMosaicRoot(),
    );
  }
}

class PlinkoMosaicRoot extends StatefulWidget {
  const PlinkoMosaicRoot({super.key});

  @override
  State<PlinkoMosaicRoot> createState() => _PlinkoMosaicRootState();
}

class _PlinkoMosaicRootState extends State<PlinkoMosaicRoot> {
  Screen _screen = Screen.loader;
  int _levelId = 1;

  /// Bumped on every entry into the game so PLAY AGAIN remounts a fresh board.
  int _round = 0;

  GameResult? _result;

  void _goMenu() {
    setState(() => _screen = Screen.menu);
  }

  void _startLevel(int levelId) {
    setState(() {
      _levelId = levelId;
      _round++;
      _screen = Screen.game;
    });
  }

  void _onGameOver(GameResult result) {
    ProgressStore.instance.record(
      levelId: result.levelId,
      stars: result.stars,
      accuracy: result.accuracy,
      won: result.won,
    );
    setState(() {
      _result = result;
      _screen = Screen.gameOver;
    });
  }

  /// Android back never leaves the app: game and result fall back to the menu.
  void _handleBack() {
    switch (_screen) {
      case Screen.game:
      case Screen.gameOver:
        _goMenu();
      case Screen.loader:
      case Screen.menu:
        break;
    }
  }

  Widget _buildScreen() {
    switch (_screen) {
      case Screen.loader:
        return LoaderScreen(key: const ValueKey<String>('loader'), onDone: _goMenu);
      case Screen.menu:
        return MenuScreen(
          key: const ValueKey<String>('menu'),
          onStart: _startLevel,
        );
      case Screen.game:
        return GameScreen(
          key: ValueKey<String>('game-$_levelId-$_round'),
          levelId: _levelId,
          onGameOver: _onGameOver,
          onExit: _goMenu,
        );
      case Screen.gameOver:
        final GameResult? result = _result;
        if (result == null) {
          return MenuScreen(
            key: const ValueKey<String>('menu'),
            onStart: _startLevel,
          );
        }
        return GameOverScreen(
          key: ValueKey<String>('gameover-$_round'),
          result: result,
          onPlayAgain: () => _startLevel(result.levelId),
          onNextLevel: _startLevel,
          onMenu: _goMenu,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: PMColors.bgBase,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: GameConfig.screenFadeMs),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildScreen(),
        ),
      ),
    );
  }
}
