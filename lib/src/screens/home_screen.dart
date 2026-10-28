import 'dart:ui' as ui;

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

/// The friend who stands in each world's card.
const _worldMascots = <String, String>{
  'english': 'assets/images/mascots/boy.png',
  'telugu': 'assets/images/mascots/elephant.png',
  'hindi': 'assets/images/mascots/tiger.png',
  'tamil': 'assets/images/mascots/girl.png',
  'numbers': 'assets/images/mascots/robot.png',
};

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.activeProfile;
    if (profile == null) return const ProfileScreen();
    return Scaffold(
      backgroundColor: GameTokens.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Softened so the scenery reads as a backdrop, not competing detail.
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 4,
              sigmaY: 4,
              tileMode: TileMode.clamp,
            ),
            child: Image.asset(
              'assets/images/backgrounds/home_bg.webp',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Light scrim only: the banner, buttons and cards carry their own
          // contrast, so the meadow can stay bright.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66132A4F), Color(0x8013213A)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 430 || constraints.maxWidth < 720;
                final pad = compact ? 12.0 : 24.0;
                return Column(
                  children: [
                    _HomeHeader(
                      profile: profile,
                      message: controller.adaptiveMessage,
                      compact: compact,
                      pad: pad,
                    ),
                    Expanded(child: _WorldStrip(pad: pad, compact: compact)),
                  ],
                );
              },
            ),
          ),
        ],
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

/// One row: greeting banner with the child's avatar overlapping it, then
/// Rewards, Parents and the star count. Frees height for the world cards.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.profile,
    required this.message,
    required this.compact,
    required this.pad,
  });
  final ChildProfile profile;
  final String message;
  final bool compact;
  final double pad;

  @override
  Widget build(BuildContext context) {
    // Labelled buttons only when there is room; icon-only keeps 640dp safe.
    final labelled = MediaQuery.sizeOf(context).width >= 900 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final bannerHeight = compact ? 54.0 : 66.0;
    final avatarSize = bannerHeight + 12;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 10, pad, 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: avatarSize * .55,
                    right: 0,
                    top: 6,
                    height: bannerHeight,
                    child: _GreetingBanner(
                      name: profile.name,
                      message: message,
                      compact: compact,
                      leftInset: avatarSize * .5,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Semantics(
                      button: true,
                      label: 'Change learner',
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const ProfileScreen(allowSkip: true),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(avatarSize),
                        child: GameAvatar(
                          value: profile.avatar,
                          size: avatarSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Image.asset(
              'assets/images/rewards/trophy.png',
              width: 26,
              height: 26,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.emoji_events_rounded),
            ),
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
            icon: const Icon(Icons.family_restroom_rounded),
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

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({
    required this.name,
    required this.message,
    required this.compact,
    required this.leftInset,
  });
  final String name;
  final String message;
  final bool compact;
  final double leftInset;

  @override
  Widget build(BuildContext context) =>
      // The banner has a fixed height, so its text scales up to 125% only;
      // the rest of the screen still follows the system text size.
      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.25, child: _body());

  Widget _body() => Container(
        padding: EdgeInsets.fromLTRB(leftInset + 12, 4, 16, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5D4DD4), Color(0xFF9A5DE2)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Namaste, '),
                    TextSpan(
                      text: '$name!',
                      style: const TextStyle(color: GameTokens.gold),
                    ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 18 : 23,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
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
  final Widget icon;
  final String label;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: showLabel
            ? FilledButton.tonalIcon(
                onPressed: onTap,
                icon: icon,
                label: Text(label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(GameTokens.minTouch, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
              )
            : IconButton.filledTonal(
                onPressed: onTap,
                icon: icon,
                tooltip: label,
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
          final bottom = compact ? 12.0 : 20.0;
          return CustomScrollView(
            key: const Key('home_scroll'),
            scrollDirection: Axis.horizontal,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 6, pad, bottom),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: constraints.maxHeight - 6 - bottom,
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
    final total = world.lessons.length;
    final progress = done / total;
    final emblem = _emblemAssets[world.id];
    final mascot = _worldMascots[world.id];
    // Panel tinted from the world's own colour, dark enough for white text.
    final panelTop = Color.lerp(world.darkColor, Colors.black, .30)!;
    final panelBottom = Color.lerp(world.darkColor, Colors.black, .52)!;
    return Semantics(
      button: true,
      label: 'Open ${world.name}, $done of $total quests done, '
          '${(progress * 100).round()} percent',
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
              // A thin world-coloured edge so each world reads as its own.
              border: Border.all(
                color: world.color.withValues(alpha: .9),
                width: 2.5,
              ),
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
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, box) {
                  final panelHeight = box.maxHeight * .32;
                  final emblemSize =
                      (box.maxHeight * .15).clamp(32.0, 44.0).toDouble();
                  final arrowSize =
                      (box.maxHeight * .14).clamp(26.0, 36.0).toDouble();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (mascot != null)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: panelHeight - 8,
                          // Sized to stay clear of the corner badge.
                          height: box.maxHeight * .50,
                          child: Image.asset(
                            mascot,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: panelHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [panelTop, panelBottom],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: world.color.withValues(alpha: .9),
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width:
                                      (box.maxWidth - 20).clamp(100.0, 400.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        world.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: progress,
                                                    minHeight: 8,
                                                    backgroundColor:
                                                        Colors.white30,
                                                    color: const Color(
                                                      0xFFFFE36E,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$done/$total quests',
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: arrowSize,
                                            height: arrowSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: world.color,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.white,
                                              size: arrowSize * .8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
