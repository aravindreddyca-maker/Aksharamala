import 'package:flutter/material.dart';

import '../app.dart';
import '../app_controller.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const badges =
      <({String id, IconData icon, String asset, String title, String detail})>[
    (
      id: 'first-step',
      icon: Icons.flag_rounded,
      asset: 'assets/images/rewards/gift.png',
      title: 'First Step',
      detail: 'Complete your first quest',
    ),
    (
      id: 'world-walker',
      icon: Icons.explore_rounded,
      asset: 'assets/images/rewards/gem.png',
      title: 'World Walker',
      detail: 'Complete four quests',
    ),
    (
      id: 'bright-star',
      icon: Icons.auto_awesome_rounded,
      asset: 'assets/images/rewards/medal.png',
      title: 'Bright Star',
      detail: 'Complete eight quests',
    ),
    (
      id: 'all-world-hero',
      icon: Icons.emoji_events_rounded,
      asset: 'assets/images/rewards/crown.png',
      title: 'All-World Hero',
      detail: 'Complete a quest in every world',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final earned = controller.activeProgress.earnedBadges;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Rewards & Achievements'),
        backgroundColor: Colors.transparent,
      ),
      // Everything fits the screen at once: the star banner on top and the
      // badges sharing the rest, in as many columns as the width allows.
      child: LayoutBuilder(
        builder: (context, box) {
          final short = box.maxHeight < 430;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, short ? 4 : 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summary(context, controller, earned.length, short),
                SizedBox(height: short ? 6 : 12),
                Expanded(child: _cabinet(context, earned, short)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    AppController controller,
    int earned,
    bool short,
  ) =>
      Container(
        padding: EdgeInsets.all(short ? 8 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD85C), Color(0xFFFFB74D)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: short ? 22 : 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFFF29F05),
                size: short ? 28 : 38,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.activeProfile?.stars ?? 0} stars collected',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Every try grows your courage!'),
                ],
              ),
            ),
            Text(
              '$earned/${badges.length} badges',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );

  /// The badges in a grid that always fits: the columns are chosen from the
  /// width, and each row takes an equal share of the height.
  Widget _cabinet(BuildContext context, Set<String> earned, bool short) =>
      LayoutBuilder(
        builder: (context, box) {
          const gap = 12.0;
          final columns = box.maxWidth >= 760
              ? 4
              : box.maxWidth >= 300
                  ? 2
                  : 1;
          final rows = (badges.length / columns).ceil();
          final titleHeight = short ? 28.0 : 36.0;
          final tileHeight = (box.maxHeight - titleHeight - gap * rows) / rows;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: titleHeight,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Badge cabinet',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              for (var r = 0; r < rows; r++) ...[
                const SizedBox(height: gap),
                SizedBox(
                  height: tileHeight.clamp(40.0, 160.0),
                  child: Row(
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: gap),
                        Expanded(
                          child: r * columns + c < badges.length
                              ? _badge(
                                  context,
                                  badges[r * columns + c],
                                  earned.contains(badges[r * columns + c].id),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      );

  Widget _badge(
    BuildContext context,
    ({
      String id,
      IconData icon,
      String asset,
      String title,
      String detail
    }) badge,
    bool unlocked,
  ) =>
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          // Scales down rather than overflowing in a small tile.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 300,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? const Color(0xFFFFE8A3)
                          : const Color(0xFFE8E9EF),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        badge.asset,
                        color: unlocked ? null : Colors.grey,
                        colorBlendMode: unlocked ? null : BlendMode.saturation,
                        errorBuilder: (_, __, ___) => Icon(
                          badge.icon,
                          color:
                              unlocked ? const Color(0xFF8A5B00) : Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          unlocked ? 'Unlocked!' : badge.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: unlocked ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
