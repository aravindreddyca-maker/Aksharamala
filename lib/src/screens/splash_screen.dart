import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/common.dart';
import 'profile_screen.dart';

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
    return GradientScaffold(
      colors: const [Color(0xFF6657D9), Color(0xFF9E78F5), Color(0xFFFFC96B)],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 500;
          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 12 : 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (compact ? 24 : 56),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .7, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: compact ? 64 : 104,
                      height: compact ? 64 : 104,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 3),
                      ),
                      child: Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: compact ? 38 : 62,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Aksharamala',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 30 : 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'అక్షరమాల  •  अक्षरमाला  •  அகரமாலை',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 15 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 18),
                  Text(
                    'Five worlds. One joyful learning adventure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 15 : 18,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 42),
                  if (!canContinue)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    FilledButton.icon(
                      key: const Key('start_adventure'),
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4B3DBA),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Start Adventure'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
