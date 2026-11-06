import 'package:flutter/material.dart';

import '../../exam/exam_controller.dart';

/// Gives the parent screens the [ExamController]. Sits next to `AppScope`.
class ExamScope extends InheritedNotifier<ExamController> {
  const ExamScope({
    required ExamController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ExamController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExamScope>();
    assert(scope != null, 'ExamScope is missing above this context');
    return scope!.notifier!;
  }

  /// Null when the app was built without exams (older tests).
  static ExamController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExamScope>()?.notifier;
}
