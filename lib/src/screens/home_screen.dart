import 'package:flutter/material.dart';

import '../app.dart';
import '../curriculum.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'parent_dashboard.dart';
import 'profile_screen.dart';
import 'world_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.activeProfile;
    if (profile == null) return const ProfileScreen();
    return Scaffold(
      backgroundColor: const Color(0xFF13213A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 430 || constraints.maxWidth < 720;
            return CustomScrollView(
              key: const Key('home_scroll'),
              slivers: [
                SliverToBoxAdapter(
                  child: _TopBar(profile: profile, compact: compact),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 24,
                    4,
                    compact ? 12 : 24,
                    10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _AdventureBanner(
                      message: controller.adaptiveMessage,
                      compact: compact,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Choose your adventure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _ActionButton(
                          icon: Icons.emoji_events_rounded,
                          label: 'Rewards',
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
                          onTap: () => _parentGate(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 24,
                    10,
                    compact ? 12 : 24,
                    24,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: compact ? 330 : 420,
                      mainAxisExtent: compact ? 190 : 230,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: curriculum.length,
                      (_, index) => _WorldCard(world: curriculum[index]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile, required this.compact});
  final ChildProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.fromLTRB(compact ? 12 : 24, 8, compact ? 12 : 24, 6),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileScreen(allowSkip: true),
                ),
              ),
              borderRadius: BorderRadius.circular(30),
              child: GameAvatar(value: profile.avatar, size: compact ? 44 : 52),
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
                      style: const TextStyle(color: Color(0xFFBECBE4)),
                    ),
                ],
              ),
            ),
            StarPill(profile.stars),
          ],
        ),
      );
}

class _AdventureBanner extends StatelessWidget {
  const _AdventureBanner({required this.message, required this.compact});
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5D4DD4), Color(0xFF9A5DE2)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFE879),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today’s learning trail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 15 : 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    message,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, height: 1.25),
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
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
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
    return Semantics(
      button: true,
      label: 'Open ${world.name}',
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
                image: AssetImage(world.assetPath),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: .62,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF253247), Color(0xFF070D17)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Text(
                          world.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          world.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF5F7FF),
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  backgroundColor: Colors.white30,
                                  color: const Color(0xFFFFE36E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$done/${world.lessons.length} quests',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
