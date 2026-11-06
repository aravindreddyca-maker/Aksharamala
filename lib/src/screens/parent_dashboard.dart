import 'package:flutter/material.dart';

import '../app.dart';
import '../levels.dart';
import '../widgets/common.dart';
import '../widgets/fit_content.dart';
import 'exam/exam_scope.dart';
import 'exam/examination_centre.dart';

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
      // Nothing scrolls: on a wide screen the summary and guidance sit beside
      // the world progress; on a tall one they stack. Either way the whole
      // dashboard is scaled to the screen.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 620 &&
              constraints.maxWidth > constraints.maxHeight;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          '${levelInfo(profile.level).label} • ${levelInfo(profile.level).tagline}',
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
              if (ExamScope.maybeOf(context) != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('open_exam_centre'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => openExaminationCentre(context),
                  icon: const Icon(Icons.fact_check_rounded),
                  label: const Text('Examination Centre'),
                ),
              ],
            ],
          );
          final progress = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Progress by world'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: twoColumns ? 100 : 100,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
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
                    margin: EdgeInsets.zero,
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
                            padding: const EdgeInsets.all(8),
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
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: world.lessons.isEmpty
                                      ? 0
                                      : complete / world.lessons.length,
                                  minHeight: 9,
                                  borderRadius: BorderRadius.circular(9),
                                  color: world.darkColor,
                                ),
                                const SizedBox(height: 4),
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
            ],
          );
          final guidance = Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton.tonalIcon(
              key: const Key('open_guidance'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FitContent(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionTitle('Learning guidance'),
                            _Insight(message: controller.adaptiveMessage),
                            const SizedBox(height: 8),
                            const _Privacy(),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.psychology_alt_rounded),
              label: const Text('Learning guidance'),
            ),
          );
          const pad = EdgeInsets.fromLTRB(20, 8, 20, 12);
          if (twoColumns) {
            return Padding(
              padding: pad,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FitContent(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [summary, guidance],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: FitContent(child: progress)),
                ],
              ),
            );
          }
          return Padding(
            padding: pad,
            child: FitContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [summary, progress, guidance],
              ),
            ),
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
                  Flexible(
                    child: Text(
                      'Adaptive insight',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
                  Flexible(
                    child: Text(
                      'Offline & private',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
