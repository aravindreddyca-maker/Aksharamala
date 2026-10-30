import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../widgets/common.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.activeProfile!;
    final record = controller.activeProgress;
    final totalAttempts = record.attempts.values.fold<int>(0, (a, b) => a + b);
    final totalCorrect = record.correct.values.fold<int>(0, (a, b) => a + b);
    final accuracy =
        totalAttempts == 0 ? 0 : (100 * totalCorrect / totalAttempts).round();
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.name}’s learning',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${profile.stage.levelLabel} • ${profile.stage.ageLabel} • ${profile.stage.focus}',
                        ),
                      ],
                    ),
                  ),
                  StarPill(profile.stars),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Stars',
                      value: '${profile.stars}',
                      icon: Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      label: 'Quests',
                      value: '${record.completedLessons.length}',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      label: 'Accuracy',
                      value: '$accuracy%',
                      icon: Icons.track_changes_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: SwitchListTile(
                  key: const Key('new_lessons_switch'),
                  title: const Text('Try the new lessons (preview)'),
                  subtitle: const Text(
                    '10 Telugu letter lessons and Number Galaxy 0–10, with '
                    'counting, comparing and writing practice. Stars and '
                    'progress already earned are kept; turn it off any time.',
                  ),
                  value: controller.newLessonsEnabled,
                  onChanged: controller.setNewLessons,
                ),
              ),
              const SectionTitle('Progress by world'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide ? 3 : 2,
                  childAspectRatio: wide ? 2.4 : 2.15,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: controller.worlds.length,
                itemBuilder: (context, index) {
                  final world = controller.worlds[index];
                  final complete = controller.completedInWorld(world);
                  final attempts = record.attempts[world.id] ?? 0;
                  final worldAccuracy = attempts == 0
                      ? 0
                      : (100 * (record.correct[world.id] ?? 0) / attempts)
                          .round();
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: .9,
                          child: Image.asset(
                            world.assetPath,
                            fit: BoxFit.cover,
                            semanticLabel: world.name,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  world.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: complete / world.lessons.length,
                                  minHeight: 9,
                                  borderRadius: BorderRadius.circular(9),
                                  color: world.darkColor,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$complete/${world.lessons.length} quests • $worldAccuracy%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SectionTitle('Learning guidance'),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Insight(message: controller.adaptiveMessage),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: _Privacy()),
                  ],
                )
              else ...[
                _Insight(message: controller.adaptiveMessage),
                const SizedBox(height: 10),
                const _Privacy(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF6657D9), size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Insight extends StatelessWidget {
  const _Insight({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFEDE8FF),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_alt_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Adaptive insight',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'The next unfinished activity is recommended first. Mastered lessons rotate for review; a world below 70% accuracy is prioritised after two attempts.',
              ),
            ],
          ),
        ),
      );
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Offline & private',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Progress is stored locally on this device. There is no sign-in, advertising, analytics, cloud sync or network requirement.',
              ),
            ],
          ),
        ),
      );
}
