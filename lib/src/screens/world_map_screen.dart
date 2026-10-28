import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({required this.world, super.key});

  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final progress = controller.activeProgress;
    final recommended = controller.recommendedLesson(world);
    return GradientScaffold(
      appBar: AppBar(
          title: Text(world.name),
          backgroundColor: const Color(0xCC13213A),
          foregroundColor: Colors.white),
      child: Stack(fit: StackFit.expand, children: [
        Image(
            image: AssetImage(world.assetPath),
            fit: BoxFit.cover,
            semanticLabel: '${world.name} adventure landscape'),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB313213A), Color(0xD6070D17)]),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 390;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(compact ? 14 : 24,
                      compact ? 8 : 16, compact ? 14 : 24, compact ? 6 : 12),
                  child: Row(children: [
                    Container(
                      width: compact ? 52 : 66,
                      height: compact ? 52 : 66,
                      decoration: BoxDecoration(
                          color: world.color,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.route_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(world.description,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text('Recommended quest: ${recommended.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFFFE36E),
                                  fontWeight: FontWeight.w900)),
                        ])),
                    const SizedBox(width: 10),
                    StarPill(controller.activeProfile?.stars ?? 0),
                  ]),
                ),
                Expanded(
                  child: ListView.separated(
                    key: const Key('quest_trail'),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 4,
                        compact ? 14 : 24, compact ? 10 : 22),
                    itemCount: world.lessons.length,
                    separatorBuilder: (_, index) => SizedBox(
                      width: compact ? 34 : 54,
                      child: Center(
                          child: Icon(Icons.arrow_forward_rounded,
                              color:
                                  index.isEven ? world.color : Colors.white70,
                              size: 30)),
                    ),
                    itemBuilder: (context, index) {
                      final lesson = world.lessons[index];
                      return _QuestCard(
                        world: world,
                        lesson: lesson,
                        number: index + 1,
                        complete: progress.completedLessons.contains(lesson.id),
                        recommended: lesson.id == recommended.id,
                        compact: compact,
                      );
                    },
                  ),
                ),
              ]);
        }),
      ]),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard(
      {required this.world,
      required this.lesson,
      required this.number,
      required this.complete,
      required this.recommended,
      required this.compact});
  final LearningWorld world;
  final Lesson lesson;
  final int number;
  final bool complete;
  final bool recommended;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Quest $number, ${lesson.title}${complete ? ', completed' : ''}',
        child: SizedBox(
          width: compact ? 220 : 270,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              key: Key('lesson_${lesson.id}'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          LessonScreen(world: world, lesson: lesson))),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: EdgeInsets.all(compact ? 13 : 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: recommended ? world.color : Colors.white,
                      width: recommended ? 4 : 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 12,
                        offset: Offset(0, 6))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            backgroundColor: world.color.withValues(alpha: .2),
                            foregroundColor: world.darkColor,
                            child: Icon(lessonIcon(lesson.kind))),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text('QUEST $number',
                                style: TextStyle(
                                    color: world.darkColor,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1))),
                        Icon(
                            complete
                                ? Icons.check_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            color: complete ? Colors.green : world.darkColor,
                            size: 30),
                      ]),
                      const SizedBox(height: 9),
                      Text(lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Expanded(
                          child: Text(lesson.subtitle,
                              maxLines: 3, overflow: TextOverflow.ellipsis)),
                      if (recommended) ...[
                        const SizedBox(height: 5),
                        Text('NEXT ADVENTURE',
                            style: TextStyle(
                                color: world.darkColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900)),
                      ],
                    ]),
              ),
            ),
          ),
        ),
      );
}
