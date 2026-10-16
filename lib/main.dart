import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'game/game_config.dart';
import 'game/progress_store.dart';
import 'game/round_result.dart';
import 'panels/level_gallery_panel.dart';
import 'panels/tutorial_panel.dart';
import 'screens/game_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/result_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter only publishes a semantics tree while some client holds a handle.
  // Short-lived uiautomator dumps never win that race on their own — without
  // this the accessibility tree comes back empty.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const PlinkoMosaicApp());
}

enum Screen { loader, menu, gallery, tutorial, game, result }

class PlinkoMosaicApp extends StatelessWidget {
  const PlinkoMosaicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plinko Mosaic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const AppShell(),
    );
  }
}

/// Screen state machine. A plain enum plus setState — no router needed.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ProgressStore _progress = ProgressStore.instance;

  Screen _screen = Screen.loader;
  int _level = 1;
  int _roundToken = 0;
  RoundResult? _result;

  void _go(Screen screen) {
    if (!mounted) return;
    setState(() => _screen = screen);
  }

  void _startLevel(int level) {
    setState(() {
      _level = GameConfig.clampLevel(level);
      _progress.currentLevel = _level;
      _roundToken++;
      _screen = Screen.game;
    });
  }

  void _onRoundOver(RoundResult result) {
    _progress.record(result);
    setState(() {
      _result = result;
      _screen = Screen.result;
    });
  }

  /// System back never leaves the app: every secondary surface returns to the
  /// Menu, and the Menu itself swallows the gesture.
  void _handleBack() {
    if (_screen == Screen.loader || _screen == Screen.menu) return;
    _go(Screen.menu);
  }

  Widget _menuScreen() {
    return MenuScreen(
      key: const ValueKey<String>('menu'),
      solvedCount: _progress.solvedCount,
      bestAccuracy: _progress.bestAccuracy,
      onStart: () => _startLevel(_progress.currentLevel),
      onGallery: () => _go(Screen.gallery),
      onRules: () => _go(Screen.tutorial),
    );
  }

  Widget _resultScreen() {
    final RoundResult? result = _result;
    if (result == null) return _menuScreen();
    return ResultScreen(
      key: ValueKey<String>('result-$_roundToken'),
      result: result,
      onPlayAgain: () => _startLevel(result.level),
      onNextLevel: () => _startLevel(_progress.nextLevelAfter(result.level)),
      onGallery: () => _go(Screen.gallery),
      onMenu: () => _go(Screen.menu),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case Screen.loader:
        return LoaderScreen(
          key: const ValueKey<String>('loader'),
          onDone: () => _go(Screen.menu),
        );
      case Screen.menu:
        return _menuScreen();
      case Screen.gallery:
        return LevelGalleryPanel(
          key: const ValueKey<String>('gallery'),
          onPick: _startLevel,
          onBack: () => _go(Screen.menu),
        );
      case Screen.tutorial:
        return TutorialPanel(
          key: const ValueKey<String>('tutorial'),
          onBack: () => _go(Screen.menu),
        );
      case Screen.game:
        return GameScreen(
          key: ValueKey<String>('game-$_level-$_roundToken'),
          level: _level,
          onRoundOver: _onRoundOver,
          onBack: () => _go(Screen.menu),
        );
      case Screen.result:
        return _resultScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBack();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _buildScreen(),
      ),
    );
  }
}
