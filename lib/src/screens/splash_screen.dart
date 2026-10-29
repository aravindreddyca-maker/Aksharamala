import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import 'profile_screen.dart';

/// The cast that waves from the bottom of the launch page.
const _cast = <String>[
  'assets/images/mascots/boy.png',
  'assets/images/mascots/elephant.png',
  'assets/images/mascots/parrot.png',
  'assets/images/mascots/tiger.png',
  'assets/images/mascots/girl.png',
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    final controller = AppScope.of(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => controller.profiles.isEmpty
            ? const ProfileScreen()
            : const ProfileScreen(allowSkip: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canContinue = _ready && controller.loaded;
    return Scaffold(
      backgroundColor: GameTokens.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/home_bg.webp',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6657D9), Color(0xFFFFC96B)],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 500;
              final castHeight = constraints.maxHeight * (compact ? .30 : .34);
              return Stack(
                children: [
                  // Decorative only: never blocks taps, never read aloud.
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 6,
                    height: castHeight,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final asset in _cast)
                              Flexible(
                                child: Image.asset(
                                  asset,
                                  height: castHeight,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 28,
                        // Title and button sit in the blue sky, above the
                        // treeline and the cast.
                        compact ? 22 : constraints.maxHeight * .07,
                        compact ? 16 : 28,
                        castHeight * .4,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: constraints.maxHeight -
                              castHeight * .4 -
                              (compact ? 16 : 48),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: .8, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.elasticOut,
                              builder: (_, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: _Logo(
                                height: constraints.maxHeight *
                                    (compact ? .40 : .38),
                              ),
                            ),
                            SizedBox(height: compact ? 8 : 16),
                            _StartButton(
                              enabled: canContinue,
                              compact: compact,
                              onPressed: _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The Aksharamala logo, announced as the app's name.
class _Logo extends StatelessWidget {
  const _Logo({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: 'Aksharamala',
        child: Image.asset(
          'assets/images/brand/logo.png',
          height: height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => SizedBox(
            height: height,
            child: const FittedBox(
              child: Text(
                'Aksharamala',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Holds its place while loading so nothing jumps when it becomes tappable.
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.enabled,
    required this.compact,
    required this.onPressed,
  });
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        key: const Key('start_adventure'),
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: GameTokens.gold,
          foregroundColor: GameTokens.ink,
          disabledBackgroundColor: Colors.white70,
          disabledForegroundColor: GameTokens.ink,
          minimumSize: Size(compact ? 230 : 280, compact ? 52 : 64),
          textStyle: TextStyle(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w900,
          ),
          side: const BorderSide(color: Colors.white, width: 3),
          elevation: 6,
          shadowColor: const Color(0x99000000),
        ),
        icon: enabled
            ? const Icon(Icons.rocket_launch_rounded)
            : const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
        label: Text(enabled ? 'Start Adventure' : 'Getting ready…'),
      );
}
