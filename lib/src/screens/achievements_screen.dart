import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const badges = [
    ('first-step', '🌟', 'First Step', 'Complete your first quest'),
    ('world-walker', '🧭', 'World Walker', 'Complete four quests'),
    ('bright-star', '💫', 'Bright Star', 'Complete eight quests'),
    ('four-world-hero', '🏆', 'All-World Hero', 'Complete a quest in every world'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final earned = controller.activeProgress.earnedBadges;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Rewards & Achievements'), backgroundColor: Colors.transparent),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: const Color(0xFFFFED9B),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [const Text('⭐', style: TextStyle(fontSize: 54)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${controller.activeProfile?.stars ?? 0} stars collected', style: Theme.of(context).textTheme.titleLarge), const Text('Every try grows your courage!')]))]),
            ),
          ),
          const SectionTitle('Badge cabinet'),
          ...badges.map((badge) {
            final unlocked = earned.contains(badge.$1);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Opacity(opacity: unlocked ? 1 : .25, child: Text(badge.$2, style: const TextStyle(fontSize: 42))),
                title: Text(badge.$3),
                subtitle: Text(unlocked ? 'Unlocked!' : badge.$4),
                trailing: Icon(unlocked ? Icons.check_circle : Icons.lock_outline, color: unlocked ? Colors.green : Colors.grey),
              ),
            );
          }),
        ],
      ),
    );
  }
}

