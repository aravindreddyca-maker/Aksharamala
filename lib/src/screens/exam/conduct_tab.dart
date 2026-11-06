import 'package:flutter/material.dart';

import '../../app.dart';
import '../../exam/exam_controller.dart';
import '../../exam/models.dart';
import '../../exam/selection.dart';
import '../../levels.dart';
import '../../models.dart';
import '../../theme.dart';
import 'child_exam_screen.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';

class _Mix {
  const _Mix(this.label, this.mix);

  final String label;
  final DifficultyMix mix;
}

const List<_Mix> _mixes = [
  _Mix('Balanced', DifficultyMix(easy: 50, medium: 30, hard: 20)),
  _Mix('Easier', DifficultyMix(easy: 70, medium: 25, hard: 5)),
  _Mix('Harder', DifficultyMix(easy: 20, medium: 40, hard: 40)),
];

class _LessonChoice {
  const _LessonChoice(this.id, this.title, this.world, this.count);

  final String id;
  final String title;
  final String world;
  final int count;
}

/// Section (a): choose and start an exam.
class ConductTab extends StatefulWidget {
  const ConductTab({required this.child, super.key});

  final ChildProfile child;

  @override
  State<ConductTab> createState() => _ConductTabState();
}

class _ConductTabState extends State<ConductTab> {
  late int _level = widget.child.level;
  ExamType _type = ExamType.subject;
  final Set<String> _lessons = {};
  String? _world;
  Set<String>? _finalWorlds; // null = every world
  int _count = 10;
  int _mixIndex = 0;
  double? _pass;
  bool _timed = false;
  int _minutes = 20;
  RetestKind _retest = RetestKind.unlimited;
  int _retestValue = 3;
  bool _includeParent = false;
  bool _perWorld = false;
  String? _message;
  int? _offer;
  bool _busy = false;

  @override
  void didUpdateWidget(ConductTab old) {
    super.didUpdateWidget(old);
    if (old.child.id != widget.child.id) {
      _level = widget.child.level;
      _lessons.clear();
      _pass = null;
      _message = null;
      _offer = null;
    }
  }

  List<LearningWorld> get _allWorlds => AppScope.of(context).allWorlds;

