import 'package:flutter/material.dart';

import '../app.dart';
import '../curriculum.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'parent_dashboard.dart';
import 'profile_screen.dart';
import 'world_map_screen.dart';

const _emblemAssets = <String, String>{
  'english': 'assets/images/emblems/english.png',
  'telugu': 'assets/images/emblems/telugu.png',
  'hindi': 'assets/images/emblems/hindi.png',
  'tamil': 'assets/images/emblems/tamil.png',
  'numbers': 'assets/images/emblems/numbers.png',
};

const _mascotAssets = <String>[
  'assets/images/mascots/boy.png',
  'assets/images/mascots/girl.png',
  'assets/images/mascots/tiger.png',
  'assets/images/mascots/parrot.png',
  'assets/images/mascots/elephant.png',
];

/// A stable guide per child, so each learner always meets the same friend.
String _mascotFor(ChildProfile profile) => _mascotAssets[
    profile.id.codeUnits.fold<int>(0, (a, b) => a + b) % _mascotAssets.length];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.activeProfile;
    if (profile == null) return const ProfileScreen();
    return Scaffold(
      backgroundColor: GameTokens.navy,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3157), GameTokens.navy],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxHeight < 430 || constraints.maxWidth < 720;
              final pad = compact ? 12.0 : 24.0;
              return Column(
                children: [
                  _TopBar(profile: profile, compact: compact, pad: pad),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: _AdventureBanner(
                      message: controller.adaptiveMessage,
                      mascot: _mascotFor(profile),
                      compact: compact,
                    ),
                  ),
                  Expanded(child: _WorldStrip(pad: pad, compact: compact)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _parentGate(BuildContext context) async {
  final answer = await showDialog<int>(
    context: context,
    builder: (context) {
      int? selected;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Grown-ups only'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('What is 7 + 5?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [10, 12, 14]
                    .map(
                      (value) => ChoiceChip(
                        label: Text('$value'),
                        selected: selected == value,
                        onSelected: (_) {
                          setState(() => selected = value);
                          Navigator.pop(context, value);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted) return;
  if (answer == 12) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ParentDashboard()),
    );
  } else if (answer != null) {
    await showInfoDialog(
      context,
      title: 'Try again',
      message: 'Ask a grown-up to open the parent dashboard.',
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.profile,
    required this.compact,
    required this.pad,
  });
  final ChildProfile profile;
  final bool compact;
  final double pad;

  @override
  Widget build(BuildContext context) {
    // Labelled buttons only when there is room; icon-only keeps 640dp safe.
    final labelled = MediaQuery.sizeOf(context).width >= 860 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Change learner',
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileScreen(allowSkip: true),
                ),
              ),
              borderRadius: BorderRadius.circular(30),
              child: GameAvatar(value: profile.avatar, size: compact ? 44 : 52),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Namaste, ${profile.name}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 17 : 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!compact)
                  Text(
                    '${profile.stage.label} • ${profile.stage.ageLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFD3DDF1)),
                  ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.emoji_events_rounded,
            label: 'Rewards',
            showLabel: labelled,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AchievementsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.family_restroom_rounded,
            label: 'Parents',
            showLabel: labelled,
            onTap: () => _parentGate(context),
          ),
          const SizedBox(width: 10),
          StarPill(profile.stars),
        ],
      ),
    );
  }
}

class _AdventureBanner extends StatelessWidget {
  const _AdventureBanner({
    required this.message,
    required this.mascot,
    required this.compact,
  });
  final String message;
  final String mascot;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,
          vertical: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5D4DD4), Color(0xFF9A5DE2)],
          ),
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              mascot,
              height: compact ? 44 : 64,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFFFE879),
                size: compact ? 28 : 40,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact)
                    const Text(
                      'Today’s learning trail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  Text(
                    message,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.25,
                      fontWeight: compact ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: showLabel
            ? FilledButton.tonalIcon(
                onPressed: onTap,
                icon: Icon(icon),
                label: Text(label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(GameTokens.minTouch, 48),
                ),
              )
            : IconButton.filledTonal(
                onPressed: onTap,
                icon: Icon(icon),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
      );
}

/// All five worlds on one landscape row. Tiles share the width when it fits
/// and slide sideways (never vertically) on narrower screens.
class _WorldStrip extends StatelessWidget {
  const _WorldStrip({required this.pad, required this.compact});
  final double pad;
  final bool compact;

  static const _gap = 12.0;
  static const _minTile = 132.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - pad * 2;
          final count = curriculum.length;
          final fit = (available - _gap * (count - 1)) / count;
          final tileWidth = fit < _minTile ? _minTile : fit;
          return CustomScrollView(
            key: const Key('home_scroll'),
            scrollDirection: Axis.horizontal,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 10, pad, compact ? 12 : 20),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: constraints.maxHeight - 10 - (compact ? 12 : 20),
                    child: Row(
                      children: [
                        for (var i = 0; i < count; i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          SizedBox(
                            width: tileWidth,
                            child: _WorldCard(world: curriculum[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world});
  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final done = controller.completedInWorld(world);
    final progress = done / world.lessons.length;
    final emblem = _emblemAssets[world.id];
    return Semantics(
      button: true,
      label: 'Open ${world.name}, $done of ${world.lessons.length} quests done',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('world_${world.id}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => WorldMapScreen(world: world),
            ),
          ),
          borderRadius: BorderRadius.circular(26),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              image: DecorationImage(
                // Decoded at tile size: the source art is 1672 px wide.
                image: ResizeImage(
                  AssetImage(world.assetPath),
                  width: 720,
                ),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: LayoutBuilder(
                builder: (context, box) {
                  final emblemSize =
                      (box.maxHeight * .24).clamp(40.0, 64.0).toDouble();
                  final roomy = box.maxHeight >= 250;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: .56,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                // Fades in over the art, solid before the
                                // text so white copy keeps 4.5:1 contrast.
                                stops: [0, .22, 1],
                                colors: [
                                  Color(0x00253247),
                                  Color(0xFF253247),
                                  Color(0xFF070D17),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (emblem != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Image.asset(
                            emblem,
                            width: emblemSize,
                            height: emblemSize,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                SizedBox(width: emblemSize),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              width: (box.maxWidth - 24).clamp(80.0, 400.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    world.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (roomy) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      world.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFF5F7FF),
                                        fontSize: 13,
                                        height: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.white30,
                                      color: const Color(0xFFFFE36E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$done/${world.lessons.length} quests',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
