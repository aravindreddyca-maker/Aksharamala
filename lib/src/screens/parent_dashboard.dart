import 'package:flutter/material.dart';

import '../app.dart';
import '../curriculum.dart';
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
    final accuracy = totalAttempts == 0 ? 0 : (100 * totalCorrect / totalAttempts).round();
    return GradientScaffold(
      appBar: AppBar(title: const Text('Parent Dashboard'), backgroundColor: Colors.transparent),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${profile.name}’s learning', style: Theme.of(context).textTheme.headlineMedium),
          Text('${profile.stage.ageLabel} • ${profile.stage.focus}'),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _Metric(label: 'Stars', value: '${profile.stars}', icon: '⭐')),
            const SizedBox(width: 10),
            Expanded(child: _Metric(label: 'Quests', value: '${record.completedLessons.length}', icon: '✅')),
            const SizedBox(width: 10),
            Expanded(child: _Metric(label: 'Accuracy', value: '$accuracy%', icon: '🎯')),
          ]),
          const SectionTitle('Progress by world'),
          ...curriculum.map((world) {
            final complete = controller.completedInWorld(world);
            final worldAttempts = record.attempts[world.id] ?? 0;
            final worldAccuracy = worldAttempts == 0 ? 0 : (100 * (record.correct[world.id] ?? 0) / worldAttempts).round();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(world.emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 10), Expanded(child: Text(world.name, style: Theme.of(context).textTheme.titleMedium)), Text('$worldAccuracy%')]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: complete / world.lessons.length, minHeight: 10, borderRadius: BorderRadius.circular(10), color: world.darkColor),
                  const SizedBox(height: 6),
                  Text('$complete/${world.lessons.length} quests • $worldAttempts attempts'),
                ]),
              ),
            );
          }),
          const SectionTitle('Adaptive learning insight'),
          Card(
            color: const Color(0xFFEDE8FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(controller.adaptiveMessage, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Aksharamala recommends the first unfinished activity, then rotates mastered lessons for spaced review. A world below 70% accuracy is prioritised after two attempts.'),
              ]),
            ),
          ),
          const SectionTitle('Offline & privacy'),
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Progress is stored locally on this device. This vertical slice has no sign-in, advertising, analytics, cloud sync or network requirement.'))),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          child: Column(children: [Text(icon, style: const TextStyle(fontSize: 28)), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center)]),
        ),
      );
}
