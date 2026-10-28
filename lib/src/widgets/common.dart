import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    required this.child,
    super.key,
    this.colors = const [Color(0xFFFDF6FF), Color(0xFFFFF7DF)],
    this.appBar,
  });

  final Widget child;
  final List<Color> colors;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar,
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
            ),
            child: SafeArea(child: child),
          ),
        ),
      );
}

class StarPill extends StatelessWidget {
  const StarPill(this.stars, {super.key});

  final int stars;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE585),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/rewards/star.png',
              width: 24,
              height: 24,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.star_rounded,
                color: Color(0xFF7A4E00),
                size: 21,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$stars',
              style: const TextStyle(
                color: GameTokens.ink,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
}

class GameAvatar extends StatelessWidget {
  const GameAvatar({
    required this.value,
    super.key,
    this.size = 48,
    this.selected = false,
  });

  final String value;
  final double size;
  final bool selected;

  static const options = <String>[
    'lion',
    'panda',
    'unicorn',
    'tiger',
    'frog',
    'robot',
  ];

  IconData get _icon => switch (value) {
        'lion' || '🦁' => Icons.pets_rounded,
        'panda' || '🐼' => Icons.cruelty_free_rounded,
        'unicorn' || '🦄' => Icons.auto_awesome_rounded,
        'tiger' || '🐯' => Icons.forest_rounded,
        'frog' || '🐸' => Icons.water_rounded,
        'robot' || '🤖' => Icons.smart_toy_rounded,
        _ => Icons.face_rounded,
      };

  /// Bundled artwork name. Older profiles stored an emoji; those still map.
  String? get _artwork => switch (value) {
        'lion' || '🦁' => 'lion',
        'panda' || '🐼' => 'panda',
        'unicorn' || '🦄' => 'unicorn',
        'tiger' || '🐯' => 'tiger',
        'frog' || '🐸' => 'frog',
        'robot' || '🤖' => 'robot',
        _ => null,
      };

  Color get _color => switch (value) {
        'lion' || '🦁' => const Color(0xFFF6A623),
        'panda' || '🐼' => const Color(0xFF50627A),
        'unicorn' || '🦄' => const Color(0xFF9B61DA),
        'tiger' || '🐯' => const Color(0xFFEA6A2A),
        'frog' || '🐸' => const Color(0xFF3C9A5F),
        'robot' || '🤖' => const Color(0xFF3978C6),
        _ => const Color(0xFF6657D9),
      };

  Widget get _iconAvatar => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color.withValues(alpha: .16),
          border: Border.all(
            color: selected ? _color : Colors.white,
            width: selected ? 4 : 2,
          ),
        ),
        child: Icon(_icon, color: _color, size: size * .56),
      );

  @override
  Widget build(BuildContext context) {
    final art = _artwork;
    return Semantics(
      image: true,
      label:
          '${value.replaceAll(RegExp(r'[^A-Za-z]'), '').isEmpty ? 'Learner' : value} avatar',
      excludeSemantics: true,
      child: art == null
          ? _iconAvatar
          : AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size,
              padding: EdgeInsets.all(selected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _color : Colors.transparent,
                  width: 4,
                ),
              ),
              child: Image.asset(
                'assets/images/avatars/$art.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => _iconAvatar,
              ),
            ),
    );
  }
}

IconData lessonIcon(LessonKind kind) => switch (kind) {
      LessonKind.alphabet => Icons.abc_rounded,
      LessonKind.words => Icons.chat_bubble_rounded,
      LessonKind.numbers => Icons.calculate_rounded,
      LessonKind.story => Icons.auto_stories_rounded,
      LessonKind.tracing => Icons.gesture_rounded,
      LessonKind.game => Icons.extension_rounded,
    };

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