  List<_LessonChoice> _lessonChoices(ExamController exams) {
    final counts = <String, int>{};
    final titles = <String, String>{};
    final worlds = <String, String>{};
    for (final q in exams.bank.forLevel(_level)) {
      counts[q.lessonId] = (counts[q.lessonId] ?? 0) + 1;
      titles[q.lessonId] = q.lessonTitle.isEmpty ? q.lessonId : q.lessonTitle;
      worlds[q.lessonId] = q.world;
    }
    return [
      for (final id in counts.keys)
        _LessonChoice(id, titles[id]!, worlds[id]!, counts[id]!),
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Worlds that have at least one auto-marked question at the chosen level.
  Set<String> _worldsWithQuestions(ExamController exams) =>
      {for (final q in exams.bank.forLevel(_level)) q.world};

  /// Final exam subjects: the parent's choice, else every subject that has
  /// questions at this level. A subject with none is never included.
  Set<String> _chosenFinalWorlds(ExamController exams) {
    final have = _worldsWithQuestions(exams);
    final own = _finalWorlds;
    final all = {for (final w in _allWorlds) w.id};
    return (own ?? all).intersection(have);
  }

  String _emptyWorldNames(ExamController exams) {
    final have = _worldsWithQuestions(exams);
    return [
      for (final w in _allWorlds)
        if (!have.contains(w.id)) w.name
    ].join(', ');
  }

  ExamConfig _config(ExamController exams, {int? count}) {
    final worlds = switch (_type) {
      ExamType.chapter => <String>[],
      ExamType.subject => [if (_world != null) _world!],
      ExamType.finalLevel => _chosenFinalWorlds(exams).toList(),
    };
    final pass = _pass ?? exams.passPercentFor(widget.child.id);
    return exams.buildConfig(
      childId: widget.child.id,
      childName: widget.child.name,
      level: _level,
      type: _type,
      worlds: worlds,
      lessonIds:
          _type == ExamType.chapter ? (_lessons.toList()..sort()) : const [],
      questionCount: count ?? _count,
      difficultyMix: _mixes[_mixIndex].mix,
      passPercent: pass,
      perWorldMinPercent:
          _type == ExamType.finalLevel && _perWorld ? pass : null,
      timeLimitSeconds: _timed ? _minutes * 60 : null,
      retestPolicy: switch (_retest) {
        RetestKind.unlimited => const RetestPolicy.unlimited(),
        RetestKind.maxAttempts => RetestPolicy.maxAttempts(_retestValue),
        RetestKind.waitHours => RetestPolicy.waitHours(_retestValue),
      },
      includeParentMarked: _includeParent,
    );
  }

  int _available(ExamController exams) =>
      ExamSelection.candidates(_config(exams), exams.bank.questions).length;

  String _availabilityText(ExamController exams, int n) {
    if (exams.bank.forLevel(_level).isEmpty) {
      return _level == lastLevel
          ? 'No questions yet - Level $_level lessons are coming.'
          : 'No questions yet for Level $_level.';
    }
    if (_type == ExamType.chapter && _lessons.isEmpty) {
      return 'Choose at least one lesson.';
    }
    if (_type == ExamType.subject && _world == null) {
      return 'Choose a subject.';
    }
    if (_type == ExamType.finalLevel && _chosenFinalWorlds(exams).isEmpty) {
      return 'No subject has questions at Level $_level yet.';
    }
    return switch (_type) {
      ExamType.chapter => 'The chosen lessons have $n questions.',
      ExamType.subject => 'This level has $n questions for this subject.',
      ExamType.finalLevel =>
        'This level has $n questions for the chosen subjects.',
    };
  }

  Future<void> _start(ExamController exams, {int? count}) async {
    setState(() {
      _busy = true;
      _message = null;
      _offer = null;
    });
    final outcome = await exams.startExam(_config(exams, count: count));
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case StartExamStarted(:final attempt):
        await _open(attempt.id);
      case StartExamResume():
        setState(() => _message =
            'This child already has an unfinished exam. Resume or discard it first.');
      case StartExamPolicyRefused(:final reason):
        setState(() => _message = reason);
      case StartExamNotEnoughQuestions(:final refusal):
        final cfg = _config(exams);
        final have = _worldsWithQuestions(exams);
        final empty = [
          for (final w in _allWorlds)
            if (cfg.worlds.contains(w.id) && !have.contains(w.id)) w.name,
        ];
        setState(() {
          if (empty.isNotEmpty) {
            // Never offer a smaller count: it would hit the same refusal.
            _message =
                '${empty.join(', ')} has no questions at Level $_level yet. '
                'Switch it off to go on.';
            _offer = null;
          } else {
            _message = refusal.reason;
            _offer = refusal.available > 0 ? refusal.available : null;
          }
        });
    }
  }

  Future<void> _open(String attemptId) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChildExamScreen(attemptId: attemptId),
        ),
      );

  Future<void> _discard(ExamController exams, ExamAttempt attempt) async {
    final ok = await confirmDialog(
      context,
      title: 'Discard this exam?',
      message:
          'The answers given so far will be thrown away and no result is made.',
      confirmLabel: 'Discard',
      confirmKey: const Key('confirm_discard'),
    );
    if (ok) await exams.abandon(attempt.id);
  }

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final child = widget.child;
    final unfinished = exams.inProgressFor(child.id);
    final available = _available(exams);
    final worlds = _allWorlds;
    final canStart = !_busy &&
        available > 0 &&
        (_type != ExamType.chapter || _lessons.isNotEmpty) &&
        (_type != ExamType.subject || _world != null) &&
        (_type != ExamType.finalLevel || _chosenFinalWorlds(exams).isNotEmpty);
    final pass = (_pass ?? exams.passPercentFor(child.id)).round();

    return PageBody(
      child: ListView(
        key: const Key('conduct_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (unfinished != null)
            ExamCard(
              key: const Key('unfinished_card'),
              title: 'Unfinished exam',
              color: const Color(0xFFFFF3CD),
              children: [
                Text(
                  '${examTypeLabel(unfinished.config.type)}, Level ${unfinished.config.level}: '
                  '${unfinished.answeredCount} of ${unfinished.questions.length} answered.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    FilledButton(
                      key: const Key('resume_exam'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => _open(unfinished.id),
                      child: const Text('Resume'),
                    ),
                    OutlinedButton(
                      key: const Key('discard_exam'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => _discard(exams, unfinished),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
          ExamCard(
            title: 'Level',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final l in allLevels)
                    ChoiceChip(
                      key: Key('level_$l'),
                      label: Text('Level $l'),
                      selected: _level == l,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() {
                        _level = l;
                        _lessons.clear();
                        _finalWorlds = null;
                        _message = null;
                        _offer = null;
                      }),
                    ),
                ],
              ),
            ],
          ),
          ExamCard(
            title: 'Type of exam',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in ExamType.values)
                    ChoiceChip(
                      key: Key('type_${t.name}'),
                      label: Text(examTypeLabel(t)),
                      selected: _type == t,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() {
                        _type = t;
                        _message = null;
                        _offer = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ..._scopePicker(exams, worlds),
            ],
          ),
          ExamCard(
            title: 'Questions',
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  _availabilityText(exams, available),
                  key: const Key('availability'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              CountStepper(
                label: 'Number of questions',
                value: _count,
                max: 100,
                keyPrefix: 'count',
                onChanged: (v) => setState(() => _count = v),
              ),
              const SizedBox(height: 6),
              const Text('Difficulty mix'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < _mixes.length; i++)
                    ChoiceChip(
                      key: Key('mix_$i'),
                      label: Text(_mixes[i].label),
                      selected: _mixIndex == i,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() => _mixIndex = i),
                    ),
                ],
              ),
              SwitchListTile(
                key: const Key('include_parent'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Include writing items I will mark myself'),
                value: _includeParent,
                onChanged: (v) => setState(() => _includeParent = v),
              ),
            ],
          ),
          ExamCard(
            title: 'Rules',
            children: [
              CountStepper(
                label: 'Pass mark',
                value: pass,
                min: 10,
                max: 100,
                step: 5,
                unit: '%',
                keyPrefix: 'pass',
                onChanged: (v) => setState(() => _pass = v.toDouble()),
              ),
              if (_type == ExamType.finalLevel)
                SwitchListTile(
                  key: const Key('per_world'),
                  contentPadding: EdgeInsets.zero,
                  title:
                      const Text('Every subject must also reach the pass mark'),
                  value: _perWorld,
                  onChanged: (v) => setState(() => _perWorld = v),
                ),
              SwitchListTile(
                key: const Key('timed'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Time limit'),
                value: _timed,
                onChanged: (v) => setState(() => _timed = v),
              ),
              if (_timed)
                CountStepper(
                  label: 'Minutes',
                  value: _minutes,
                  min: 1,
                  max: 180,
                  step: 5,
                  keyPrefix: 'minutes',
                  onChanged: (v) => setState(() => _minutes = v),
                ),
              const SizedBox(height: 6),
              const Text('Retest policy'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (kind, label) in const [
                    (RetestKind.unlimited, 'No limit'),
                    (RetestKind.maxAttempts, 'Limit attempts'),
                    (RetestKind.waitHours, 'Wait between attempts'),
                  ])
                    ChoiceChip(
                      key: Key('retest_${kind.name}'),
                      label: Text(label),
                      selected: _retest == kind,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() {
                        _retest = kind;
                        _retestValue = kind == RetestKind.waitHours ? 24 : 3;
                      }),
                    ),
                ],
              ),
              if (_retest != RetestKind.unlimited)
                CountStepper(
                  label: _retest == RetestKind.maxAttempts
                      ? 'Attempts allowed'
                      : 'Hours to wait',
                  value: _retestValue,
                  min: 1,
                  max: _retest == RetestKind.maxAttempts ? 10 : 168,
                  step: _retest == RetestKind.maxAttempts ? 1 : 6,
                  keyPrefix: 'retest_value',
                  onChanged: (v) => setState(() => _retestValue = v),
                ),
            ],
          ),
          if (_message != null)
            Notice(
              _message!,
              key: const Key('start_message'),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFFE1E1),
            ),
          if (_offer != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('use_available'),
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () {
                  setState(() => _count = _offer!);
                  _start(exams, count: _offer);
                },
                child: Text('Use $_offer questions instead'),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'When you press Start, hand the device to ${child.name}.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('start_exam'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(GameTokens.minTouch)),
            onPressed: canStart ? () => _start(exams) : null,
            child: const Text('Start exam'),
          ),
        ],
      ),
    );
  }

  List<Widget> _scopePicker(ExamController exams, List<LearningWorld> worlds) {
    switch (_type) {
      case ExamType.chapter:
        final choices = _lessonChoices(exams);
        if (choices.isEmpty) {
          return const [Text('No lessons with questions at this level yet.')];
        }
        return [
          const Text('Choose the lessons to test'),
          for (final c in choices)
            CheckboxListTile(
              key: Key('lesson_${c.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _lessons.contains(c.id),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _lessons.add(c.id);
                } else {
                  _lessons.remove(c.id);
                }
              }),
              title:
                  Text(c.title, style: scriptStyle(c.title, const TextStyle())),
              subtitle: Text(
                  '${worldNameOf(context, c.world)}: ${c.count} questions'),
            ),
        ];
      case ExamType.subject:
        return [
          const Text('Choose one subject'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final w in worlds)
                ChoiceChip(
                  key: Key('world_${w.id}'),
                  label: Text(w.name),
                  selected: _world == w.id,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() => _world = w.id),
                ),
            ],
          ),
        ];
      case ExamType.finalLevel:
        final chosen = _chosenFinalWorlds(exams);
        final have = _worldsWithQuestions(exams);
        final missing = _emptyWorldNames(exams);
        return [
          const Text('Subjects included'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final w in worlds)
                FilterChip(
                  key: Key('final_world_${w.id}'),
                  label: Text(have.contains(w.id)
                      ? w.name
                      : '${w.name} (no questions yet)'),
                  selected: chosen.contains(w.id),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: !have.contains(w.id)
                      ? null
                      : (v) => setState(() {
                            final next = {...chosen};
                            if (v) {
                              next.add(w.id);
                            } else if (next.length > 1) {
                              next.remove(w.id);
                            }
                            _finalWorlds = next;
                          }),
                ),
            ],
          ),
          if (missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Switched off because they have no questions at Level $_level yet: $missing.',
                key: const Key('final_empty_note'),
              ),
            ),
        ];
    }
  }
}
