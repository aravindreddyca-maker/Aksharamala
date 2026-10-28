import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const badges =
      <({String id, IconData icon, String title, String detail})>[
    (
      id: 'first-step',
      icon: Icons.flag_rounded,
      title: 'First Step',
      detail: 'Complete your first quest',
    ),
    (
      id: 'world-walker',
      icon: Icons.explore_rounded,
      title: 'World Walker',
      detail: 'Complete four quests',
    ),
    (
      id: 'bright-star',
      icon: Icons.auto_awesome_rounded,
      title: 'Bright Star',
      detail: 'Complete eight quests',
    ),
    (
      id: 'four-world-hero',
      icon: Icons.emoji_events_rounded,
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
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD85C), Color(0xFFFFB74D)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF29F05),
                        size: 38,
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
                      '${earned.length}/${badges.length} badges',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 6, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Badge cabinet',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 138,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(childCount: badges.length, (
                context,
                index,
              ) {
                final badge = badges[index];
                final unlocked = earned.contains(badge.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                          child: Icon(
                            badge.icon,
                            color: unlocked
                                ? const Color(0xFF8A5B00)
                                : Colors.grey,
                            size: 32,
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
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
