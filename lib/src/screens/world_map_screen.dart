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
      colors: [world.color.withValues(alpha: .18), Colors.white],
      appBar: AppBar(title: Text(world.name), backgroundColor: Colors.transparent),
      child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
        child: Column(children: [
          Text(world.emoji, style: const TextStyle(fontSize: 66)),
          Text(world.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: world.color.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
            child: Text('✨ Recommended: ${recommended.title}', style: TextStyle(color: world.darkColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 20),
          ...List.generate(world.lessons.length, (index) {
            final lesson = world.lessons[index];
            final complete = progress.completedLessons.contains(lesson.id);
            final isRecommended = lesson.id == recommended.id;
            return Align(
              alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: SizedBox(
                width: constraints.maxWidth * .82,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    key: Key('lesson_${lesson.id}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LessonScreen(world: world, lesson: lesson))),
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isRecommended ? world.color : const Color(0xFFE9E5F2), width: isRecommended ? 3 : 1),
                        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 25, backgroundColor: world.color.withValues(alpha: .25), child: Text(_icon(lesson.kind), style: const TextStyle(fontSize: 23))),
                        const SizedBox(width: 13),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lesson.title, style: Theme.of(context).textTheme.titleMedium), Text(lesson.subtitle)])),
                        Icon(complete ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded, color: complete ? Colors.green : world.darkColor, size: 32),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          }),
        ]),
      )),
    );
  }

  String _icon(LessonKind kind) => switch (kind) {
        LessonKind.alphabet => '🔤',
        LessonKind.words => '💬',
        LessonKind.numbers => '🔢',
        LessonKind.story => '📖',
        LessonKind.tracing => '✍️',
        LessonKind.game => '🎮',
      };
}
