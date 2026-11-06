import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'exam/exam_controller.dart';
import 'screens/exam/exam_scope.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }
}

class AksharamalaApp extends StatefulWidget {
  const AksharamalaApp({super.key, this.controller, this.examController});

  final AppController? controller;

  /// Runs parent examinations (a separate store from learning progress).
  final ExamController? examController;

  @override
  State<AksharamalaApp> createState() => _AksharamalaAppState();
}

class _AksharamalaAppState extends State<AksharamalaApp> {
  late final AppController controller = widget.controller ?? AppController();
  late final ExamController examController =
      widget.examController ?? ExamController();

  @override
  void initState() {
    super.initState();
    controller.initialise();
    examController.load();
  }

  @override
  void dispose() {
    controller.dispose();
    examController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
        controller: controller,
        child: ExamScope(
          controller: examController,
          child: MaterialApp(
            title: 'Aksharamala',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: const SplashScreen(),
          ),
        ),
      );
}
